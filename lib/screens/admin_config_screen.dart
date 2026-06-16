import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gmail_client_flutter/gmail_client_flutter.dart';

class AdminConfigScreen extends ConsumerStatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  ConsumerState<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends ConsumerState<AdminConfigScreen> {
  final _webClientIdController = TextEditingController();
  final _webSecretController = TextEditingController();
  final _iosClientIdController = TextEditingController();
  final _androidClientIdController = TextEditingController();
  final _projectIdController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final service = ref.read(emailServiceProvider);
    final config = await service.getOrgEmailConfig();
    if (config != null && mounted) {
      setState(() {
        _webClientIdController.text = config.webClientId == 'PLACEHOLDER_CLIENT_ID' ? '' : config.webClientId;
        _iosClientIdController.text = config.iosClientId;
        _androidClientIdController.text = config.androidClientId;
      });
    }
  }

  Future<void> _saveConfig() async {
    final webClientId = _webClientIdController.text.trim();
    final webSecret = _webSecretController.text.trim();

    if (webClientId.isEmpty || webSecret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web Client ID y Secret son obligatorios')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final service = ref.read(emailServiceProvider);
      await service.saveOrgEmailConfig(
        webClientId: webClientId,
        webClientSecret: webSecret,
        iosClientId: _iosClientIdController.text.trim().isNotEmpty
            ? _iosClientIdController.text.trim()
            : null,
        androidClientId: _androidClientIdController.text.trim().isNotEmpty
            ? _androidClientIdController.text.trim()
            : null,
        projectId: _projectIdController.text.trim().isNotEmpty
            ? _projectIdController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada exitosamente')),
        );
        _loadConfig();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _webClientIdController.dispose();
    _webSecretController.dispose();
    _iosClientIdController.dispose();
    _androidClientIdController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración OAuth'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Guía de configuración',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Ve a https://console.cloud.google.com\n'
                  '2. Crea un proyecto y habilita la Gmail API\n'
                  '3. Ve a Google Auth Platform → Branding\n'
                  '4. Configura la pantalla de consentimiento OAuth\n'
                  '5. En Clients, crea un OAuth Client ID tipo "Web application"\n'
                  '6. Agrega como redirect URI la URL de callback de Supabase\n'
                  '7. Copia aquí el Client ID y Client Secret',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Credenciales OAuth 2.0',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _webClientIdController,
            decoration: const InputDecoration(
              labelText: 'Web Client ID *',
              hintText: 'xxx.apps.googleusercontent.com',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _webSecretController,
            decoration: const InputDecoration(
              labelText: 'Web Client Secret *',
              hintText: 'GOCSPX-xxx',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Opcional (apps nativas)',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _iosClientIdController,
            decoration: const InputDecoration(
              labelText: 'iOS Client ID',
              hintText: 'xxx.apps.googleusercontent.com',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _androidClientIdController,
            decoration: const InputDecoration(
              labelText: 'Android Client ID',
              hintText: 'xxx.apps.googleusercontent.com',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _projectIdController,
            decoration: const InputDecoration(
              labelText: 'Google Cloud Project ID',
              hintText: 'my-project-123',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveConfig,
              child: _saving
                  ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  : const Text('Guardar configuración'),
            ),
          ),
        ],
      ),
    );
  }
}
