import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gmail_client_flutter/gmail_client_flutter.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final String? replyTo;
  final String? replySubject;

  const ComposeScreen({super.key, this.replyTo, this.replySubject});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  final List<Map<String, dynamic>> _attachments = [];
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    if (widget.replyTo != null) _toController.text = widget.replyTo!;
    if (widget.replySubject != null) _subjectController.text = widget.replySubject!;
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _mimeFromExtension(String ext) {
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'html': 'text/html',
      'json': 'application/json',
      'xml': 'application/xml',
    };
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }

  Future<void> _pickFiles() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (result != null && mounted) {
        setState(() {
          for (final file in result.files) {
            if (file.bytes != null) {
              _attachments.add({
                'filename': file.name,
                'mimeType': _mimeFromExtension(file.extension ?? ''),
                'data': base64Encode(file.bytes!),
                'size': file.size,
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _sendEmail() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo "Para" es obligatorio')),
      );
      return;
    }

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo "Asunto" es obligatorio')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final service = ref.read(emailServiceProvider);
      await service.sendEmail(
        to: to,
        subject: subject,
        body: body,
        cc: _ccController.text.trim().isNotEmpty ? _ccController.text.trim() : null,
        bcc: _bccController.text.trim().isNotEmpty ? _bccController.text.trim() : null,
        attachments: _attachments.isNotEmpty
            ? _attachments
                .map((a) => {
                      'filename': a['filename'] as String,
                      'mimeType': a['mimeType'] as String,
                      'data': a['data'] as String,
                    })
                .toList()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo enviado exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redactar'),
        actions: [
          IconButton(
            onPressed: _sending ? null : _pickFiles,
            icon: _picking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            tooltip: 'Adjuntar archivo',
          ),
          TextButton.icon(
            onPressed: _sending ? null : _sendEmail,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Enviar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _toController,
            decoration: const InputDecoration(
              labelText: 'Para',
              hintText: 'correo@ejemplo.com',
              prefixIcon: Icon(Icons.person_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ccController,
            decoration: const InputDecoration(
              labelText: 'CC',
              hintText: 'cc@ejemplo.com',
              prefixIcon: Icon(Icons.people_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bccController,
            decoration: const InputDecoration(
              labelText: 'CCO',
              hintText: 'cco@ejemplo.com',
              prefixIcon: Icon(Icons.visibility_off_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Asunto',
              hintText: 'Asunto del correo',
              prefixIcon: Icon(Icons.subject),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Escribe tu mensaje...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.message_outlined),
              ),
            ),
            maxLines: 12,
            textInputAction: TextInputAction.newline,
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Archivos adjuntos (${_attachments.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final att = entry.value;
              final filename = att['filename'] as String;
              final size = att['size'] as int;
              final ext = filename.split('.').last.toUpperCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ext.length <= 4 ? ext : 'FILE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    _formatSize(size),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _removeAttachment(index),
                    tooltip: 'Quitar adjunto',
                  ),
                ),
              );
            }),
          ],
          if (_attachments.isEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _sending ? null : _pickFiles,
              icon: _picking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: const Text('Adjuntar archivo'),
            ),
          ],
        ],
      ),
    );
  }
}
