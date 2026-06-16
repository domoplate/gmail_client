import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';
import { getAccessToken } from '../_shared/auth.ts';
import {
  decodeBase64Url,
  parseEmailHeaders,
  parseGmailDate,
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

    const { q, maxResults, pageToken } = await req.json();

    const accessToken = await getAccessToken(supabase, user.id);

    const params = new URLSearchParams();
    params.set('maxResults', String(maxResults || 20));
    if (q) params.set('q', q);
    if (pageToken) params.set('pageToken', pageToken);

    const listUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages?${params.toString()}`;

    const listResponse = await fetch(listUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    const listData = await listResponse.json();

    if (!listResponse.ok) {
      return new Response(
        JSON.stringify({
          error: listData.error?.message || 'Failed to list emails',
        }),
        {
          status: listResponse.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const messages = listData.messages || [];

    const emails = [];
    for (const msg of messages) {
      try {
        const detailResponse = await fetch(
          `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}?format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date&metadataHeaders=To`,
          { headers: { Authorization: `Bearer ${accessToken}` } }
        );

        if (!detailResponse.ok) continue;
        const detailData = await detailResponse.json();

        const headers = parseEmailHeaders(detailData.payload?.headers || []);

        emails.push({
          id: msg.id,
          threadId: msg.threadId,
          from: headers['from'] || 'Unknown',
          to: headers['to'] ? [headers['to']] : [],
          subject: headers['subject'] || '(sin asunto)',
          snippet: detailData.snippet || '',
          labels: detailData.labelIds || [],
          isRead: !(detailData.labelIds || []).includes('UNREAD'),
          date: parseGmailDate(headers['date']),
        });
      } catch {
        emails.push({
          id: msg.id,
          threadId: msg.threadId,
          from: 'Unknown',
          subject: '(sin asunto)',
          snippet: '',
          labels: [],
          isRead: true,
          date: null,
        });
      }
    }

    return new Response(
      JSON.stringify({
        messages: emails,
        nextPageToken: listData.nextPageToken || null,
        resultSizeEstimate: listData.resultSizeEstimate || 0,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('List emails error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
