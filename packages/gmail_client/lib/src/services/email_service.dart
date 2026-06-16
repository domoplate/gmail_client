import 'package:supabase/supabase.dart';

import '../config/gmail_client_config.dart';
import '../exceptions/gmail_client_exception.dart';
import '../models/models.dart';

/// Core service for Gmail operations via Supabase Edge Functions.
///
/// Requires a Supabase project with the following Edge Functions deployed:
/// - `google-auth-callback`
/// - `send-email`
/// - `list-emails`
/// - `get-email`
///
/// And the following database tables:
/// - `org_email_config`
/// - `user_email_tokens`
/// - `synced_emails`
class EmailService {
  final SupabaseClient _client;
  final GmailClientConfig _config;

  /// Creates an [EmailService] backed by the given [SupabaseClient].
  ///
  /// Optionally accepts a [GmailClientConfig] for OAuth parameters like
  /// redirect URI and Gmail scopes.
  EmailService(this._client, [this._config = const GmailClientConfig()]);

  // ---------------------------------------------------------------------------
  // OAuth / Account
  // ---------------------------------------------------------------------------

  /// Exchanges a Google OAuth authorization code for Gmail API tokens.
  ///
  /// Stores the resulting access and refresh tokens in the `user_email_tokens`
  /// table, keyed by the authenticated Supabase user (or the explicit [userId]).
  ///
  /// Throws [GmailAuthException] on failure.
  Future<void> connectGoogleAccount(
    String serverAuthCode,
    String email, {
    String? redirectUri,
    String? userId,
  }) async {
    final response = await _client.functions.invoke(
      'google-auth-callback',
      body: {
        'code': serverAuthCode,
        'email': email,
        'user_id': userId ?? _requireUserId(),
        'redirect_uri':
            redirectUri ?? _config.gmailRedirectUri ?? 'postmessage',
      },
    );
    final data = response.data;
    if (data['error'] != null) {
      throw GmailAuthException(data['error'] as String);
    }
  }

  /// Removes stored Gmail tokens for the currently authenticated user.
  ///
  /// Throws [GmailAuthException] if no user is authenticated.
  Future<void> disconnectAccount() async {
    final userId = _requireUserId();
    await _client
        .from('user_email_tokens')
        .delete()
        .eq('user_id', userId);
  }

  /// Returns `true` if the current user has Gmail tokens stored.
  Future<bool> isEmailConnected() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('user_email_tokens')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Returns the email address of the connected Gmail account,
  /// or `null` if not connected.
  Future<String?> getConnectedEmail() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('user_email_tokens')
        .select('email')
        .eq('user_id', userId)
        .maybeSingle();

    return response?['email'] as String?;
  }

  /// Returns the sender display name, or `null` if not set.
  Future<String?> getDisplayName() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('user_email_tokens')
        .select('display_name')
        .eq('user_id', userId)
        .maybeSingle();

    return response?['display_name'] as String?;
  }

  /// Updates the sender display name for the current user.
  ///
  /// Throws [GmailAuthException] if no user is authenticated.
  Future<void> updateDisplayName(String displayName) async {
    final userId = _requireUserId();
    await _client
        .from('user_email_tokens')
        .update({
          'display_name': displayName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // Email operations
  // ---------------------------------------------------------------------------

  /// Lists emails from Gmail inbox.
  ///
  /// [query] — Gmail search query (same syntax as Gmail search box).
  /// [maxResults] — Max emails per page (default 20).
  /// [pageToken] — Token for fetching the next page.
  ///
  /// Returns a [ListEmailsResult] with messages and optional pagination token.
  Future<ListEmailsResult> listEmails({
    String? query,
    int maxResults = 20,
    String? pageToken,
  }) async {
    final response = await _client.functions.invoke(
      'list-emails',
      body: {
        'q': query,
        'maxResults': maxResults,
        'pageToken': pageToken,
      },
    );
    final data = response.data;
    if (data['error'] != null) {
      throw GmailClientException(data['error'] as String);
    }

    final messages = data['messages'] as List<dynamic>? ?? [];
    return ListEmailsResult(
      messages: messages
          .map((m) => EmailMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      nextPageToken: data['nextPageToken'] as String?,
      resultSizeEstimate: data['resultSizeEstimate'] ?? 0,
    );
  }

  /// Fetches a single email by Gmail message ID.
  ///
  /// Returns the full [EmailMessage] with parsed body (text and HTML).
  Future<EmailMessage> getEmail(String messageId) async {
    final response = await _client.functions.invoke(
      'get-email',
      body: {'id': messageId},
    );
    final data = response.data;
    if (data['error'] != null) {
      throw GmailClientException(data['error'] as String);
    }
    return EmailMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  /// Sends an email via Gmail.
  ///
  /// Required: [to], [subject], [body].
  /// Optional: [cc], [bcc], [attachments].
  ///
  /// [attachments] is a list of maps, each containing:
  /// - `filename` — the attachment file name.
  /// - `mimeType` — the MIME type (e.g. `application/pdf`).
  /// - `data` — base64-encoded file content.
  ///
  /// Returns a [SendEmailResult] with the assigned message/thread IDs.
  Future<SendEmailResult> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    List<Map<String, String>>? attachments,
  }) async {
    final response = await _client.functions.invoke(
      'send-email',
      body: {
        'to': to,
        'subject': subject,
        'body': body,
        if (cc != null) 'cc': cc,
        if (bcc != null) 'bcc': bcc,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      },
    );
    final data = response.data;
    if (data['error'] != null) {
      throw GmailSendException(data['error'] as String);
    }
    return SendEmailResult.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // Synced emails (local Supabase storage)
  // ---------------------------------------------------------------------------

  /// Returns emails previously synced to the local Supabase database.
  Future<List<EmailMessage>> getSyncedEmails({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('synced_emails')
        .select()
        .order('received_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => EmailMessage.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Organization email configuration
  // ---------------------------------------------------------------------------

  /// Returns the active OAuth configuration for the organization.
  Future<EmailConfig?> getOrgEmailConfig() async {
    final response = await _client
        .from('org_email_config')
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return EmailConfig.fromJson(response);
  }

  /// Creates or updates the organization's OAuth configuration.
  ///
  /// [webClientSecret] is a sensitive value — it is stored server-side
  /// and never exposed to the client. Handle with care.
  Future<void> saveOrgEmailConfig({
    required String webClientId,
    required String webClientSecret,
    String? iosClientId,
    String? androidClientId,
    String? projectId,
  }) async {
    await _client.from('org_email_config').upsert({
      'org_name': 'default',
      'google_web_client_id': webClientId,
      'google_web_client_secret': webClientSecret,
      'google_ios_client_id': iosClientId,
      'google_android_client_id': androidClientId,
      'google_project_id': projectId,
      'is_active': true,
    });
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Returns the current user ID or throws [GmailAuthException].
  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw GmailAuthException('User not authenticated');
    }
    return userId;
  }
}
