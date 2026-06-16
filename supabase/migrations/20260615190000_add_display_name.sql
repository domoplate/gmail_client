-- Add display_name column to user_email_tokens
ALTER TABLE public.user_email_tokens
  ADD COLUMN IF NOT EXISTS display_name TEXT;
