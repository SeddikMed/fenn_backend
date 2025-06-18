import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'widgets/auth_form.dart';
import 'widgets/auth_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: const BoxDecoration(
          color: Color(0xFFDAE6B2), // Remplace le gradient par une couleur unie
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const AuthLogo(),
                const SizedBox(height: 30),
                const AuthForm(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}