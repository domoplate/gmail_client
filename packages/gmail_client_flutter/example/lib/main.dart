import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );

  runApp(const ProviderScope(child: GmailClientExampleApp()));
}

class GmailClientExampleApp extends StatelessWidget {
  const GmailClientExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail Client Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const InboxExamplePage(),
    );
  }
}

class InboxExamplePage extends ConsumerWidget {
  const InboxExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxProvider);
    final isConnected = ref.watch(emailConnectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gmail Client Example')),
      body: isConnected.maybeWhen(
        data: (connected) => !connected
            ? const Center(child: Text('Connect your Gmail account'))
            : state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: state.emails.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(state.emails[i].subject ?? ''),
                      subtitle: Text(state.emails[i].from ?? ''),
                    ),
                  ),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(inboxProvider.notifier).refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
