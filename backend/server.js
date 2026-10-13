'use strict';

require('dotenv').config();

const express = require('express');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const FRONTEND_DIR = path.resolve(__dirname, '..', 'frontend');

app.disable('x-powered-by');
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));
app.use(express.static(FRONTEND_DIR));

/* ============================================================================
   AURA AI — QUOTA-AWARE MULTI-MODEL FALLBACK

   Primary route: Google AI models (Gemini first, then Google Gemma text models)
   Secondary:     Groq model pool
   Tertiary:      Cerebras model pool

   Existing frontend contract is preserved:
     POST /api/aura-ai -> { success: true, provider, result }

   Cooldowns are held in memory for this server process. A model that reports a
   daily quota failure is skipped until the next midnight in America/Los_Angeles
   (the Gemini API's documented RPD reset boundary). Rate-limit responses with
   a retry delay use that delay; short-term limits default to a 60-second skip.
   Unsupported models are skipped for 24 hours rather than retried on every call.
   ============================================================================ */

const MODEL_COOLDOWNS = new Map();
const PROVIDER_COOLDOWNS = new Map();

const SHORT_COOLDOWN_MS = 60 * 1000;
const SERVER_ERROR_COOLDOWN_MS = 30 * 1000;
const UNSUPPORTED_MODEL_COOLDOWN_MS = 24 * 60 * 60 * 1000;
const AUTH_FAILURE_COOLDOWN_MS = 10 * 60 * 1000;

function parseListFromEnv(name, fallback) {
  const value = process.env[name];
  if (!value || !value.trim()) return fallback;
  return [...new Set(value.split(',').map((item) => item.trim()).filter(Boolean))];
}

/*
 * Order matters: use the newer general-purpose Flash model first, then a model
 * with the larger daily quota shown in the supplied AI Studio limits, then the
 * Google text-capable Gemma models with larger displayed RPD, and keep models
 * currently quota-exhausted/older on the tail end.
 *
 * Override any pool in backend/.env with comma-separated model IDs if your
 * model access or rate limits change. Model IDs are verified/attempted at runtime;
 * unsupported IDs are cooled down instead of breaking the whole route.
 */
const GOOGLE_MODELS = parseListFromEnv('AURA_GOOGLE_MODELS', [
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
  'gemma-4-31b-it',
  'gemma-4-26b-a4b-it',
  'gemini-3-flash-preview',
  'gemini-2.5-flash-lite',
  'gemini-3.6-flash'
]);

const GROQ_MODELS = parseListFromEnv('AURA_GROQ_MODELS', [
  'openai/gpt-oss-120b',
  'openai/gpt-oss-20b'
]);

const CEREBRAS_MODELS = parseListFromEnv('AURA_CEREBRAS_MODELS', [
  'gpt-oss-120b',
  'qwen-3.8-27b',
  'gemma-4-31b',
  'zai-glm-4.7',
  'llama3.1-8b'
]);

function ensureText(value, label) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} returned an empty response`);
  }
  return value.trim();
}

function errorStatus(error) {
  const candidate = error?.status ?? error?.statusCode ?? error?.response?.status ?? error?.code;
  const numeric = Number(candidate);
  if (Number.isInteger(numeric) && numeric >= 100 && numeric <= 599) return numeric;

  const message = String(error?.message || error || '');
  const match = message.match(/\b(400|401|403|404|408|409|422|429|500|502|503|504)\b/);
  return match ? Number(match[1]) : null;
}

function errorText(error) {
  const bits = [error?.message, error?.body, error?.responseBody]
    .filter((value) => typeof value === 'string' && value.trim());
  return (bits.join(' ') || String(error || 'Unknown error')).slice(0, 1200);
}

function readHeader(headers, name) {
  if (!headers) return null;
  if (typeof headers.get === 'function') return headers.get(name);
  const key = Object.keys(headers).find((item) => item.toLowerCase() === name.toLowerCase());
  return key ? headers[key] : null;
}

function retryAfterMs(error) {
  if (Number.isFinite(error?.retryAfterMs) && error.retryAfterMs >= 0) {
    return error.retryAfterMs;
  }

  const headers = error?.headers || error?.response?.headers;
  const retryAfter = readHeader(headers, 'retry-after');
  if (retryAfter !== null && retryAfter !== undefined) {
    const seconds = Number(retryAfter);
    if (Number.isFinite(seconds)) return Math.max(1000, seconds * 1000);
    const dateMs = Date.parse(retryAfter);
    if (Number.isFinite(dateMs)) return Math.max(1000, dateMs - Date.now());
  }

  const text = errorText(error);
  const secondsMatch = text.match(/retry(?:\s+in|\s+after)?\s*[=:]?\s*(\d+(?:\.\d+)?)\s*s(?:ec(?:ond)?s?)?/i);
  if (secondsMatch) return Math.max(1000, Number(secondsMatch[1]) * 1000);

  // Some provider errors encode durations such as "retryDelay": "32s".
  const jsonDurationMatch = text.match(/retryDelay[^\S\r\n]*["']?\s*:\s*["'](\d+(?:\.\d+)?)s["']/i);
  if (jsonDurationMatch) return Math.max(1000, Number(jsonDurationMatch[1]) * 1000);

  return null;
}

function pacificParts(date) {
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/Los_Angeles',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23'
  });
  const parts = Object.fromEntries(formatter.formatToParts(date)
    .filter((part) => part.type !== 'literal')
    .map((part) => [part.type, Number(part.value)]));
  return parts;
}

function nextPacificMidnightMs(now = Date.now()) {
  const current = pacificParts(new Date(now));
  const nextCalendarDate = new Date(Date.UTC(current.year, current.month - 1, current.day + 1));
  const y = nextCalendarDate.getUTCFullYear();
  const m = nextCalendarDate.getUTCMonth();
  const d = nextCalendarDate.getUTCDate();

  // Find UTC instant for 00:00 Pacific on the next local calendar day. Iterate
  // so daylight-saving transitions are handled rather than assuming UTC-7/-8.
  let guess = Date.UTC(y, m, d, 8, 0, 0);
  for (let i = 0; i < 4; i += 1) {
    const local = pacificParts(new Date(guess));
    const localAsUtc = Date.UTC(local.year, local.month - 1, local.day,
      local.hour, local.minute, local.second);
    const offsetMs = localAsUtc - guess;
    guess = Date.UTC(y, m, d, 0, 0, 0) - offsetMs;
  }
  return Math.max(now + 1000, guess);
}

function isDailyQuotaFailure(providerName, status, text) {
  if (status !== 429 && !/RESOURCE_EXHAUSTED|quota_exceeded/i.test(text)) return false;

  // Respect explicit short-window clues first. A generic Google "project has
  // exceeded a quota" 429 is treated as daily exhaustion, matching the report
  // supplied for Gemini 3.6 Flash where RPD is already above its daily limit.
  if (/per\s*minute|requests?\s*per\s*minute|tokens?\s*per\s*minute|\bRPM\b|\bTPM\b|too many requests in a short|retry\s+in/i.test(text)) {
    return false;
  }
  if (/per\s*day|requests?\s*per\s*day|daily quota|\bRPD\b|quota has been exceeded|project has exceeded a quota|exceeded your current quota/i.test(text)) {
    return true;
  }
  return providerName === 'gemini' && /quota|RESOURCE_EXHAUSTED/i.test(text);
}

function getModelCooldownMs(providerName, error) {
  const status = errorStatus(error);
  const text = errorText(error);
  const delay = retryAfterMs(error);

  if (status === 401 || status === 403) return AUTH_FAILURE_COOLDOWN_MS;
  if (status === 404 || /model[^.\n]{0,100}(not found|not supported|unavailable)|unsupported model/i.test(text)) {
    return UNSUPPORTED_MODEL_COOLDOWN_MS;
  }
  if (status === 429 || /RESOURCE_EXHAUSTED|quota_exceeded|too_many_requests/i.test(text)) {
    if (delay !== null) return delay;
    if (isDailyQuotaFailure(providerName, status, text)) {
      if (providerName === 'gemini') return Math.max(1000, nextPacificMidnightMs() - Date.now());
      // Third-party provider quota reset boundaries differ; don't guess midnight.
      return 15 * 60 * 1000;
    }
    return SHORT_COOLDOWN_MS;
  }
  if (status !== null && status >= 500) return SERVER_ERROR_COOLDOWN_MS;
  return SHORT_COOLDOWN_MS;
}

function cooldownKey(providerName, model) {
  return `${providerName}:${model}`;
}

function formatTime(timestamp) {
  return new Date(timestamp).toISOString();
}

async function callGoogleModel(prompt, model) {
  if (!process.env.GEMINI_API_KEY) throw new Error('GEMINI_API_KEY is not configured');
  const { GoogleGenAI } = require('@google/genai');
  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

  const interaction = await ai.interactions.create({ model, input: prompt });
  return ensureText(interaction?.output_text, `Google model ${model}`);
}

async function callChatCompletionsModel({ provider, endpoint, model, apiKey, prompt }) {
  if (!apiKey) throw new Error(`${provider.toUpperCase()}_API_KEY is not configured`);

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7
    }),
    signal: AbortSignal.timeout(45000)
  });

  if (!response.ok) {
    const details = (await response.text().catch(() => '')).slice(0, 700);
    const error = new Error(`${provider} ${response.status}${details ? `: ${details}` : ''}`);
    error.status = response.status;
    error.body = details;
    error.headers = response.headers;
    throw error;
  }

  const data = await response.json();
  return ensureText(data?.choices?.[0]?.message?.content, `${provider} model ${model}`);
}

async function attemptModelPool({ providerName, models, invoke }) {
  const providerUntil = PROVIDER_COOLDOWNS.get(providerName) || 0;
  if (providerUntil > Date.now()) {
    throw new Error(`${providerName} provider temporarily skipped until ${formatTime(providerUntil)}`);
  }

  let lastError = null;
  for (const model of models) {
    const key = cooldownKey(providerName, model);
    const unavailableUntil = MODEL_COOLDOWNS.get(key) || 0;
    if (unavailableUntil > Date.now()) {
      console.log(`AURA AI: skipping ${providerName}/${model}; cooldown until ${formatTime(unavailableUntil)}`);
      continue;
    }

    try {
      const result = await invoke(model);
      MODEL_COOLDOWNS.delete(key);
      console.log(`AURA AI: model succeeded: ${providerName}/${model}`);
      return { result, model, provider: providerName };
    } catch (error) {
      lastError = error;
      const status = errorStatus(error);
      const text = errorText(error);
      const cooldown = getModelCooldownMs(providerName, error);
      const until = Date.now() + cooldown;
      MODEL_COOLDOWNS.set(key, until);

      console.warn(`AURA AI: ${providerName}/${model} failed${status ? ` (${status})` : ''}: ${text}`);
      console.warn(`AURA AI: ${providerName}/${model} will be skipped until ${formatTime(until)}`);

      // Authentication/permission errors normally affect the whole provider key,
      // so don't waste calls against every remaining model for the same key.
      if (status === 401 || status === 403) {
        PROVIDER_COOLDOWNS.set(providerName, Date.now() + AUTH_FAILURE_COOLDOWN_MS);
        break;
      }
    }
  }

  throw lastError || new Error(`No available models in the ${providerName} pool`);
}

async function callGooglePool(prompt) {
  if (!process.env.GEMINI_API_KEY) throw new Error('GEMINI_API_KEY is not configured');
  return attemptModelPool({
    providerName: 'gemini',
    models: GOOGLE_MODELS,
    invoke: (model) => callGoogleModel(prompt, model)
  });
}

async function callGroqPool(prompt) {
  if (!process.env.GROQ_API_KEY) throw new Error('GROQ_API_KEY is not configured');
  return attemptModelPool({
    providerName: 'groq',
    models: GROQ_MODELS,
    invoke: (model) => callChatCompletionsModel({
      provider: 'Groq',
      endpoint: 'https://api.groq.com/openai/v1/chat/completions',
      model,
      apiKey: process.env.GROQ_API_KEY,
      prompt
    })
  });
}

async function callCerebrasPool(prompt) {
  if (!process.env.CEREBRAS_API_KEY) throw new Error('CEREBRAS_API_KEY is not configured');
  return attemptModelPool({
    providerName: 'cerebras',
    models: CEREBRAS_MODELS,
    invoke: (model) => callChatCompletionsModel({
      provider: 'Cerebras',
      endpoint: 'https://api.cerebras.ai/v1/chat/completions',
      model,
      apiKey: process.env.CEREBRAS_API_KEY,
      prompt
    })
  });
}

app.post('/api/aura-ai', async (req, res) => {
  try {
    const { task, context } = req.body || {};
    if (task === undefined || task === null ||
        (typeof task === 'string' && !task.trim())) {
      return res.status(400).json({ error: 'AURA AI: Missing task.' });
    }
    if (typeof task !== 'string' && typeof task !== 'object') {
      return res.status(400).json({ error: 'AURA AI: Task must be text or a JSON object.' });
    }

    const taskText = typeof task === 'string' ? task.trim() : JSON.stringify(task, null, 2);
    const prompt = `
You are AURA, an intelligent personal wellness assistant.

Task:
${taskText}

User Context:
${JSON.stringify(context || {}, null, 2)}

Return the most useful response for this task.
Do not invent user information.
Keep recommendations practical and safe.
`;

    const providerPools = [
      ['gemini', () => callGooglePool(prompt)],
      ['groq', () => callGroqPool(prompt)],
      ['cerebras', () => callCerebrasPool(prompt)]
    ];

    const failures = [];
    for (const [providerName, runPool] of providerPools) {
      try {
        const response = await runPool();
        console.log(`AURA AI: Response generated using ${providerName}/${response.model}`);
        // Preserve the response shape expected by the current frontend.
        return res.json({ success: true, provider: providerName, result: response.result });
      } catch (error) {
        failures.push(`${providerName}: ${errorText(error).slice(0, 240)}`);
        console.warn(`AURA AI: ${providerName} model pool unavailable; moving to next provider: ${error.message}`);
      }
    }

    console.error('AURA AI: all model pools failed:', failures.join(' | '));
    return res.status(503).json({ error: 'AURA AI: All providers unavailable. Please try again shortly.' });
  } catch (error) {
    console.error('AURA AI ERROR:', errorText(error));
    return res.status(500).json({ error: 'AURA AI request failed.' });
  }
});

/* ============================================================================
   HEALTH CHECK — response kept compatible with the existing frontend
   ============================================================================ */
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Aura API is running' });
});

app.listen(PORT, () => {
  console.log(`Aura server running on http://localhost:${PORT}`);
  console.log(`AURA AI: Google model pool (${GOOGLE_MODELS.length} models) → Groq (${GROQ_MODELS.length}) → Cerebras (${CEREBRAS_MODELS.length})`);
});
