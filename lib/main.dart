import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const CGSApp());
}

class CGSApp extends StatelessWidget {
  const CGSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema CGS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn;
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isChecking = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn) {
      return HomeScreen(onLogout: () => setState(() => _isLoggedIn = false));
    }

    return LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}
