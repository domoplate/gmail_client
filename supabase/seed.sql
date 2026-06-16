-- Seed data for local development
-- Insert default OAuth config for development
INSERT INTO public.org_email_config (org_name, google_web_client_id, google_web_client_secret, google_ios_client_id, google_android_client_id)
VALUES ('default', 'PLACEHOLDER_CLIENT_ID', 'PLACEHOLDER_CLIENT_SECRET', '', '')
ON CONFLICT DO NOTHING;
