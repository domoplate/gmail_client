import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gmail_client/gmail_client.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';
import 'compose_screen.dart';
import 'email_detail_screen.dart';
import 'profile_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  List<EmailMessage> _emails = [];
  bool _loading = true;
  bool _noTokens = false;
  String? _error;
  String? _nextPageToken;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails({String? pageToken}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(emailServiceProvider);
      final result = await service.listEmails(
        maxResults: 30,
        pageToken: pageToken,
      );

      setState(() {
        if (pageToken != null) {
          _emails.addAll(result.messages);
        } else {
          _emails = result.messages;
        }
        _nextPageToken = result.nextPageToken;
        _loading = false;
      });
    } on GmailTokenException {
      setState(() {
        _noTokens = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(date);
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de entrada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ComposeScreen()),
          );
          if (result == true) _loadEmails();
        },
        icon: const Icon(Icons.edit),
        label: const Text('Redactar'),
      ),
      body: _loading && _emails.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _noTokens
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Cuenta Gmail no conectada',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conecta tu cuenta para ver tus correos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Ir al perfil'),
                      ),
                    ],
                  ),
                )
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
                        onPressed: () => _loadEmails(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _emails.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No hay correos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Conecta tu cuenta de Gmail para empezar',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadEmails(),
                      child: ListView.separated(
                        itemCount: _emails.length + (_nextPageToken != null ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index >= _emails.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final email = _emails[index];
                          final isUnread = email.labels.contains('UNREAD');

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isUnread
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: Text(
                                (email.from ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUnread
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            title: Text(
                              email.from ?? 'Desconocido',
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email.subject ?? '(sin asunto)',
                                  style: TextStyle(
                                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email.snippet ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatDate(email.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnread
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmailDetailScreen(
                                    messageId: email.id,
                                    threadId: email.threadId,
                                  ),
                                ),
                              );
                              _loadEmails();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
