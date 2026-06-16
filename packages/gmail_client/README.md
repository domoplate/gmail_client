# gmail_client

Core Gmail/Google Workspace client for Dart. Send and receive emails via Supabase Edge Functions — framework-agnostic, no Flutter dependency.

## Features

- Send emails with attachments (multipart MIME via Edge Functions)
- List inbox emails with pagination
- Fetch full email details with parsed body (text + HTML)
- Connect/disconnect Gmail accounts via Google OAuth
- Token management (auto-refresh via Supabase Edge Functions)
- Synced email storage and retrieval from Supabase

## Getting started

```bash
dart pub add gmail_client
```

```dart
import 'package:gmail_client/gmail_client.dart';
import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://your-project.supabase.co',
    'your-anon-key',
  );

  final emailService = EmailService(client);

  // List emails
  final result = await emailService.listEmails(maxResults: 20);
  for (final email in result.messages) {
    print('${email.from}: ${email.subject}');
  }

  // Send an email
  final sent = await emailService.sendEmail(
    to: 'recipient@example.com',
    subject: 'Hello',
    body: 'This is a test email.',
  );
  print('Sent: ${sent.id}');

  // Connect a Gmail account
  await emailService.connectGoogleAccount(
    'server-auth-code',
    'user@example.com',
    userId: 'user-uuid',
    redirectUri: 'http://localhost:3000/callback',
  );
}
```

## Prerequisites

This package requires a Supabase project with the corresponding Edge Functions and database schema deployed. See the [enviar_gmail](https://github.com/your-org/enviar_gmail) repository for the complete setup, including:

- Edge Functions: `google-auth-callback`, `send-email`, `list-emails`, `get-email`
- Database tables: `org_email_config`, `user_email_tokens`, `synced_emails`
- Google Cloud OAuth credentials configured in `org_email_config`

## API

### EmailService

| Method | Description |
|---|---|
| `listEmails({query, maxResults, pageToken})` | List inbox emails. Returns `ListEmailsResult`. |
| `getEmail(messageId)` | Get full email by Gmail message ID. Returns `EmailMessage`. |
| `sendEmail({to, subject, body, cc, bcc, attachments})` | Send an email. Returns `SendEmailResult`. |
| `connectGoogleAccount(code, email, {redirectUri, userId})` | Exchange OAuth code for Gmail tokens. |
| `disconnectAccount()` | Remove stored Gmail tokens. |
| `isEmailConnected()` | Check if current user has Gmail tokens. |
| `getConnectedEmail()` | Get the connected email address. |
| `getDisplayName()` / `updateDisplayName(name)` | Get/set sender display name. |
| `getSyncedEmails({limit, offset})` | Get synced emails from local Supabase storage. |
| `getOrgEmailConfig()` / `saveOrgEmailConfig(...)` | Manage OAuth configuration. |
