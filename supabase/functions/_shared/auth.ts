import { createClient } from '@supabase/supabase-js';

export async function getAccessToken(
  supabase: ReturnType<typeof createClient>,
  userId: string
): Promise<string> {
  const { data: tokens, error } = await supabase
    .from('user_email_tokens')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error || !tokens) {
    throw new Error('No tokens found for user');
  }

  const now = new Date();
  const expiry = new Date(tokens.token_expiry);

  if (now < expiry) {
    return tokens.access_token;
  }

  if (!tokens.refresh_token) {
    throw new Error('Token expired and no refresh token available');
  }

  const { data: configs } = await supabase
    .from('org_email_config')
    .select('*')
    .eq('is_active', true)
    .limit(1)
    .single();

  const refreshResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: configs.google_web_client_id,
      client_secret: configs.google_web_client_secret,
      refresh_token: tokens.refresh_token,
      grant_type: 'refresh_token',
    }),
  });

  const refreshData = await refreshResponse.json();

  if (refreshData.error) {
    throw new Error(
      `Failed to refresh token: ${refreshData.error_description || refreshData.error}`
    );
  }

  const newExpiry = new Date(
    Date.now() + (refreshData.expires_in || 3600) * 1000
  ).toISOString();

  await supabase
    .from('user_email_tokens')
    .update({
      access_token: refreshData.access_token,
      token_expiry: newExpiry,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId);

  return refreshData.access_token;
}
