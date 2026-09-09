require('dotenv').config();

const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(express.static(path.join(__dirname, '..', 'frontend')));


/* ============================================================
   AURA AI — 18B PROVIDER ENGINE
   Gemini → Groq → Cerebras
   ============================================================ */

async function callGemini(prompt) {

  const { GoogleGenAI } =
    require("@google/genai");

  const ai = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY
  });

  const interaction =
    await ai.interactions.create({
      model: "gemini-3.6-flash",
      input: prompt
    });

  return interaction.output_text;
}

async function callGroq(prompt) {

  const response = await fetch(
    'https://api.groq.com/openai/v1/chat/completions',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
          `Bearer ${process.env.GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7
      })
    }
  );

  if (!response.ok) {
    throw new Error(`Groq ${response.status}`);
  }

  const data = await response.json();

  return data?.choices?.[0]?.message?.content;
}




app.post('/api/aura-ai', async (req, res) => {

  try {

    const { task, context } = req.body;

    if (!task) {
      return res.status(400).json({
        error: 'AURA AI: Missing task.'
      });
    }

    const prompt = `
You are AURA, an intelligent personal wellness assistant.

Task:
${task}

User Context:
${JSON.stringify(context || {}, null, 2)}

Return the most useful response for this task.
Do not invent user information.
Keep recommendations practical and safe.
`;

    let result;
    let provider;

    try {

      result = await callGemini(prompt);

      if (result) {
        provider = 'gemini';
      }

    } catch (error) {

      console.warn(
        'AURA AI: Gemini failed:',
        error.message
      );

    }


    if (!result) {

      try {

        result = await callGroq(prompt);

        if (result) {
          provider = 'groq';
        }

      } catch (error) {

        console.warn(
          'AURA AI: Groq failed:',
          error.message
        );

      }

    }


    if (!result) {

      try {

        result = await callCerebras(prompt);

        if (result) {
          provider = 'cerebras';
        }

      } catch (error) {

        console.warn(
          'AURA AI: Cerebras failed:',
          error.message
        );

      }

    }


    if (!result) {

      return res.status(503).json({
        error: 'AURA AI: All providers unavailable.'
      });

    }


    console.log(
      `AURA AI: Response generated using ${provider}`
    );


    res.json({
      success: true,
      provider,
      result
    });

  } catch (error) {

    console.error(
      'AURA AI ERROR:',
      error
    );

    res.status(500).json({
      error: 'AURA AI request failed.'
    });

  }

});


/* ============================================================
   HEALTH CHECK
   ============================================================ */

app.get('/api/health', (req, res) => {

  res.json({
    status: 'ok',
    message: 'Aura API is running'
  });

});


app.listen(PORT, () => {

  console.log(
    `Aura server running on http://localhost:${PORT}`
  );

});