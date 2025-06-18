import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/firebase_auth_provider.dart';
import '../forgotpassword.dart';
import '../home.dart';
import '../register_screen.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le provider d'authentification
    final authProvider = Provider.of<FirebaseAuthProvider>(context);
    _isLoading = authProvider.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Afficher les erreurs d'authentification s'il y en a
          if (authProvider.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 16),
                    onPressed: () => authProvider.clearError(),
                  ),
                ],
              ),
            ),
          TextFormField(
            controller: _emailController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'E-mail',
              labelStyle: const TextStyle(color: AppColors.textFieldText),
              prefixIcon: const Icon(Icons.email, color: AppColors.textFieldText),
              filled: true,
              fillColor: AppColors.textFieldBackground.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              errorStyle: const TextStyle(color: AppColors.error),
            ),
            style: const TextStyle(color: AppColors.textFieldText),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _validateEmail(value),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: const TextStyle(color: AppColors.textFieldText),
              prefixIcon: const Icon(Icons.lock, color: AppColors.textFieldText),
              filled: true,
              fillColor: AppColors.textFieldBackground.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            ),
            style: const TextStyle(color: AppColors.textFieldText),
            obscureText: true,
            validator: (value) => _validatePassword(value),
          ),
          const SizedBox(height: 10),
          _buildForgotPasswordLink(),
          const SizedBox(height: 20),
          _buildLoginButton(),
          const SizedBox(height: 30),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildRegisterButton(context),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
    if (!value.contains('@')) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
    if (value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
    return null;
  }

  Widget _buildForgotPasswordLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: TextButton(
          onPressed: _isLoading ? null : _onForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'J\'ai oublié mon mot de passe',
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryButton,
              decorationThickness: 1.5,
              color: AppColors.textFieldText,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _isLoading ? null : _onLogin,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'Se connecter',
                style: TextStyle(fontSize: 18),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'ou',
            style: TextStyle(color: AppColors.primaryButton),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryButton,
        side: BorderSide(color: AppColors.primaryButton),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      ),
      onPressed: () => _onRegister(context),
      child: const Text(
        'Je suis nouveau !',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProgressScreen(),
          ),
        );
      }
    }
  }

  void _onForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _onRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }
}