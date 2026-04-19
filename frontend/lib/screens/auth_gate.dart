import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'splash_screen.dart';

/// Root widget: restores session, shows splash for guests, then login or main.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showGuestSplash = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.bootstrapFuture;
    if (!mounted) return;
    if (auth.isAuthenticated) {
      setState(() => _showGuestSplash = false);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) setState(() => _showGuestSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const MainShell();
        }
        if (_showGuestSplash) {
          return const SplashScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
