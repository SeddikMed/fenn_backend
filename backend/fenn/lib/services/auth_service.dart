import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  // Retourne l'UID de l'utilisateur courant (Firebase)
  Future<String?> getCurrentUserId() async {
    try {
      final user = _auth.currentUser;
      return user?.uid;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'ID utilisateur: $e');
      return null;
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _apiToken; // Stocke le token API en mémoire

  // Clé pour le stockage du token dans les préférences
  static const String _tokenKey = 'api_token';
  static const String _tokenExpiryKey = 'api_token_expiry';

  // État du stream d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Obtenir le token Firebase
  Future<String?> getFirebaseToken() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token Firebase: $e');
      return null;
    }
  }

  // Obtenir le token API pour les appels au backend
  Future<String?> getIdToken() async {
    try {
      // Si nous avons déjà un token en mémoire, vérifier s'il est expiré
      if (_apiToken != null) {
        // Vérifier si le token est expiré en recuperant la date d'expiration des prefs
        final prefs = await SharedPreferences.getInstance();
        final expiryTimeStr = prefs.getString(_tokenExpiryKey);
        if (expiryTimeStr != null) {
          final expiryTime = DateTime.parse(expiryTimeStr);
          // Si le token est encore valide (avec une marge de 5 minutes)
          if (expiryTime.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
            return _apiToken;
          }
        }
      }

      // Le token est expiré ou n'existe pas, obtenir un nouveau token
      final firebaseToken = await getFirebaseToken();
      if (firebaseToken == null) {
        return null;
      }

      // Utiliser le nouvel endpoint verify-token pour obtenir un token API
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        // Stocker le token en mémoire
        _apiToken = token;

        // Stocker le token dans les préférences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        // Calculer et stocker la date d'expiration (7 jours comme configuré sur le serveur)
        final expiry = DateTime.now().add(const Duration(days: 7));
        await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());

        return token;
      } else {
        debugPrint('Erreur d\'authentification API: ${response.statusCode} - ${response.body}');
        // En cas d'échec, effacer le token et les préférences
        await clearToken();
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token API: $e');
      return null;
    }
  }

  // Charger le token API depuis les préférences au démarrage de l'app
  Future<void> loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiToken = prefs.getString(_tokenKey);
      
      // Vérifier si le token est expiré
      final expiryTimeStr = prefs.getString(_tokenExpiryKey);
      if (expiryTimeStr != null) {
        final expiryTime = DateTime.parse(expiryTimeStr);
        // Si le token est expiré, le supprimer
        if (expiryTime.isBefore(DateTime.now())) {
          await clearToken();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du token: $e');
    }
  }

  // Effacer le token API
  Future<void> clearToken() async {
    try {
      _apiToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenExpiryKey);
    } catch (e) {
      debugPrint('Erreur lors de la suppression du token: $e');
    }
  }

  // Connexion avec email et mot de passe
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Effacer le token API précédent
      await clearToken();
      
      // Obtenir immédiatement un nouveau token API
      await getIdToken();
      
      return credential.user;
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      return null;
    }
  }

  // Inscription avec email et mot de passe
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await clearToken(); // Effacer le token API
      await _auth.signOut();
    } catch (e) {
      debugPrint('Erreur de déconnexion: $e');
    }
  }

  // Envoyer un email de réinitialisation du mot de passe
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Erreur d\'envoi d\'email de réinitialisation: $e');
      return false;
    }
  }

  // Vérifier si l'utilisateur est connecté
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // Mettre à jour le mot de passe
  Future<bool> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du mot de passe: $e');
      return false;
    }
  }
} 