import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Clé pour stocker le token dans SharedPreferences
  static const String _tokenKey = 'auth_token';

  // Méthode pour s'inscrire
  Future<Map<String, dynamic>> register({
    required String email, 
    required String username, 
    required String password
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // Méthode pour se connecter
  Future<Map<String, dynamic>> login({
    required String email, 
    required String password
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email, // L'API utilise username mais nous passons l'email
          'password': password,
        },
      );

      final result = _handleResponse(response);
      if (result['success'] && result['data']['access_token'] != null) {
        // Sauvegarder le token dans SharedPreferences
        await _saveToken(result['data']['access_token']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // Méthode pour récupérer le profil utilisateur
  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Méthode pour vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Méthode pour récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Méthode privée pour sauvegarder le token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Méthode privée pour gérer les réponses HTTP
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {
      return {
        'success': false,
        'message': 'Erreur ${response.statusCode}: ${response.body}',
        'statusCode': response.statusCode,
      };
    }
  }
} 