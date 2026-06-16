export function decodeBase64Url(data: string): string {
  if (!data) return '';
  const normalized = data.replace(/-/g, '+').replace(/_/g, '/');
  return atob(normalized);
}

export function parseEmailHeaders(
  headers: { name?: string; value?: string }[]
): Record<string, string> {
  const result: Record<string, string> = {};
  for (const header of headers) {
    const name = header.name?.toLowerCase();
    if (name && header.value) {
      result[name] = header.value;
    }
  }
  return result;
}

export function parseGmailDate(dateStr: string): string | null {
  if (!dateStr) return null;
  try {
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return null;
    return date.toISOString();
  } catch {
    return null;
  }
}

interface PayloadPart {
  partId?: string;
  mimeType?: string;
  filename?: string;
  headers?: { name?: string; value?: string }[];
  body?: { size?: number; data?: string };
  parts?: PayloadPart[];
}

export function getBodyFromParts(
  parts: PayloadPart[]
): { text: string; html: string } {
  let text = '';
  let html = '';

  for (const part of parts) {
    if (part.parts) {
      const nested = getBodyFromParts(part.parts);
      if (nested.text) text = nested.text;
      if (nested.html) html = nested.html;
      continue;
    }

    const mimeType = part.mimeType || '';
    const bodyData = part.body?.data;

    if (!bodyData) continue;

    const decoded = decodeBase64Url(bodyData);

    if (mimeType === 'text/plain') {
      text = text || decoded;
    } else if (mimeType === 'text/html') {
      html = html || decoded;
    }
  }

  return { text, html };
}

export function getBody(
  payload: { mimeType?: string; body?: { data?: string }; parts?: PayloadPart[] }
): { text: string; html: string } {
  if (payload.parts) {
    return getBodyFromParts(payload.parts);
  }

  const bodyData = payload.body?.data;
  if (!bodyData) return { text: '', html: '' };

  const decoded = decodeBase64Url(bodyData);
  const mimeType = payload.mimeType || '';

  if (mimeType === 'text/html') {
    return { text: '', html: decoded };
  }
  return { text: decoded, html: '' };
}
