import 'package:gmail_client/gmail_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Provider that fetches a single email by its Gmail message ID.
///
/// Usage:
/// ```dart
/// final emailAsync = ref.watch(emailDetailProvider(messageId));
/// ```
final emailDetailProvider =
    FutureProvider.family<EmailMessage?, String>((ref, messageId) async {
  final service = ref.watch(emailServiceProvider);
  return service.getEmail(messageId);
});
