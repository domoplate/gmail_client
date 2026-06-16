-- ============================================================
-- Gmail MVP: Schema inicial para Supabase
-- Proyecto: nsmdeucodjlweuhbvcjl
-- ============================================================

-- 1. Configuración OAuth por organización (multi-tenant)
CREATE TABLE IF NOT EXISTS public.org_email_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_name TEXT NOT NULL DEFAULT 'default',
    google_web_client_id TEXT NOT NULL,
    google_web_client_secret TEXT NOT NULL,
    google_ios_client_id TEXT,
    google_android_client_id TEXT,
    google_project_id TEXT,
    gmail_scopes TEXT[] NOT NULL DEFAULT ARRAY[
        'https://www.googleapis.com/auth/gmail.send',
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/gmail.readonly'
    ],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insertar config por defecto para desarrollo
INSERT INTO public.org_email_config (org_name, google_web_client_id, google_web_client_secret)
VALUES ('default', 'PLACEHOLDER_CLIENT_ID', 'PLACEHOLDER_CLIENT_SECRET');

-- 2. Tokens OAuth por usuario
CREATE TABLE IF NOT EXISTS public.user_email_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    token_expiry TIMESTAMPTZ NOT NULL,
    scopes TEXT[] NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_email_tokens_user_id ON public.user_email_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_email_tokens_email ON public.user_email_tokens(email);

-- 3. Tracking de sincronización incremental
CREATE TABLE IF NOT EXISTS public.email_sync_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    last_history_id TEXT,
    last_sync_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

-- 4. Correos sincronizados localmente (cache para acceso rápido)
CREATE TABLE IF NOT EXISTS public.synced_emails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    gmail_message_id TEXT NOT NULL,
    thread_id TEXT NOT NULL,
    from_address TEXT,
    to_addresses TEXT[],
    subject TEXT,
    snippet TEXT,
    body_text TEXT,
    body_html TEXT,
    labels TEXT[],
    is_read BOOLEAN DEFAULT false,
    received_at TIMESTAMPTZ,
    synced_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, gmail_message_id)
);

CREATE INDEX IF NOT EXISTS idx_synced_emails_user_id ON public.synced_emails(user_id);
CREATE INDEX IF NOT EXISTS idx_synced_emails_received ON public.synced_emails(user_id, received_at DESC);

-- 5. Políticas RLS
ALTER TABLE public.org_email_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_email_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_sync_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.synced_emails ENABLE ROW LEVEL SECURITY;

-- Config legible por autenticados
DROP POLICY IF EXISTS "Authenticated can read org config" ON public.org_email_config;
CREATE POLICY "Authenticated can read org config" ON public.org_email_config
    FOR SELECT USING (auth.role() = 'authenticated');

-- Tokens: solo el dueño
DROP POLICY IF EXISTS "Users can manage own tokens" ON public.user_email_tokens;
CREATE POLICY "Users can manage own tokens" ON public.user_email_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Sync history: solo el dueño
DROP POLICY IF EXISTS "Users can manage own sync" ON public.email_sync_history;
CREATE POLICY "Users can manage own sync" ON public.email_sync_history
    FOR ALL USING (auth.uid() = user_id);

-- Correos sincronizados: solo el dueño
DROP POLICY IF EXISTS "Users can access own emails" ON public.synced_emails;
CREATE POLICY "Users can access own emails" ON public.synced_emails
    FOR ALL USING (auth.uid() = user_id);

-- 6. Función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar el trigger donde aplique
DROP TRIGGER IF EXISTS set_org_config_updated_at ON public.org_email_config;
CREATE TRIGGER set_org_config_updated_at
    BEFORE UPDATE ON public.org_email_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_user_tokens_updated_at ON public.user_email_tokens;
CREATE TRIGGER set_user_tokens_updated_at
    BEFORE UPDATE ON public.user_email_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
