import 'package:gmail_client/gmail_client.dart';
import 'package:supabase/supabase.dart';

void main() async {
  // Replace with your Supabase project credentials.
  final client = SupabaseClient(
    'https://your-project.supabase.co',
    'your-anon-key',
  );

  final emailService = EmailService(client, GmailClientConfig());

  // List recent emails
  final result = await emailService.listEmails(maxResults: 5);
  print('Found ${result.messages.length} emails');

  for (final email in result.messages) {
    print('  ${email.from}: ${email.subject}');
  }

  if (result.nextPageToken != null) {
    print('\nNext page token available for pagination.');
  }
}
