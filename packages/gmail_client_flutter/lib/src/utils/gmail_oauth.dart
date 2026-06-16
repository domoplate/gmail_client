import 'gmail_oauth_stub.dart'
    if (dart.library.html) 'gmail_oauth_web.dart' as impl;

Future<String?> getGmailAuthCodeViaPopup({
  required String clientId,
  required List<String> scopes,
  required String redirectUri,
}) {
  return impl.getGmailAuthCodeViaPopup(
    clientId: clientId,
    scopes: scopes,
    redirectUri: redirectUri,
  );
}
