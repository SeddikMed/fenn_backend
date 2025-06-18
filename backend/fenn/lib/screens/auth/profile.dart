import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/firebase_auth_provider.dart';
import '../../core/models/user_progress.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
      final imageUrl = await authProvider.getProfileImageUrl();
      
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
      print("Erreur lors du chargement de l'image de profil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le provider d'authentification
    final authProvider = Provider.of<FirebaseAuthProvider>(context);
    
    // Récupérer les données de l'utilisateur
    final userData = authProvider.userData;
    final user = authProvider.user;
    
    // Récupérer les données de progression
    final userProgress = authProvider.userProgress;
    
    // Nom d'utilisateur (depuis userData ou user.displayName)
    final username = userData?['username'] ?? user?.displayName ?? 'Utilisateur';
    final email = userData?['email'] ?? user?.email ?? '';
    
    // Déterminer le niveau en fonction du pourcentage de progression
    final level = _getUserLevel(userProgress.progressPercentage);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Afficher un indicateur de chargement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mise à jour des données...'))
              );
              
              // Mettre à jour les données utilisateur
              await Provider.of<FirebaseAuthProvider>(context, listen: false).checkAuthStatus();
              
              // Recharger l'image de profil
              setState(() {
                _isLoadingImage = true;
              });
              await _loadProfileImage();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Données mises à jour !'))
                );
              }
            },
            tooltip: 'Rafraîchir les données',
          ),
        ],
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryButton),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Section Photo de profil et informations
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _isLoadingImage
                            ? const SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryButton),
                                ),
                              )
                            : _profileImageUrl != null
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(_profileImageUrl!),
                                    backgroundColor: AppColors.primaryButton,
                                  )
                                : const CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.primaryButton,
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                        const SizedBox(height: 15),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          level,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProfileStat(userProgress.completedLessons.toString(), 'Leçons'),
                            _buildProfileStat(userProgress.currentStreak.toString(), 'Série'),
                            _buildProfileStat(userProgress.formattedProgressPercentage, 'Progression'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Paramètres
                  _buildSectionTitle('Paramètres'),
                  _buildSettingsItem(
                    Icons.notifications,
                    'Notifications',
                        () => _showNotificationSettings(context),
                  ),
                  _buildSettingsItem(
                    Icons.lock,
                    'Confidentialité',
                        () => _showPrivacySettings(context),
                  ),
                  _buildSettingsItem(
                    Icons.help,
                    'Centre d\'aide',
                        () => _showHelpCenter(context),
                  ),
                  _buildSettingsItem(
                    Icons.info,
                    'À propos',
                        () => _showAboutDialog(context),
                  ),

                  // Section Actions
                  const SizedBox(height: 20),
                  _buildSectionTitle('Actions'),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _editProfile(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: AppColors.primaryButton,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Modifier le profil',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.primaryButton,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _changePassword(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: AppColors.primaryButton,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Changer le mot de passe',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.primaryButton,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Fonctions pour les actions des boutons

  void _editProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    ).then((_) {
      // Rafraîchir les données du provider après retour de la page d'édition
      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
      authProvider.checkAuthStatus();
    });
  }

  void _changePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.primaryButton),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue

                // Récupération du provider d'authentification
                final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
                
                // Déconnexion via le provider
                await authProvider.logout();

                // Redirection vers l'écran de login
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }

                // Affichage d'un message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnexion réussie')),
                  );
                }
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpCenterScreen(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('À propos'),
          content: const Text(
            'Application d\'apprentissage d\'anglais Fennling\nVersion 1.0.0\n\n© 2025 Équipe Fenn',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: TextStyle(color: AppColors.primaryButton),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widgets helper
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primaryButton,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  // Méthode pour déterminer le niveau de l'utilisateur
  String _getUserLevel(double progressPercentage) {
    if (progressPercentage < 10) {
      return 'Débutant';
    } else if (progressPercentage < 30) {
      return 'Apprenti';
    } else if (progressPercentage < 60) {
      return 'Intermédiaire';
    } else if (progressPercentage < 80) {
      return 'Avancé';
    } else {
      return 'Expert';
    }
  }
}

// Écran d'édition de profil
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  bool _isLoading = false;
  String? _errorMessage;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Récupérer les données de l'utilisateur
    final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    final user = authProvider.user;
    
    // Initialiser le contrôleur avec le nom d'utilisateur actuel
    _usernameController = TextEditingController(
      text: userData?['username'] ?? user?.displayName ?? '',
    );
    
    // Charger la photo de profil existante s'il y en a une
    _loadProfileImage();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // Méthode pour charger la photo de profil existante
  Future<void> _loadProfileImage() async {
    final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
    final photoURL = await authProvider.getProfileImageUrl();
    
    if (photoURL != null && mounted) {
      setState(() {
        // Pas besoin de stocker l'URL, on l'affichera directement
      });
    }
  }

  // Méthode pour sélectionner une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection de l\'image: ${e.toString()}';
      });
    }
  }

  // Méthode pour afficher une boîte de dialogue de choix de source d'image
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une source'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Appareil photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galerie'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Stack(
                children: [
                  _imageFile != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_imageFile!),
                      )
                    : FutureBuilder<String?>(
                        future: authProvider.getProfileImageUrl(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryButton),
                              ),
                            );
                          }
                          
                          if (snapshot.hasData && snapshot.data != null) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(snapshot.data!),
                              backgroundColor: AppColors.primaryButton,
                            );
                          }
                          
                          return const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryButton,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryButton,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Appuyez pour modifier la photo',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            
            // Formulaire
            if (_errorMessage != null)
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
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom d\'utilisateur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.primaryButton)
                          : const Text(
                              'Enregistrer les modifications',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer le provider d'authentification
      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
      
      // Télécharger l'image si une nouvelle a été sélectionnée
      if (_imageFile != null) {
        final imageResult = await authProvider.uploadProfileImage(_imageFile!);
        if (!imageResult['success']) {
          setState(() {
            _errorMessage = imageResult['message'];
            _isLoading = false;
          });
          return;
        }
      }
      
      // Mettre à jour le nom d'utilisateur
      final result = await authProvider.updateUserData(
        username: _usernameController.text.trim(),
      );
      
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Écran de changement de mot de passe
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Changer le mot de passe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: AppColors.primaryButton,
            ),
            const SizedBox(height: 20),
            
            // Message de succès
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Message d'erreur
            if (_errorMessage != null)
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
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe actuel';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nouveau mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.primaryButton)
                          : const Text(
                              'Mettre à jour le mot de passe',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Récupérer le provider d'authentification
      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
      
      // Mettre à jour le mot de passe
      final result = await authProvider.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _successMessage = result['message'];
          // Vider les champs en cas de succès
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      });
    }
  }
}

// Écran des paramètres de notification
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _enableAllNotifications = true;
  bool _enableLessonReminders = true;
  bool _enableNewContentNotifications = true;
  bool _enableAchievementNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres de notification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('Général'),
          SwitchListTile(
            title: const Text('Activer toutes les notifications'),
            subtitle: const Text('Contrôle l\'ensemble des notifications de l\'application'),
            value: _enableAllNotifications,
            onChanged: (bool value) {
              setState(() {
                _enableAllNotifications = value;
                // Si on désactive toutes les notifications, on désactive aussi les sous-options
                if (!value) {
                  _enableLessonReminders = false;
                  _enableNewContentNotifications = false;
                  _enableAchievementNotifications = false;
                }
              });
              _showNotificationFeedback(value);
            },
            activeColor: AppColors.primaryButton,
          ),
          const Divider(),
          _buildSectionTitle('Types de notifications'),
          SwitchListTile(
            title: const Text('Rappels de leçons'),
            subtitle: const Text('Recevez des rappels pour continuer votre apprentissage'),
            value: _enableLessonReminders && _enableAllNotifications,
            onChanged: _enableAllNotifications 
                ? (bool value) {
                    setState(() {
                      _enableLessonReminders = value;
                    });
                    _showNotificationFeedback(value);
                  }
                : null,
            activeColor: AppColors.primaryButton,
          ),
          SwitchListTile(
            title: const Text('Nouveau contenu'),
            subtitle: const Text('Soyez informé quand de nouvelles leçons sont disponibles'),
            value: _enableNewContentNotifications && _enableAllNotifications,
            onChanged: _enableAllNotifications 
                ? (bool value) {
                    setState(() {
                      _enableNewContentNotifications = value;
                    });
                    _showNotificationFeedback(value);
                  }
                : null,
            activeColor: AppColors.primaryButton,
          ),
          SwitchListTile(
            title: const Text('Réussites et récompenses'),
            subtitle: const Text('Soyez notifié de vos accomplissements'),
            value: _enableAchievementNotifications && _enableAllNotifications,
            onChanged: _enableAllNotifications 
                ? (bool value) {
                    setState(() {
                      _enableAchievementNotifications = value;
                    });
                    _showNotificationFeedback(value);
                  }
                : null,
            activeColor: AppColors.primaryButton,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  void _showNotificationFeedback(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled 
              ? 'Notification activée' 
              : 'Notification désactivée'
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// Écran des paramètres de confidentialité
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareProgress = true;
  bool _allowDataCollection = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres de confidentialité'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gérez vos préférences de confidentialité',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Partage de progression'),
            subtitle: const Text('Permettre le partage de votre progression avec d\'autres utilisateurs'),
            value: _shareProgress,
            onChanged: (bool value) {
              setState(() {
                _shareProgress = value;
              });
              _showSettingUpdatedMessage();
            },
            activeColor: AppColors.primaryButton,
          ),
          SwitchListTile(
            title: const Text('Collecte de données d\'utilisation'),
            subtitle: const Text('Autoriser l\'application à collecter des données anonymes pour améliorer l\'expérience'),
            value: _allowDataCollection,
            onChanged: (bool value) {
              setState(() {
                _allowDataCollection = value;
              });
              _showSettingUpdatedMessage();
            },
            activeColor: AppColors.primaryButton,
          ),
          const Divider(),
          ListTile(
            title: const Text('Politique de confidentialité'),
            leading: const Icon(Icons.privacy_tip, color: AppColors.primaryButton),
            onTap: () {
              _showPrivacyPolicy();
            },
          ),
          ListTile(
            title: const Text('Conditions d\'utilisation'),
            leading: const Icon(Icons.description, color: AppColors.primaryButton),
            onTap: () {
              _showTermsOfService();
            },
          ),
          ListTile(
            title: const Text('Supprimer mon compte'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showSettingUpdatedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètre mis à jour'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Politique de confidentialité'),
          content: SingleChildScrollView(
            child: const Text(
              'Notre politique de confidentialité explique comment nous collectons, utilisons et partageons vos données personnelles.\n\n'
              'Nous nous engageons à protéger votre vie privée et à traiter vos données avec soin. Nous collectons uniquement les informations nécessaires pour vous fournir nos services et améliorer votre expérience d\'apprentissage.\n\n'
              'Cette politique sera régulièrement mise à jour.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: TextStyle(color: AppColors.primaryButton),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conditions d\'utilisation'),
          content: SingleChildScrollView(
            child: const Text(
              'En utilisant notre application, vous acceptez de respecter nos conditions d\'utilisation.\n\n'
              'Notre application est destinée à l\'apprentissage des langues. Toute utilisation abusive ou inappropriée pourra entraîner la suspension de votre compte.\n\n'
              'Nous nous réservons le droit de modifier ces conditions à tout moment.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: TextStyle(color: AppColors.primaryButton),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    TextEditingController passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pour confirmer, veuillez entrer votre mot de passe :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Mot de passe',
                      ),
                    ),
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                if (isLoading)
                  const CircularProgressIndicator(color: Colors.red)
                else
                  TextButton(
                    onPressed: () async {
                      if (passwordController.text.isEmpty) {
                        setState(() {
                          errorMessage = 'Veuillez entrer votre mot de passe';
                        });
                        return;
                      }
                      
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      
                      final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
                      final result = await authProvider.deleteAccount(
                        password: passwordController.text,
                      );
                      
                      if (result['success']) {
                        Navigator.of(context).pop();
                        // Redirection vers l'écran de login
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setState(() {
                          isLoading = false;
                          errorMessage = result['message'];
                        });
                      }
                    },
                    child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// Écran du centre d'aide
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Comment pouvons-nous vous aider ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher dans l\'aide',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              // TODO: Implémenter la recherche dans l'aide
            },
          ),
          const SizedBox(height: 24),
          _buildHelpSectionTitle('Foire aux questions'),
          _buildFAQItem(
            context,
            'Comment fonctionne le système de niveaux ?',
            'Notre système de niveaux est basé sur votre progression dans les leçons et exercices. Plus vous complétez d\'exercices correctement, plus vous gagnez de points d\'expérience qui vous permettent de monter de niveau.',
          ),
          _buildFAQItem(
            context,
            'Comment réinitialiser mon mot de passe ?',
            'Pour réinitialiser votre mot de passe, allez à l\'écran de connexion et cliquez sur "Mot de passe oublié". Suivez ensuite les instructions envoyées à votre adresse e-mail.',
          ),
          _buildFAQItem(
            context,
            'Comment contacter le support ?',
            'Vous pouvez nous contacter directement via l\'adresse e-mail support@fennlingo.com ou en utilisant le formulaire de contact ci-dessous.',
          ),
          const SizedBox(height: 24),
          _buildHelpSectionTitle('Nous contacter'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formulaire de contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Sujet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message envoyé ! Nous vous répondrons dans les plus brefs délais.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}