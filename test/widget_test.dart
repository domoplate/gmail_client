import 'package:flutter_test/flutter_test.dart';

import 'package:gmail_client/gmail_client.dart';

void main() {
  test('gmail_client can be imported and instantiated', () {
    final email = EmailMessage(
      id: '1',
      threadId: 'thread1',
      snippet: 'Hello world',
      subject: 'Test',
      from: 'sender@test.com',
      to: ['receiver@test.com'],
      date: DateTime(2025, 1, 1),
      bodyText: 'This is a test email.',
      labels: ['INBOX'],
    );

    expect(email.id, '1');
    expect(email.subject, 'Test');
    expect(email.from, 'sender@test.com');
  });

  test('SendEmailResult can be created', () {
    final result = SendEmailResult(id: 'msg1', threadId: 'th1');
    expect(result.id, 'msg1');
    expect(result.threadId, 'th1');
  });

  test('ListEmailsResult with nextPageToken', () {
    final result = ListEmailsResult(
      messages: [],
      resultSizeEstimate: 0,
      nextPageToken: 'token123',
    );
    expect(result.nextPageToken, 'token123');
  });
}
