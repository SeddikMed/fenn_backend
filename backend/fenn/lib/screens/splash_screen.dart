import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/firebase_auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier l'état d'authentification après le rendu initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  // Vérifier si l'utilisateur est authentifié
  Future<void> _checkAuth() async {
    final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    // Naviguer vers l'écran approprié en fonction de l'état d'authentification
    if (authProvider.isAuthenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProgressScreen()),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAE6B2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo/mascotte.png',
              height: 150,
            ),
            const SizedBox(height: 30),
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 