/// Configuration for the Gmail client.
///
/// Provides Supabase connection details and optional OAuth parameters
/// that are passed to the EmailService.
class GmailClientConfig {
  /// Your Supabase project URL (e.g. `https://xxx.supabase.co`).
  final String? supabaseUrl;

  /// Your Supabase anonymous/publishable key.
  final String? supabaseAnonKey;

  /// The redirect URI used during the OAuth token exchange.
  ///
  /// Defaults to `http://localhost:3000/gmail-callback.html` for web
  /// and `postmessage` for native platforms.
  final String? gmailRedirectUri;

  /// The Gmail API scopes requested during OAuth.
  ///
  /// Defaults to `gmail.send`, `gmail.modify`, and `gmail.readonly`.
  final List<String>? gmailScopes;

  const GmailClientConfig({
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.gmailRedirectUri,
    this.gmailScopes,
  });

  /// Default Gmail API scopes for full email access.
  static const defaultGmailScopes = [
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/gmail.readonly',
  ];
}
