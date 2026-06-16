import 'package:flutter_test/flutter_test.dart';
import 'package:gmail_client/gmail_client.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';

void main() {
  group('EmailMessage.toSupabase', () {
    test('serializes all fields', () {
      final email = EmailMessage(
        id: 'msg-001',
        threadId: 'thread-001',
        from: 'sender@example.com',
        to: ['a@a.com', 'b@b.com'],
        subject: 'Test',
        snippet: 'Snippet',
        bodyText: 'Hello',
        bodyHtml: '<p>Hello</p>',
        labels: ['INBOX'],
        isRead: true,
        date: DateTime.utc(2026, 6, 15, 12, 0, 0),
      );

      final json = email.toSupabase();

      expect(json['gmail_message_id'], 'msg-001');
      expect(json['thread_id'], 'thread-001');
      expect(json['from_address'], 'sender@example.com');
      expect(json['to_addresses'], ['a@a.com', 'b@b.com']);
      expect(json['subject'], 'Test');
      expect(json['is_read'], true);
    });
  });

  group('EmailMessage.fromSupabase', () {
    test('deserializes from Supabase column names', () {
      final json = {
        'gmail_message_id': 'msg-002',
        'thread_id': 'thread-002',
        'from_address': 'test@example.com',
        'to_addresses': ['recipient@example.com'],
        'subject': 'Hello',
        'snippet': 'Hi there',
        'body_text': 'Body',
        'body_html': '<p>Body</p>',
        'labels': ['INBOX', 'IMPORTANT'],
        'is_read': false,
        'received_at': '2026-06-15T12:00:00Z',
      };

      final email = EmailMessage.fromSupabase(json);

      expect(email.id, 'msg-002');
      expect(email.threadId, 'thread-002');
      expect(email.from, 'test@example.com');
      expect(email.labels, ['INBOX', 'IMPORTANT']);
      expect(email.isRead, false);
    });
  });

  group('mimeFromExtension', () {
    test('maps known extensions', () {
      expect(mimeFromExtension('pdf'), 'application/pdf');
      expect(mimeFromExtension('png'), 'image/png');
      expect(mimeFromExtension('jpg'), 'image/jpeg');
      expect(mimeFromExtension('jpeg'), 'image/jpeg');
      expect(mimeFromExtension('docx'),
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
    });

    test('returns octet-stream for unknown extensions', () {
      expect(mimeFromExtension('xyz'), 'application/octet-stream');
      expect(mimeFromExtension(''), 'application/octet-stream');
    });
  });

  group('ComposeState', () {
    test('initial state is clean', () {
      const state = ComposeState();
      expect(state.sending, false);
      expect(state.attachments, isEmpty);
      expect(state.picking, false);
      expect(state.sent, false);
      expect(state.error, null);
    });

    test('copyWith updates fields', () {
      const state = ComposeState();
      final updated = state.copyWith(sending: true);
      expect(updated.sending, true);
      expect(updated.attachments, state.attachments);
    });

    test('copyWith clearError removes error', () {
      final state = const ComposeState().copyWith(error: 'err');
      expect(state.error, 'err');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, null);
    });
  });

  group('InboxState', () {
    test('initial state is clean', () {
      const state = InboxState();
      expect(state.emails, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLoadingMore, false);
      expect(state.error, null);
      expect(state.noTokens, false);
    });

    test('copyWith updates fields', () {
      const state = InboxState();
      final updated = state.copyWith(isLoading: true, noTokens: true);
      expect(updated.isLoading, true);
      expect(updated.noTokens, true);
    });
  });
}
