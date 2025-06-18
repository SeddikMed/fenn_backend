import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  // Vérifier l'état d'authentification au démarrage
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _authService.isAuthenticated();
    
    if (_isAuthenticated) {
      // Charger les données de l'utilisateur
      await getUserData();
    }

    _isLoading = false;
    notifyListeners();
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

    final result = await _authService.register(
      email: email,
      username: username,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      // Après inscription réussie, connectez l'utilisateur
      return await login(email: email, password: password);
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

    final result = await _authService.login(email: email, password: password);

    if (result['success']) {
      _isAuthenticated = true;
      await getUserData();
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return result['success'];
  }

  // Se déconnecter
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _isAuthenticated = false;
    _userData = null;

    _isLoading = false;
    notifyListeners();
  }

  // Récupérer les données de l'utilisateur
  Future<void> getUserData() async {
    if (!_isAuthenticated) return;

    final result = await _authService.getUserProfile();
    if (result['success']) {
      _userData = result['data'];
    } else {
      // Si nous ne pouvons pas obtenir les données de l'utilisateur, déconnectez-le
      _isAuthenticated = false;
      _errorMessage = result['message'];
    }
    notifyListeners();
  }

  // Effacer les messages d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 