# enviar_gmail

Cliente Gmail/Google Workspace para enviar y recibir emails mediante Supabase Edge Functions.

## Estructura del monorepo

```
enviar_gmail/
├── packages/
│   ├── gmail_client/              # Paquete Dart puro (framework-agnóstico)
│   │   └── lib/
│   │       ├── src/models/        # Modelos de datos (EmailMessage, EmailConfig)
│   │       ├── src/services/      # EmailService (opera sobre Supabase Edge Functions)
│   │       ├── src/config/        # GmailClientConfig
│   │       └── src/exceptions/    # Excepciones tipadas
│   │
│   └── gmail_client_flutter/      # Paquete Flutter con providers y utils de OAuth
│       └── lib/
│           ├── src/services/      # GoogleAuthService (Google Sign-In, OAuth)
│           ├── src/providers/     # Riverpod providers (auth, inbox, compose, email detail)
│           └── src/utils/         # OAuth popup web, URL utils
│
├── lib/                           # App de ejemplo / UI
│   ├── main.dart
│   └── screens/                   # Pantallas que consumen los paquetes
│
└── supabase/
    ├── functions/
    │   ├── _shared/               # Utilidades compartidas entre Edge Functions
    │   ├── google-auth-callback/  # Intercambia auth code por tokens
    │   ├── send-email/            # Construye MIME y envía por Gmail API
    │   ├── list-emails/           # Lista emails con metadata
    │   └── get-email/             # Obtiene email completo (parsea MIME)
    └── migrations/                # Schema de base de datos + RLS
```

## Cómo usar `gmail_client` (Dart puro)

```dart
import 'package:gmail_client/gmail_client.dart';
import 'package:supabase/supabase.dart';

void main() async {
  final config = GmailClientConfig(
    supabaseUrl: 'https://xxx.supabase.co',
    supabaseAnonKey: 'eyJhbGci...',
  );

  final supabase = SupabaseClient(config.supabaseUrl, config.supabaseAnonKey);
  final emailService = EmailService(supabase);

  // Listar emails
  final result = await emailService.listEmails(maxResults: 20);
  final emails = result['messages'] as List<EmailMessage>;

  // Enviar email
  await emailService.sendEmail(
    to: 'destino@ejemplo.com',
    subject: 'Asunto',
    body: 'Cuerpo del mensaje',
  );

  // Obtener email completo
  final email = await emailService.getEmail('message-id');
}
```

## Cómo usar `gmail_client_flutter` (Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xxx.supabase.co',
    anonKey: 'eyJhbGci...',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class InboxPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxProvider);

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

### Providers disponibles

| Provider | Tipo | Descripción |
|---|---|---|
| `emailServiceProvider` | Provider | Instancia de EmailService |
| `supabaseClientProvider` | Provider | SupabaseClient singleton |
| `emailConnectionProvider` | FutureProvider | ¿Cuenta Gmail conectada? |
| `connectedEmailProvider` | FutureProvider | Email de la cuenta conectada |
| `displayNameProvider` | FutureProvider | Nombre del remitente |
| `authStateProvider` | StreamProvider | Estado de autenticación Supabase |
| `currentUserProvider` | Provider | Usuario actual |
| `isLoggedInProvider` | Provider | ¿Sesión activa? |
| `inboxProvider` | StateNotifierProvider | Estado de la bandeja (emails, paginación, loading) |
| `composeProvider` | StateNotifierProvider | Estado de redacción (adjuntos, envío) |
| `emailDetailProvider` | FutureProvider.family | Email por messageId |
| `googleAuthServiceProvider` | Provider | Servicio de autenticación Google |

## Setup de Supabase

### 1. Variables de entorno en Supabase

```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
```

### 2. Deploy de migraciones

```bash
supabase db push
```

### 3. Deploy de Edge Functions

```bash
supabase functions deploy google-auth-callback
supabase functions deploy send-email
supabase functions deploy list-emails
supabase functions deploy get-email
```

### 4. Configurar OAuth en Google Cloud Console

1. Crear proyecto en [Google Cloud Console](https://console.cloud.google.com)
2. Habilitar Gmail API
3. Configurar pantalla de consentimiento OAuth
4. Crear OAuth Client ID tipo "Web application"
5. Agregar redirect URIs
6. Guardar Client ID y Client Secret en la tabla `org_email_config`

## Para desarrolladores que quieran crear su propia UI

1. Agrega el paquete a tu `pubspec.yaml`:
   ```yaml
   dependencies:
     gmail_client:
       path: packages/gmail_client
     gmail_client_flutter:
       path: packages/gmail_client_flutter
   ```

2. Inicializa Supabase y los providers en tu `main.dart`

3. Usa los providers de `gmail_client_flutter` para obtener los datos

4. Construye tu UI con cualquier framework Flutter (Material, Cupertino, etc.)

La lógica de negocio (auth, envío, recepción, tokens) está encapsulada en los paquetes. Solo necesitas construir la capa visual con los providers expuestos.
