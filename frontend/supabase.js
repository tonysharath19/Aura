window.supabaseClient = window.supabase.createClient(
    window.AURA_CONFIG.SUPABASE_URL,
    window.AURA_CONFIG.SUPABASE_ANON_KEY
);