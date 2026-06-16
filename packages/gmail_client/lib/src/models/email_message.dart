class EmailMessage {
  final String id;
  final String threadId;
  final String? from;
  final List<String>? to;
  final String? subject;
  final String? snippet;
  final String? bodyText;
  final String? bodyHtml;
  final List<String> labels;
  final bool isRead;
  final DateTime? date;

  const EmailMessage({
    required this.id,
    required this.threadId,
    this.from,
    this.to,
    this.subject,
    this.snippet,
    this.bodyText,
    this.bodyHtml,
    this.labels = const [],
    this.isRead = false,
    this.date,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'] ?? '',
      threadId: json['threadId'] ?? '',
      from: json['from'] as String?,
      to: json['to'] != null ? List<String>.from(json['to'] as List) : null,
      subject: json['subject'] as String?,
      snippet: json['snippet'] as String?,
      bodyText: json['bodyText'] as String?,
      bodyHtml: json['bodyHtml'] as String?,
      labels: json['labels'] != null ? List<String>.from(json['labels'] as List) : [],
      isRead: json['isRead'] ?? false,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
    );
  }

  factory EmailMessage.fromSupabase(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['gmail_message_id'] ?? '',
      threadId: json['thread_id'] ?? '',
      from: json['from_address'] as String?,
      to: json['to_addresses'] != null ? List<String>.from(json['to_addresses'] as List) : null,
      subject: json['subject'] as String?,
      snippet: json['snippet'] as String?,
      bodyText: json['body_text'] as String?,
      bodyHtml: json['body_html'] as String?,
      labels: json['labels'] != null ? List<String>.from(json['labels'] as List) : [],
      isRead: json['is_read'] ?? false,
      date: json['received_at'] != null ? DateTime.tryParse(json['received_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'gmail_message_id': id,
      'thread_id': threadId,
      'from_address': from,
      'to_addresses': to,
      'subject': subject,
      'snippet': snippet,
      'body_text': bodyText,
      'body_html': bodyHtml,
      'labels': labels,
      'is_read': isRead,
      'received_at': date?.toIso8601String(),
    };
  }
}
