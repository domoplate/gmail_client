import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';
import { getAccessToken } from '../_shared/auth.ts';
import {
  parseEmailHeaders,
  parseGmailDate,
  getBody,
} from '../_shared/email.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const token = authHeader.replace('Bearer ', '');
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { id } = await req.json();

    if (!id) {
      return new Response(
        JSON.stringify({ error: 'id (messageId) is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const accessToken = await getAccessToken(supabase, user.id);

    const gmailResponse = await fetch(
      `https://gmail.googleapis.com/gmail/v1/users/me/messages/${id}?format=full`,
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );

    const gmailData = await gmailResponse.json();

    if (!gmailResponse.ok) {
      return new Response(
        JSON.stringify({
          error: gmailData.error?.message || 'Failed to get email',
        }),
        {
          status: gmailResponse.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const headers = parseEmailHeaders(gmailData.payload?.headers || []);
    const body = gmailData.payload
      ? getBody(gmailData.payload)
      : { text: '', html: '' };

    const email = {
      id: gmailData.id,
      threadId: gmailData.threadId,
      from: headers['from'] || 'Unknown',
      to: headers['to'] ? [headers['to']] : [],
      cc: headers['cc'] ? [headers['cc']] : [],
      bcc: headers['bcc'] ? [headers['bcc']] : [],
      subject: headers['subject'] || '(sin asunto)',
      snippet: gmailData.snippet || '',
      bodyText: body.text,
      bodyHtml: body.html,
      labels: gmailData.labelIds || [],
      isRead: !(gmailData.labelIds || []).includes('UNREAD'),
      date: parseGmailDate(headers['date']),
    };

    return new Response(JSON.stringify({ message: email }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Get email error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
