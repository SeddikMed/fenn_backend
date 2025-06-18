import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  // Méthode pour s'inscrire
  Future<Map<String, dynamic>> register({
    required String email, 
    required String username, 
    required String password
  }) async {
    try {
      // Créer l'utilisateur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Mettre à jour le nom d'utilisateur
      await result.user?.updateDisplayName(username);
      
      // Enregistrer des données supplémentaires dans Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'username': username,
        'created_at': FieldValue.serverTimestamp(),
        'is_active': true
      });
      
      return {
        'success': true,
        'user': result.user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Méthode pour se connecter
  Future<Map<String, dynamic>> login({
    required String email, 
    required String password
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      return {
        'success': true,
        'user': result.user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Un e-mail de réinitialisation a été envoyé à $email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Méthode pour mettre à jour les données utilisateur
  Future<Map<String, dynamic>> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      // Mettre à jour les données dans Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update(data);
      
      return {
        'success': true,
        'message': 'Données utilisateur mises à jour avec succès',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Méthode pour récupérer l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Méthode pour obtenir un stream des changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Méthode pour récupérer les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
          
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  // Méthode pour mettre à jour le mot de passe
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword, 
    required String newPassword
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }

      // Récupérer l'email de l'utilisateur actuel
      String? email = _auth.currentUser!.email;
      if (email == null) {
        return {
          'success': false,
          'message': 'Email de l\'utilisateur indisponible',
        };
      }

      // Réauthentifier l'utilisateur pour valider l'ancien mot de passe
      AuthCredential credential = EmailAuthProvider.credential(
        email: email, 
        password: currentPassword
      );

      try {
        await _auth.currentUser!.reauthenticateWithCredential(credential);
      } catch (e) {
        return {
          'success': false,
          'message': 'Mot de passe actuel incorrect',
        };
      }

      // Mettre à jour le mot de passe
      await _auth.currentUser!.updatePassword(newPassword);

      return {
        'success': true,
        'message': 'Mot de passe mis à jour avec succès',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du mot de passe: ${e.toString()}',
      };
    }
  }

  // Méthode pour télécharger une image de profil
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      final userId = _auth.currentUser!.uid;
      final storageRef = _storage.ref().child('profile_images').child('$userId.jpg');
      
      // Télécharger l'image vers Firebase Storage
      final uploadTask = storageRef.putFile(imageFile);
      final taskSnapshot = await uploadTask;
      
      // Obtenir l'URL de téléchargement
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      // Mettre à jour le profil utilisateur avec l'URL de l'image
      await _firestore.collection('users').doc(userId).update({
        'photoURL': downloadUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Mettre également à jour l'URL de la photo dans Firebase Auth
      await _auth.currentUser!.updatePhotoURL(downloadUrl);
      
      return {
        'success': true,
        'message': 'Photo de profil mise à jour avec succès',
        'url': downloadUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors du téléchargement de l\'image: ${e.toString()}',
      };
    }
  }

  // Méthode pour récupérer l'URL de la photo de profil
  Future<String?> getProfileImageUrl() async {
    try {
      if (_auth.currentUser == null) return null;
      
      // Essayer d'obtenir l'URL depuis Firebase Auth
      String? photoURL = _auth.currentUser!.photoURL;
      
      // Si aucune URL n'est trouvée, essayer de l'obtenir depuis Firestore
      if (photoURL == null || photoURL.isEmpty) {
        final userData = await getUserData();
        photoURL = userData?['photoURL'] as String?;
      }
      
      return photoURL;
    } catch (e) {
      print('Erreur lors de la récupération de la photo de profil: $e');
      return null;
    }
  }
} 