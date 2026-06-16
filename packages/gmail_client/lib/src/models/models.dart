import 'email_message.dart';

export 'email_config.dart';
export 'email_message.dart';

/// Result returned by [EmailService.listEmails].
class ListEmailsResult {
  /// The list of email messages for the current page.
  final List<EmailMessage> messages;

  /// Token for fetching the next page, or `null` if no more pages.
  final String? nextPageToken;

  /// Estimated total number of results (from Gmail API).
  final int resultSizeEstimate;

  const ListEmailsResult({
    this.messages = const [],
    this.nextPageToken,
    this.resultSizeEstimate = 0,
  });
}

/// Result returned by [EmailService.sendEmail].
class SendEmailResult {
  /// The Gmail message ID assigned by the API.
  final String id;

  /// The Gmail thread ID.
  final String threadId;

  /// Labels applied by Gmail (e.g., `SENT`).
  final List<String> labelIds;

  const SendEmailResult({
    required this.id,
    required this.threadId,
    this.labelIds = const [],
  });

  factory SendEmailResult.fromJson(Map<String, dynamic> json) {
    return SendEmailResult(
      id: json['message_id'] ?? '',
      threadId: json['thread_id'] ?? '',
      labelIds: json['label_ids'] != null
          ? List<String>.from(json['label_ids'] as List)
          : [],
    );
  }
}
