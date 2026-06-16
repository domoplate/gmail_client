-- Fix: Add UNIQUE constraint on user_email_tokens.user_id
-- Required by google-auth-callback Edge Function which uses .onConflict('user_id')

ALTER TABLE public.user_email_tokens
  ADD CONSTRAINT user_email_tokens_user_id_unique UNIQUE (user_id);
