import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gmail_client_flutter/gmail_client_flutter.dart';
import 'inbox_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _connecting = false;
  bool _gmailConnected = false;
  String? _connectedEmail;
  final _displayNameController = TextEditingController();
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final service = ref.read(emailServiceProvider);
    final connected = await service.isEmailConnected();
    final connectedEmail = await service.getConnectedEmail();
    final displayName = await service.getDisplayName();
    if (mounted) {
      setState(() {
        _gmailConnected = connected;
        _connectedEmail = connectedEmail;
        if (displayName != null) {
          _displayNameController.text = displayName;
        }
      });
    }

    final config = await service.getOrgEmailConfig();
    if (config != null && config.webClientId != 'PLACEHOLDER_CLIENT_ID') {
      final googleAuth = ref.read(googleAuthServiceProvider);
      await googleAuth.initialize(
        webClientId: config.webClientId,
        iosClientId: config.iosClientId.isNotEmpty ? config.iosClientId : null,
      );
    }
  }

  Future<void> _connectGmail() async {
    setState(() => _connecting = true);

    try {
      final emailService = ref.read(emailServiceProvider);
      final googleAuth = ref.read(googleAuthServiceProvider);

      final config = await emailService.getOrgEmailConfig();
      if (config == null || config.webClientId == 'PLACEHOLDER_CLIENT_ID') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No hay configuración OAuth. Configúrala en el panel de administración.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión no encontrada')),
          );
        }
        return;
      }

      String? authCode;

      if (kIsWeb) {
        authCode = await googleAuth.getGmailAuthCodeForWeb(config.webClientId);
      } else {
        final account = await googleAuth.signIn();
        if (account == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo autenticar con Google')),
            );
          }
          return;
        }
        authCode = await googleAuth.getServerAuthCode(account);
      }

      if (authCode == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al obtener el código de autorización')),
          );
        }
        return;
      }

      await emailService.connectGoogleAccount(
        authCode,
        userEmail,
        userId: Supabase.instance.client.auth.currentUser?.id,
        redirectUri: kIsWeb ? 'http://localhost:3000/gmail-callback.html' : null,
      );

      setState(() {
        _gmailConnected = true;
        _connectedEmail = userEmail;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta $userEmail conectada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _saveDisplayName() async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _savingName = true);

    try {
      final service = ref.read(emailServiceProvider);
      await service.updateDisplayName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre guardado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Administración',
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.email ?? 'Usuario',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Cuenta de Correo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gmailConnected
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _gmailConnected ? 'Conectada' : 'No conectada',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _gmailConnected
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_gmailConnected && _connectedEmail != null) ...[
                    Text(
                      _connectedEmail!,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del remitente',
                        hintText: 'Tu nombre visible en los correos',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _savingName ? null : _saveDisplayName,
                        icon: _savingName
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar nombre'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _connecting ? null : _connectGmail,
                      icon: _connecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(_gmailConnected
                          ? 'Reconectar cuenta'
                          : 'Conectar cuenta de Gmail'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Bandeja de entrada'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InboxScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
