import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gmail_client/gmail_client.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';
import 'compose_screen.dart';

class EmailDetailScreen extends ConsumerStatefulWidget {
  final String messageId;
  final String? threadId;

  const EmailDetailScreen({
    super.key,
    required this.messageId,
    this.threadId,
  });

  @override
  ConsumerState<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends ConsumerState<EmailDetailScreen> {
  EmailMessage? _email;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(emailServiceProvider);
      final email = await service.getEmail(widget.messageId);
      setState(() {
        _email = email;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE, d MMMM yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correo'),
        actions: [
          if (_email != null)
            IconButton(
              icon: const Icon(Icons.reply),
              tooltip: 'Responder',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ComposeScreen(
                    replyTo: _email!.from,
                    replySubject: _email!.subject != null
                        ? 'Re: ${_email!.subject}'
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEmail,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _email == null
                  ? const Center(child: Text('Correo no encontrado'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          _email!.subject ?? '(sin asunto)',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                (_email!.from ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _email!.from ?? 'Desconocido',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_email!.to != null && _email!.to!.isNotEmpty)
                                    Text(
                                      'Para: ${_email!.to!.join(', ')}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              _formatFullDate(_email!.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        if (_email!.bodyHtml != null && _email!.bodyHtml!.isNotEmpty)
                          _buildHtmlBody(_email!.bodyHtml!, theme)
                        else if (_email!.bodyText != null && _email!.bodyText!.isNotEmpty)
                          SelectableText(
                            _email!.bodyText!,
                            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                          )
                        else
                          Text(
                            '(sin contenido)',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildHtmlBody(String html, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        _stripHtml(html),
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .trim();
  }
}
