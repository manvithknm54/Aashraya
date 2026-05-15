import 'package:flutter/material.dart';
import 'auth_screen.dart';

class LoginScreen extends StatelessWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return AuthScreen(role: role);
  }
}