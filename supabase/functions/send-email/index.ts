import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';
import { getAccessToken } from '../_shared/auth.ts';

interface Attachment {
  filename: string;
  mimeType: string;
  data: string;
}

function buildEmailMime({
  to,
  subject,
  body,
  cc,
  bcc,
  from,
  displayName,
  attachments,
}: {
  to: string;
  subject: string;
  body: string;
  cc?: string;
  bcc?: string;
  from: string;
  displayName?: string;
  attachments?: Attachment[];
}): string {
  const domain = from.split('@')[1] || 'gmail.com';
  const messageId = `<${crypto.randomUUID()}@${domain}>`;
  const date = new Date().toUTCString();

  const fromFormatted = displayName
    ? `=?UTF-8?B?${btoa(unescape(encodeURIComponent(displayName)))}?= <${from}>`
    : from;

  const encodedSubject = `=?UTF-8?B?${btoa(unescape(encodeURIComponent(subject)))}?=`;

  const normalizedBody = body.replace(/\r\n/g, '\n').replace(/\n/g, '\r\n');

  let mime = '';
  mime += `From: ${fromFormatted}\r\n`;
  mime += `To: ${to}\r\n`;
  if (cc) mime += `Cc: ${cc}\r\n`;
  if (bcc) mime += `Bcc: ${bcc}\r\n`;
  mime += `Reply-To: ${from}\r\n`;
  mime += `Subject: ${encodedSubject}\r\n`;
  mime += `Date: ${date}\r\n`;
  mime += `Message-ID: ${messageId}\r\n`;
  mime += `MIME-Version: 1.0\r\n`;

  if (attachments && attachments.length > 0) {
    const boundary = `==Multipart_Boundary_${crypto.randomUUID().replace(/-/g, '')}`;
    mime += `Content-Type: multipart/mixed; boundary="${boundary}"\r\n`;
    mime += `\r\n`;

    mime += `--${boundary}\r\n`;
    mime += `Content-Type: text/plain; charset=UTF-8\r\n`;
    mime += `Content-Transfer-Encoding: 8bit\r\n`;
    mime += `\r\n`;
    mime += normalizedBody;
    mime += `\r\n`;

    for (const att of attachments) {
      mime += `--${boundary}\r\n`;
      mime += `Content-Type: ${att.mimeType}\r\n`;
      mime += `Content-Disposition: attachment; filename="${att.filename}"\r\n`;
      mime += `Content-Transfer-Encoding: base64\r\n`;
      mime += `\r\n`;
      const wrapped = att.data.match(/.{1,76}/g)?.join('\r\n') || att.data;
      mime += wrapped;
      mime += `\r\n`;
    }

    mime += `--${boundary}--`;
  } else {
    mime += `Content-Type: text/plain; charset=UTF-8\r\n`;
    mime += `Content-Transfer-Encoding: 8bit\r\n`;
    mime += `\r\n`;
    mime += normalizedBody;
  }

  return mime;
}

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

    const { to, subject, body, cc, bcc, attachments } = await req.json();

    if (!to || !subject || !body) {
      return new Response(
        JSON.stringify({ error: 'to, subject, and body are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const accessToken = await getAccessToken(supabase, user.id);

    const tokens = await supabase
      .from('user_email_tokens')
      .select('email, display_name')
      .eq('user_id', user.id)
      .single();

    const fromEmail = tokens.data.email;
    const displayName = tokens.data.display_name || fromEmail.split('@')[0];

    const rawMime = buildEmailMime({
      to,
      subject,
      body,
      cc,
      bcc,
      from: fromEmail,
      displayName,
      attachments: attachments || undefined,
    });

    const base64Url = btoa(rawMime)
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');

    const gmailResponse = await fetch(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ raw: base64Url }),
      }
    );

    const gmailData = await gmailResponse.json();

    if (!gmailResponse.ok) {
      console.error('Gmail API error:', gmailData);
      return new Response(
        JSON.stringify({
          error: gmailData.error?.message || 'Failed to send email',
          details: gmailData,
        }),
        {
          status: gmailResponse.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    return new Response(
      JSON.stringify({
        message_id: gmailData.id,
        thread_id: gmailData.threadId,
        label_ids: gmailData.labelIds,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Send email error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
