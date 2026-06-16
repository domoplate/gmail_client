import 'package:gmail_client/gmail_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the Supabase client singleton from `Supabase.instance`.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides an [EmailService] bound to the current Supabase client.
final emailServiceProvider = Provider<EmailService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmailService(client);
});

/// Stream of Supabase auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// The currently authenticated user, or `null`.
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Whether the user has an active Supabase session.
final isLoggedInProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentSession != null;
});

/// Whether the current user has a Gmail account connected.
final emailConnectionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(emailServiceProvider);
  return service.isEmailConnected();
});

/// The email address of the connected Gmail account, or `null`.
final connectedEmailProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(emailServiceProvider);
  return service.getConnectedEmail();
});

/// The sender display name, or `null`.
final displayNameProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(emailServiceProvider);
  return service.getDisplayName();
});
