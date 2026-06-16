## Gmail App MVP - Guía de Configuración

### Estado del Proyecto

| Componente | Estado |
|-----------|--------|
| Flutter App (6 pantallas) | ✅ Creado |
| DB Schema (4 tablas + RLS) | ✅ Desplegado |
| Edge Function: google-auth-callback | ✅ ACTIVE |
| Edge Function: send-email | ✅ ACTIVE |
| Edge Function: list-emails | ✅ ACTIVE |
| Edge Function: get-email | ✅ ACTIVE |
| Riverpod code gen | ✅ Generado |
| Android/iOS config | ✅ Configurado |

### Pasos para poner en marcha

#### 1. Google Cloud Console (Obligatorio)

1. Ve a https://console.cloud.google.com
2. Crea un proyecto o usa uno existente
3. Habilita **Gmail API** (APIs & Services → Library → buscar "Gmail API" → Enable)
4. Ve a **Google Auth Platform** (https://console.cloud.google.com/auth/overview)
5. En **Branding**: configura nombre de la app, email de soporte, logo
6. En **Audience**: selecciona "External" (para producción) 
7. En **Data Access (Scopes)**: agrega:
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/gmail.modify`
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `openid`
8. En **Clients** → Create OAuth Client ID:
   - **Web application**: agrega como Authorized redirect URI:
     `https://nsmdeucodjlweuhbvcjl.supabase.co/auth/v1/callback`
   - **iOS** (opcional): con Bundle ID `com.gmailapp.enviarGmail`
   - **Android** (opcional): con SHA-1 de tu keystore
9. Guarda el **Client ID** y **Client Secret** del Web Client
10. En **Audience** → Test Users: agrega tu email para desarrollo

#### 2. Supabase Dashboard

1. Ve a https://supabase.com/dashboard/project/nsmdeucodjlweuhbvcjl
2. **Settings → API**: copia el `anon` (publishable) key
3. Pega la key en el archivo `.env`:
   ```
   SUPABASE_URL=https://nsmdeucodjlweuhbvcjl.supabase.co
   SUPABASE_ANON_KEY=TU_ANON_KEY_AQUI
   GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID.apps.googleusercontent.com
   ```
4. **Authentication → Providers → Google**:
   - Enable Google provider
   - Client ID: pega el Web Client ID de Google Cloud
   - Client Secret: pega el Client Secret de Google Cloud
   - Skip nonce check: habilitado (para desarrollo)

#### 3. Configurar credenciales OAuth en la app

Opción A - Desde el panel admin de la app:
1. Inicia sesión en la app Flutter
2. Ve al perfil → icono de admin (engranaje)
3. Completa Web Client ID y Web Client Secret
4. Guarda

Opción B - Directo en Supabase SQL Editor:
```sql
UPDATE public.org_email_config
SET google_web_client_id = 'TU_CLIENT_ID.apps.googleusercontent.com',
    google_web_client_secret = 'GOCSPX-TU_SECRET',
    is_active = true
WHERE org_name = 'default';
```

#### 4. Probar el flujo

1. Ejecuta la app: `flutter run`
2. Login con Google (usa una cuenta de test)
3. Ve al perfil → Conectar cuenta de Gmail
4. Autoriza los scopes
5. Ve a la bandeja de entrada para ver correos
6. Redacta un correo para probar el envío

### Estructura del Proyecto

```
enviar_gmail/
├── lib/
│   ├── main.dart              # Entry point, Supabase init
│   ├── models/
│   │   └── email_message.dart # Modelos EmailMessage, EmailConfig
│   ├── services/
│   │   ├── email_service.dart # Llamadas a Edge Functions
│   │   └── google_auth_service.dart # Google Sign-In wrapper
│   ├── providers/
│   │   └── auth_provider.dart # Riverpod auth state
│   ├── screens/
│   │   ├── login_screen.dart      # Login con Google OAuth
│   │   ├── profile_screen.dart    # Conectar cuenta Gmail
│   │   ├── inbox_screen.dart      # Bandeja de entrada
│   │   ├── email_detail_screen.dart # Ver correo completo
│   │   ├── compose_screen.dart    # Redactar/enviar
│   │   └── admin_config_screen.dart # Config OAuth admin
│   └── theme/
│       └── app_theme.dart
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   └── 20260615120000_init_schema.sql
│   ├── functions/
│   │   ├── google-auth-callback/  # Intercambia código → tokens
│   │   ├── send-email/            # Envía MIME via Gmail API
│   │   ├── list-emails/           # Lista correos con metadata
│   │   └── get-email/             # Obtiene correo completo
│   └── seed.sql
├── .env
└── pubspec.yaml
```

### Flujo de Datos

```
1. Flutter → google_sign_in → Google OAuth consent → serverAuthCode
2. Flutter → Edge Function (google-auth-callback) → intercambia code por access_token+refresh_token
3. Flutter → Edge Function (send-email) → Gmail API POST /messages/send
4. Flutter → Edge Function (list-emails) → Gmail API GET /messages?q=...
5. Flutter → Edge Function (get-email) → Gmail API GET /messages/{id}?format=full
```

### URLs de Edge Functions

- google-auth-callback: https://nsmdeucodjlweuhbvcjl.supabase.co/functions/v1/google-auth-callback
- send-email: https://nsmdeucodjlweuhbvcjl.supabase.co/functions/v1/send-email
- list-emails: https://nsmdeucodjlweuhbvcjl.supabase.co/functions/v1/list-emails
- get-email: https://nsmdeucodjlweuhbvcjl.supabase.co/functions/v1/get-email
