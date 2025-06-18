import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../services/api_service.dart';
import '../models/user_progress.dart';

class FirebaseAuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  firebase.User? _user;
  Map<String, dynamic>? _userData;
  UserProgress _userProgress = UserProgress();

  // Getters
  bool get isAuthenticated => _userData != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  firebase.User? get user => _user; // Maintenu pour la compatibilité
  Map<String, dynamic>? get userData => _userData;
  UserProgress get userProgress => _userProgress;

  // Constructeur pour initialiser le service API
  FirebaseAuthProvider() {
    _initApiService();
  }

  // Initialiser le service API et vérifier l'état d'authentification
  Future<void> _initApiService() async {
    await _apiService.init();
    await checkAuthStatus();
  }

  // Vérifier l'état d'authentification au démarrage
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print("FirebaseAuthProvider: Vérification de l'état d'authentification");
      
      // Forcer le rechargement complet des données utilisateur
      _userData = await _apiService.getUserData();
      print("FirebaseAuthProvider: Données utilisateur récupérées: $_userData");
      
      // Si l'utilisateur est authentifié, récupérer sa progression
      if (_userData != null) {
        print("FirebaseAuthProvider: Utilisateur authentifié, récupération de la progression");
        await fetchUserProgress();
        
        // Enregistrer localement l'URL de la photo
        String? photoUrl = _userData!['photo_url'];
        print("FirebaseAuthProvider: URL de la photo récupérée: $photoUrl");
        
        // Vérifier et convertir l'URL si nécessaire
        if (photoUrl != null && photoUrl.startsWith('/uploads/')) {
          photoUrl = "${_apiService.baseUrl}$photoUrl";
          _userData!['photo_url'] = photoUrl;
          print("FirebaseAuthProvider: URL de la photo convertie en absolue: $photoUrl");
        }
      } else {
        print("FirebaseAuthProvider: Utilisateur non authentifié");
      }
    } catch (e) {
      print("FirebaseAuthProvider: Erreur lors de la vérification d'authentification: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupérer les données de progression de l'utilisateur
  Future<void> fetchUserProgress() async {
    try {
      final result = await _apiService.getUserProgress();
      if (result['success'] && result['data'] != null) {
        _userProgress = UserProgress.fromJson(result['data']);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la récupération de la progression: $e');
    }
  }

  // S'inscrire
  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.register(
      email: email,
      username: username,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      await checkAuthStatus(); // Récupérer les données utilisateur après l'inscription
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Se connecter
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print('FirebaseAuthProvider: Tentative de connexion');
    final result = await _apiService.login(email: email, password: password);
    print('FirebaseAuthProvider: Résultat de connexion: $result');

    _isLoading = false;

    if (result['success']) {
      print('FirebaseAuthProvider: Connexion réussie');
      // Initialiser avec un Map vide si aucune donnée utilisateur n'est renvoyée
      if (result.containsKey('user') && result['user'] != null) {
        // Conversion explicite de Map<dynamic, dynamic> en Map<String, dynamic>
        Map<dynamic, dynamic> originalMap = result['user'];
        _userData = {};
        // Copier chaque entrée en convertissant les clés en String
        originalMap.forEach((key, value) {
          _userData![key.toString()] = value;
        });
      } else {
        // Initialiser avec un Map vide et tenter de récupérer les données utilisateur
        _userData = <String, dynamic>{};
        checkAuthStatus(); // Récupérer les données utilisateur après connexion
      }
      print('FirebaseAuthProvider: Données utilisateur: $_userData');
      notifyListeners();
      return true;
    } else {
      // Message d'erreur personnalisé
      _errorMessage = result['message'] ?? 'Utilisateur introuvable. Vérifiez votre email ou mot de passe.';
      print('FirebaseAuthProvider: Erreur de connexion: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // Réinitialiser le mot de passe
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.resetPassword(email: email);

    _isLoading = false;
    
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    
    notifyListeners();
    return result;
  }

  // Se déconnecter
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.logout();
    _userData = null;
    _user = null;

    _isLoading = false;
    notifyListeners();
  }

  // Mettre à jour les données utilisateur
  Future<Map<String, dynamic>> updateUserData({
    String? username,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Préparer les données à mettre à jour
      Map<String, dynamic> dataToUpdate = {};
      
      // Ajouter le username si fourni
      if (username != null && username.isNotEmpty) {
        dataToUpdate['username'] = username;
      }
      
      // Ajouter les données additionnelles si fournies
      if (additionalData != null && additionalData.isNotEmpty) {
        dataToUpdate.addAll(additionalData);
      }

      // Mettre à jour les données via l'API
      final result = await _apiService.updateUserData(dataToUpdate);
      
      if (result['success']) {
        // Rafraîchir les données utilisateur
        await checkAuthStatus();
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour: ${e.toString()}',
      };
    }
  }

  // Mettre à jour le mot de passe
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _isLoading = false;
      
      if (!result['success']) {
        _errorMessage = result['message'];
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Télécharger une nouvelle photo de profil
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.uploadImage(imageFile);
      
      _isLoading = false;
      
      if (!result['success']) {
        _errorMessage = result['message'];
      } else {
        // Mettre à jour les données utilisateur avec la nouvelle URL de la photo
        if (result['url'] != null) {
          await updateUserData(additionalData: {'photo_url': result['url']});
        }
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Obtenir l'URL de la photo de profil
  Future<String?> getProfileImageUrl() async {
    if (_userData != null && _userData!.containsKey('photo_url')) {
      return _userData!['photo_url'] as String?;
    }
    
    // Ne pas tenter de récupérer les données actualisées ici pour éviter les setState pendant build
    return null;
  }

  // Supprimer le compte utilisateur
  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Appel à l'API pour supprimer le compte
      final result = await _apiService.deleteAccount(password: password);
      
      // Si la suppression réussit, déconnecter l'utilisateur
      if (result['success']) {
        await logout();
      } else {
        _errorMessage = result['message'];
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Erreur lors de la suppression du compte: ${e.toString()}',
      };
    }
  }

  // Effacer les messages d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Méthode pour extraire le code d'erreur
  String _extractErrorCode(String errorMessage) {
    return errorMessage;
  }
} 