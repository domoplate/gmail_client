-- Add INSERT and UPDATE policies for org_email_config
-- Needed by saveOrgEmailConfig() which uses upsert

DROP POLICY IF EXISTS "Authenticated can insert org config" ON public.org_email_config;
CREATE POLICY "Authenticated can insert org config" ON public.org_email_config
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated can update org config" ON public.org_email_config;
CREATE POLICY "Authenticated can update org config" ON public.org_email_config
    FOR UPDATE USING (auth.role() = 'authenticated');
