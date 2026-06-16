import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Represents an email attachment ready to be sent.
class AttachmentInfo {
  final String filename;
  final String mimeType;
  final String data;
  final int size;

  const AttachmentInfo({
    required this.filename,
    required this.mimeType,
    required this.data,
    required this.size,
  });
}

/// State for the compose provider.
class ComposeState {
  final bool sending;
  final List<AttachmentInfo> attachments;
  final bool picking;
  final String? error;
  final bool sent;

  const ComposeState({
    this.sending = false,
    this.attachments = const [],
    this.picking = false,
    this.error,
    this.sent = false,
  });

  ComposeState copyWith({
    bool? sending,
    List<AttachmentInfo>? attachments,
    bool? picking,
    String? error,
    bool? sent,
    bool clearError = false,
  }) {
    return ComposeState(
      sending: sending ?? this.sending,
      attachments: attachments ?? this.attachments,
      picking: picking ?? this.picking,
      error: clearError ? null : (error ?? this.error),
      sent: sent ?? this.sent,
    );
  }
}

/// Maps a file extension to its MIME type.
String mimeFromExtension(String ext) {
  const map = {
    'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
    'gif': 'image/gif', 'bmp': 'image/bmp', 'webp': 'image/webp',
    'svg': 'image/svg+xml',
    'mp4': 'video/mp4', 'mov': 'video/quicktime', 'avi': 'video/x-msvideo',
    'mkv': 'video/x-matroska', 'webm': 'video/webm',
    'mp3': 'audio/mpeg', 'wav': 'audio/wav', 'ogg': 'audio/ogg',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip': 'application/zip', 'rar': 'application/x-rar-compressed',
    '7z': 'application/x-7z-compressed',
    'txt': 'text/plain', 'csv': 'text/csv', 'html': 'text/html',
    'json': 'application/json', 'xml': 'application/xml',
  };
  return map[ext.toLowerCase()] ?? 'application/octet-stream';
}

/// Callback type for picking attachments.
/// Returns a list of [AttachmentInfo] or throws on cancel/error.
typedef AttachmentPicker = Future<List<AttachmentInfo>> Function();

/// Default [AttachmentPicker] implementation using the `file_picker` package.
Future<List<AttachmentInfo>> defaultAttachmentPicker() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
  );
  if (result == null) return const [];

  final attachments = <AttachmentInfo>[];
  for (final file in result.files) {
    if (file.bytes != null) {
      attachments.add(AttachmentInfo(
        filename: file.name,
        mimeType: mimeFromExtension(file.extension ?? ''),
        data: base64Encode(file.bytes!),
        size: file.size,
      ));
    }
  }
  return attachments;
}

/// Notifier that manages compose state: attachments, sending.
class ComposeNotifier extends StateNotifier<ComposeState> {
  final Ref _ref;
  final AttachmentPicker _picker;

  ComposeNotifier(this._ref, [this._picker = defaultAttachmentPicker])
      : super(const ComposeState());

  /// Opens the file picker and adds selected files as attachments.
  Future<void> pickAttachments() async {
    state = state.copyWith(picking: true);
    try {
      final attachments = await _picker();
      state = state.copyWith(
        attachments: [...state.attachments, ...attachments],
        picking: false,
      );
    } catch (e) {
      state = state.copyWith(
        picking: false,
        error: 'Failed to pick files: $e',
      );
    }
  }

  /// Removes an attachment at the given [index].
  void removeAttachment(int index) {
    final updated = [...state.attachments];
    updated.removeAt(index);
    state = state.copyWith(attachments: updated);
  }

  /// Sends the email with the current attachments.
  ///
  /// Returns `true` on success, `false` on failure (check [ComposeState.error]).
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
  }) async {
    state = state.copyWith(sending: true, clearError: true);

    try {
      final service = _ref.read(emailServiceProvider);
      await service.sendEmail(
        to: to,
        subject: subject,
        body: body,
        cc: cc,
        bcc: bcc,
        attachments: state.attachments.isNotEmpty
            ? state.attachments
                .map((a) => {
                      'filename': a.filename,
                      'mimeType': a.mimeType,
                      'data': a.data,
                    })
                .toList()
            : null,
      );

      state = state.copyWith(sending: false, sent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        sending: false,
        error: 'Failed to send email: $e',
      );
      return false;
    }
  }

  /// Resets state for composing a new email.
  void reset() {
    state = const ComposeState();
  }
}

/// Provider for compose state.
final composeProvider =
    StateNotifierProvider<ComposeNotifier, ComposeState>((ref) {
  return ComposeNotifier(ref);
});
