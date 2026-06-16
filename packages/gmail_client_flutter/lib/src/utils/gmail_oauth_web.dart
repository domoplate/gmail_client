import 'dart:async';
import 'dart:html' as html;

Future<String?> getGmailAuthCodeViaPopup({
  required String clientId,
  required List<String> scopes,
  required String redirectUri,
}) async {
  final scopeParam = scopes.join(' ');
  final url = 'https://accounts.google.com/o/oauth2/v2/auth'
      '?response_type=code'
      '&client_id=${Uri.encodeComponent(clientId)}'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&scope=${Uri.encodeComponent(scopeParam)}'
      '&access_type=offline'
      '&prompt=consent';

  final popup = html.window.open(url, 'gmail-oauth', 'width=500,height=600');
  final completer = Completer<String?>();

  Timer.periodic(const Duration(milliseconds: 300), (t) {
    final storage = html.window.localStorage;
    final code = storage['gmail_oauth_code'];
    final error = storage['gmail_oauth_error'];

    if (code != null) {
      storage.remove('gmail_oauth_code');
      try {
        popup.close();
      } catch (_) {}
      t.cancel();
      if (!completer.isCompleted) completer.complete(code);
      return;
    }

    if (error != null) {
      storage.remove('gmail_oauth_error');
      try {
        popup.close();
      } catch (_) {}
      t.cancel();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    if (popup.closed == true) {
      final lateCode = storage['gmail_oauth_code'];
      if (lateCode != null) {
        storage.remove('gmail_oauth_code');
        if (!completer.isCompleted) completer.complete(lateCode);
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
      t.cancel();
    }
  });

  Timer(const Duration(minutes: 5), () {
    if (!completer.isCompleted) completer.complete(null);
  });

  return completer.future;
}
