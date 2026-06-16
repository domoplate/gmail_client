import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/compose_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/email_detail_screen.dart';
import 'screens/admin_config_screen.dart';
import 'package:gmail_client_flutter/gmail_client_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  if (kIsWeb) {
    cleanAuthUrlParams();
    debugPrint('[Auth] Auth-related URL parameters cleaned');
  }

  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    debugPrint('[Auth] Session found (user: ${session.user.email}), validating...');
    try {
      await Supabase.instance.client.auth.getUser();
      debugPrint('[Auth] Session valid');
    } catch (e) {
      debugPrint('[Auth] Session invalid ($e) - signing out');
      await Supabase.instance.client.auth.signOut();
    }
  } else {
    debugPrint('[Auth] No session');
  }

  runApp(const ProviderScope(child: GmailApp()));
}

class GmailApp extends StatelessWidget {
  const GmailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _buildPageRoute(const LoginScreen());
          case '/profile':
            return _buildPageRoute(const ProfileScreen());
          case '/inbox':
            return _buildPageRoute(const InboxScreen());
          case '/compose':
            return _buildPageRoute(const ComposeScreen());
          case '/email-detail':
            final args = settings.arguments as Map<String, dynamic>;
            return _buildPageRoute(EmailDetailScreen(
              messageId: args['messageId'] as String,
              threadId: args['threadId'] as String?,
            ));
          case '/admin':
            return _buildPageRoute(const AdminConfigScreen());
          default:
            return _buildPageRoute(const LoginScreen());
        }
      },
    );
  }

  MaterialPageRoute _buildPageRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
