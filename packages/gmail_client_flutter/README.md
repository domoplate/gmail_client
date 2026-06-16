# gmail_client_flutter

Flutter bindings for [gmail_client](https://pub.dev/packages/gmail_client). Provides Riverpod providers, Google Sign-In integration, and platform-specific OAuth utilities.

## Features

- **Riverpod providers** for auth state, inbox, compose, and email detail
- **GoogleAuthService** — Google Sign-In and Gmail OAuth token exchange (web + mobile)
- **Platform-specific OAuth** — web popup flow via `gmail_oauth`
- **URL utils** — clean OAuth params from browser address bar
- **Attachment management** — file picking and MIME type mapping

## Getting started

```bash
flutter pub add gmail_client_flutter
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class InboxPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxProvider);

    if (inboxState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: inboxState.emails.length,
      itemBuilder: (context, index) {
        final email = inboxState.emails[index];
        return ListTile(
          title: Text(email.subject ?? ''),
          subtitle: Text(email.from ?? ''),
        );
      },
    );
  }
}
```

## Providers

| Provider | Type | Description |
|---|---|---|
| `emailServiceProvider` | `Provider<EmailService>` | Core email service instance |
| `supabaseClientProvider` | `Provider<SupabaseClient>` | Supabase client singleton |
| `emailConnectionProvider` | `FutureProvider<bool>` | Whether Gmail is connected |
| `connectedEmailProvider` | `FutureProvider<String?>` | Connected email address |
| `displayNameProvider` | `FutureProvider<String?>` | Sender display name |
| `authStateProvider` | `StreamProvider<AuthState>` | Supabase auth state stream |
| `currentUserProvider` | `Provider<User?>` | Current authenticated user |
| `isLoggedInProvider` | `Provider<bool>` | Whether session is active |
| `inboxProvider` | `StateNotifierProvider` | Inbox state (emails, loading, pagination) |
| `composeProvider` | `StateNotifierProvider` | Compose state (attachments, sending) |
| `emailDetailProvider` | `FutureProvider.family` | Email detail by message ID |
| `googleAuthServiceProvider` | `Provider<GoogleAuthService>` | Google Sign-In service |

## GoogleAuthService

```dart
final googleAuth = ref.read(googleAuthServiceProvider);

// Initialize with OAuth client IDs
await googleAuth.initialize(
  webClientId: 'xxx.apps.googleusercontent.com',
  iosClientId: 'xxx.apps.googleusercontent.com',
);

// Sign in (mobile)
final account = await googleAuth.signIn();

// Get OAuth code (mobile)
final code = await googleAuth.getServerAuthCode(account!);

// Get OAuth code via web popup
final code = await googleAuth.getGmailAuthCodeForWeb('web-client-id');

// Exchange code for Gmail tokens
await googleAuth.connectGmailAccount(
  serverAuthCode: code!,
  email: 'user@gmail.com',
  userId: supabaseUser.id,
);
```

## Prerequisites

Requires `gmail_client` and a Supabase project with Edge Functions deployed. See [gmail_client](https://pub.dev/packages/gmail_client) for backend setup instructions.
