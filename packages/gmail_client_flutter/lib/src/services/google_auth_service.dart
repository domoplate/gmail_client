import 'package:flutter/foundation.dart';
import 'package:gmail_client/gmail_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../utils/gmail_oauth.dart';

/// Service for Google Sign-In and Gmail OAuth token exchange.
class GoogleAuthService {
  final EmailService _emailService;
  final GmailClientConfig _config;
  GoogleSignIn? _googleSignIn;
  bool _initializing = false;
  bool _initialized = false;

  GoogleAuthService(this._emailService, [this._config = const GmailClientConfig()]);

  /// Initializes Google Sign-In with the given OAuth client IDs.
  ///
  /// Must be called before [signIn] or [getServerAuthCode].
  Future<void> initialize({
    required String webClientId,
    String? iosClientId,
  }) async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      _googleSignIn = GoogleSignIn.instance;
      if (kIsWeb) {
        await _googleSignIn!.initialize(clientId: webClientId);
      } else {
        await _googleSignIn!.initialize(
          clientId: iosClientId,
          serverClientId: webClientId,
        );
      }
      _initialized = true;
    } finally {
      _initializing = false;
    }
  }

  /// Signs in with Google (native platforms only).
  ///
  /// Returns the [GoogleSignInAccount], or `null` if the user cancels.
  /// Throws [GmailAuthException] if called before [initialize].
  Future<GoogleSignInAccount?> signIn() async {
    _ensureInitialized();
    if (kIsWeb) {
      return _googleSignIn!.attemptLightweightAuthentication();
    }
    return _googleSignIn!.authenticate();
  }

  /// Opens a popup window for Gmail OAuth authorization (web only).
  ///
  /// Returns the authorization code, or `null` if the user cancels.
  Future<String?> getGmailAuthCodeForWeb(String clientId) async {
    return getGmailAuthCodeViaPopup(
      clientId: clientId,
      scopes: _config.gmailScopes ?? GmailClientConfig.defaultGmailScopes,
      redirectUri:
          _config.gmailRedirectUri ?? 'http://localhost:3000/gmail-callback.html',
    );
  }

  /// Exchanges a [GoogleSignInAccount] for a server-side authorization code.
  ///
  /// Returns the one-time auth code to be exchanged for Gmail tokens.
  Future<String?> getServerAuthCode(GoogleSignInAccount account) async {
    final authorization = await account.authorizationClient
        .authorizeServer(_config.gmailScopes ?? GmailClientConfig.defaultGmailScopes);
    return authorization?.serverAuthCode;
  }

  /// Exchanges the OAuth authorization code for Gmail API tokens and
  /// stores them via [EmailService.connectGoogleAccount].
  Future<void> connectGmailAccount({
    required String serverAuthCode,
    required String email,
    String? redirectUri,
    String? userId,
  }) async {
    await _emailService.connectGoogleAccount(
      serverAuthCode,
      email,
      redirectUri: redirectUri ?? _config.gmailRedirectUri,
      userId: userId,
    );
  }

  /// Signs out of Google and revokes local session.
  Future<void> signOut() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw GmailAuthException('GoogleAuthService not initialized. Call initialize() first.');
    }
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final emailService = ref.watch(emailServiceProvider);
  return GoogleAuthService(emailService);
});
