import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo/mascotte.png',
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          'Bienvenue',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8B1F),
          ),
        ),
      ],
    );
  }
}