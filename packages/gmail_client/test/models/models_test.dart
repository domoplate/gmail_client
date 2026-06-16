import 'package:gmail_client/gmail_client.dart';
import 'package:test/test.dart';

void main() {
  group('EmailMessage', () {
    test('fromJson parses full email', () {
      final json = {
        'id': 'msg-001',
        'threadId': 'thread-001',
        'from': 'sender@example.com',
        'to': ['recipient@example.com'],
        'subject': 'Test Subject',
        'snippet': 'This is a snippet.',
        'bodyText': 'Hello world',
        'bodyHtml': '<p>Hello world</p>',
        'labels': ['INBOX', 'UNREAD'],
        'isRead': false,
        'date': '2026-06-15T12:00:00.000Z',
      };

      final email = EmailMessage.fromJson(json);

      expect(email.id, 'msg-001');
      expect(email.threadId, 'thread-001');
      expect(email.from, 'sender@example.com');
      expect(email.to, ['recipient@example.com']);
      expect(email.subject, 'Test Subject');
      expect(email.snippet, 'This is a snippet.');
      expect(email.bodyText, 'Hello world');
      expect(email.bodyHtml, '<p>Hello world</p>');
      expect(email.labels, ['INBOX', 'UNREAD']);
      expect(email.isRead, false);
      expect(email.date, DateTime.utc(2026, 6, 15, 12, 0, 0));
    });

    test('fromJson handles missing fields', () {
      final json = {
        'id': 'msg-002',
        'threadId': 'thread-002',
      };

      final email = EmailMessage.fromJson(json);

      expect(email.id, 'msg-002');
      expect(email.threadId, 'thread-002');
      expect(email.from, null);
      expect(email.subject, null);
      expect(email.snippet, null);
      expect(email.bodyText, null);
      expect(email.bodyHtml, null);
      expect(email.labels, isEmpty);
      expect(email.isRead, false);
      expect(email.date, null);
    });
  });

  group('EmailConfig', () {
    test('fromJson parses config', () {
      final json = {
        'id': 'cfg-001',
        'org_name': 'Test Org',
        'google_web_client_id': 'web-123.apps.googleusercontent.com',
        'google_ios_client_id': 'ios-123',
        'google_android_client_id': 'android-123',
      };

      final config = EmailConfig.fromJson(json);

      expect(config.id, 'cfg-001');
      expect(config.orgName, 'Test Org');
      expect(config.webClientId, 'web-123.apps.googleusercontent.com');
      expect(config.iosClientId, 'ios-123');
      expect(config.androidClientId, 'android-123');
    });
  });

  group('ListEmailsResult', () {
    test('holds messages and pagination', () {
      final email = EmailMessage(id: '1', threadId: 't1');
      final result = ListEmailsResult(
        messages: [email],
        nextPageToken: 'token-xyz',
        resultSizeEstimate: 42,
      );

      expect(result.messages, hasLength(1));
      expect(result.nextPageToken, 'token-xyz');
      expect(result.resultSizeEstimate, 42);
    });
  });

  group('SendEmailResult', () {
    test('fromJson parses send response', () {
      final json = {
        'message_id': 'msg-99',
        'thread_id': 'thread-99',
        'label_ids': ['SENT'],
      };

      final result = SendEmailResult.fromJson(json);

      expect(result.id, 'msg-99');
      expect(result.threadId, 'thread-99');
      expect(result.labelIds, ['SENT']);
    });
  });

  group('GmailClientConfig', () {
    test('defaultGmailScopes has required scopes', () {
      final scopes = GmailClientConfig.defaultGmailScopes;
      expect(scopes, contains('https://www.googleapis.com/auth/gmail.send'));
      expect(scopes, contains('https://www.googleapis.com/auth/gmail.modify'));
      expect(scopes, contains('https://www.googleapis.com/auth/gmail.readonly'));
    });
  });

  group('Exceptions', () {
    test('GmailClientException has message and code', () {
      final ex = GmailClientException('test error', code: 'TEST_CODE');
      expect(ex.message, 'test error');
      expect(ex.code, 'TEST_CODE');
      expect(ex.toString(), contains('TEST_CODE'));
    });

    test('GmailAuthException inherits properly', () {
      final ex = GmailAuthException('auth failed');
      expect(ex, isA<GmailClientException>());
      expect(ex.message, 'auth failed');
    });

    test('GmailTokenException inherits properly', () {
      final ex = GmailTokenException('token expired');
      expect(ex, isA<GmailClientException>());
      expect(ex.message, 'token expired');
    });
  });
}
