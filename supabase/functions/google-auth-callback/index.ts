import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { code, email, user_id, redirect_uri } = await req.json();

    if (!code || !email || !user_id) {
      return new Response(
        JSON.stringify({ error: 'code, email, and user_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: configs, error: configError } = await supabase
      .from('org_email_config')
      .select('*')
      .eq('is_active', true)
      .limit(1);

    if (configError || !configs || configs.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No active OAuth configuration found' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const config = configs[0];
    const clientId = config.google_web_client_id;
    const clientSecret = config.google_web_client_secret;

    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirect_uri || 'postmessage',
        grant_type: 'authorization_code',
      }),
    });

    const tokenData = await tokenResponse.json();

    if (tokenData.error) {
      console.error('Token exchange error:', tokenData);
      return new Response(
        JSON.stringify({
          error: tokenData.error_description || tokenData.error,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { access_token, refresh_token, expires_in, scope } = tokenData;

    const tokenExpiry = new Date(
      Date.now() + (expires_in || 3600) * 1000
    ).toISOString();
    const scopes = scope ? scope.split(' ') : [];

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.admin.getUserById(user_id);

    if (userError || !user) {
      console.error('User lookup error:', userError);
      return new Response(JSON.stringify({ error: 'User not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { error: upsertError } = await supabase
      .from('user_email_tokens')
      .upsert(
        {
          user_id: user.id,
          email,
          access_token,
          refresh_token: refresh_token || null,
          token_expiry: tokenExpiry,
          scopes,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' }
      );

    if (upsertError) {
      console.error('Token storage error:', upsertError);
      return new Response(
        JSON.stringify({ error: 'Failed to store tokens' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify({ success: true, email }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
