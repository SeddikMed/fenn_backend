import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/firebase_auth_provider.dart';
import 'home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le provider d'authentification
    final authProvider = Provider.of<FirebaseAuthProvider>(context);
    _isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Bouton de retour en haut à gauche
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primaryButton),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            // Contenu principal avec défilement
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Form(
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
                        
                        // Mascotte avec bulle améliorée
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mascotte plus visible
                            Container(
                              width: 80, // Taille augmentée
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2), // Fond pour mieux voir
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.asset(
                                  'assets/logo/mascotte_tete.png',
                                  fit: BoxFit.contain, // Meilleur ajustement
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Bulle de conversation en #4A5C7A
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A5C7A),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Bienvenue chez ton futur professeur d\'anglais !',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white, // Texte en blanc
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'Veuillez saisir vos informations personnelles',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.primaryButton,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Champs de saisie
                        _buildCustomTextField(
                          controller: _emailController,
                          label: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Veuillez entrer votre e-mail';
                            if (!value!.contains('@')) return 'Veuillez entrer un e-mail valide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        _buildCustomTextField(
                          controller: _firstNameController,
                          label: 'Nom d\'utilisateur',
                          enabled: !_isLoading,
                          validator: (value) => value?.isEmpty ?? true ? 'Veuillez entrer votre nom d\'utilisateur' : null,
                        ),
                        const SizedBox(height: 15),
                        
                        _buildCustomTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          obscureText: true,
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Veuillez entrer un mot de passe';
                            if (value!.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        _buildCustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmez le mot de passe',
                          obscureText: true,
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Veuillez confirmer votre mot de passe';
                            if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Bouton d'inscription
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryButton,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
                                    'Je m\'inscris',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF8D99AE).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
        );
        return;
      }

      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        username: _firstNameController.text.trim(),
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
}