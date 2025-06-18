import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class ApiService {
  // URL de base de l'API - Nous n'utilisons plus cette valeur hardcodée
  // Nous utilisons ApiConstants.baseUrl à la place pour chaque requête
  
  // Headers HTTP par défaut
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Token de l'utilisateur connecté
  String? _authToken;
  
  // Getter pour l'URL de base
  String get baseUrl => ApiConstants.baseUrl;
  
  // Initialiser le service API
  Future<void> init() async {
    await _loadToken();
  }
  
  // Charger le token depuis le stockage local
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    if (_authToken != null) {
      _headers['Authorization'] = 'Bearer $_authToken';
    }
  }
  
  // Sauvegarder le token dans le stockage local
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _authToken = token;
    _headers['Authorization'] = 'Bearer $token';
  }
  
  // Supprimer le token du stockage local
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _authToken = null;
    _headers.remove('Authorization');
  }
  
  // Méthode pour s'inscrire
  Future<Map<String, dynamic>> register({
    required String email, 
    required String username, 
    required String password
  }) async {
    try {
      // Recalculer l'URL à chaque fois pour éviter les problèmes de cache
      final String url = ApiConstants.baseUrl + ApiConstants.register;
      print('Tentative d\'inscription avec email: $email, username: $username');
      print('URL d\'inscription: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password
        })
      ).timeout(const Duration(seconds: 10)); // Ajouter un timeout
      
      print('Réponse status: ${response.statusCode}');
      print('Réponse body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        print('Inscription réussie');
        return {
          'success': true,
          'message': data['message'] ?? 'Utilisateur créé avec succès',
          'user': data
        };
      } else {
        print('Erreur d\'inscription: ${data['detail'] ?? 'Erreur inconnue'}');
        return {
          'success': false,
          'message': data['detail'] ?? 'Erreur lors de l\'inscription'
        };
      }
    } catch (e) {
      print('Exception lors de l\'inscription: $e');
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}'
      };
    }
  }
  
  // Méthode pour se connecter
  Future<Map<String, dynamic>> login({
    required String email, 
    required String password
  }) async {
    try {
      // Recalculer l'URL à chaque fois pour éviter les problèmes de cache
      final String url = ApiConstants.baseUrl + ApiConstants.login;
      print('Tentative de connexion à l\'URL: $url');
      print('Headers: $_headers');
      print('Body: ${jsonEncode({
          'email': email,
          'password': password
        })}');
        
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password
        })
      ).timeout(const Duration(seconds: 10)); // Ajouter un timeout
      
      print('Réponse status: ${response.statusCode}');
      print('Réponse body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Données décodées: $data');
        
        // Vérifier si access_token existe
        if (data.containsKey('access_token')) {
          // Sauvegarder le token
          await _saveToken(data['access_token']);
          
          return {
            'success': true,
            'user': data['user'] ?? {},
            'message': data['message'] ?? 'Connexion réussie'
          };
        } else {
          print('Erreur: Clé access_token non trouvée dans la réponse');
          return {
            'success': false,
            'message': 'Erreur dans la structure de réponse'
          };
        }
      } else {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          print('Erreur décodage JSON: $e');
        }
        
        return {
          'success': false,
          'message': data['detail'] ?? 'Erreur lors de la connexion: Code ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Erreur de connexion: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}'
      };
    }
  }
  
  // Méthode pour réinitialiser le mot de passe
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        })
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Erreur lors de la réinitialisation du mot de passe'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }
  
  // Méthode pour mettre à jour les données utilisateur
  Future<Map<String, dynamic>> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      final response = await http.put(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.profile),
        headers: _headers,
        body: jsonEncode(data)
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message']
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Erreur lors de la mise à jour des données'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }
  
  // Méthode pour mettre à jour le mot de passe
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      final response = await http.put(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.updatePassword),
        headers: _headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword
        })
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Erreur lors de la mise à jour du mot de passe'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }
  
  // Méthode pour télécharger une image
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      if (_authToken == null) {
        print('ApiService: Token manquant pour l\'upload d\'image');
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      print('ApiService: Début d\'upload de l\'image ${imageFile.path}');
      
      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        print('ApiService: Le fichier n\'existe pas: ${imageFile.path}');
        return {
          'success': false,
          'message': 'Fichier image introuvable',
        };
      }
      
      final fileSize = await imageFile.length();
      print('ApiService: Taille du fichier: ${fileSize} octets');
      
      // Création d'une requête multipart pour l'upload de fichier
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.uploadImage);
      print('ApiService: URL d\'upload: $uri');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Ajout du token d'authentification
      request.headers.addAll({
        'Authorization': 'Bearer $_authToken',
        'Accept': 'application/json',
      });
      
      // Ajout du fichier image
      final filename = imageFile.path.split('/').last;
      final multipartFile = await http.MultipartFile.fromPath(
        'file', // Nom du champ attendu par le serveur
        imageFile.path,
        filename: filename,
      );
      
      request.files.add(multipartFile);
      print('ApiService: Fichier ajouté à la requête: $filename');
      
      // Envoi de la requête
      print('ApiService: Envoi de la requête...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('ApiService: Réponse reçue, status: ${response.statusCode}');
      print('ApiService: Corps de la réponse: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Convertir l'URL relative en URL absolue
        String url = data['url'] ?? '';
        if (url.startsWith('/uploads/')) {
          url = ApiConstants.baseUrl + url;
        }
        
        print('ApiService: Upload réussi, URL absolue: $url');
        return {
          'success': true,
          'message': data['message'] ?? 'Image téléchargée avec succès',
          'url': url  // URL absolue
        };
      } else {
        String errorMessage;
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['detail'] ?? 'Erreur lors du téléchargement de l\'image';
        } catch (e) {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
        }
        print('ApiService: Échec de l\'upload: $errorMessage');
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      print('ApiService: Exception lors de l\'upload: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}'
      };
    }
  }
  
  // Méthode pour récupérer le profil utilisateur
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_authToken == null) {
        print('ApiService: Token manquant pour getUserData');
        return null;
      }
      
      print('ApiService: Récupération des données utilisateur');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.me),
        headers: _headers
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ApiService: Données utilisateur reçues: $data');
        
        // Convertir les URLs relatives en URLs absolues
        if (data.containsKey('photo_url') && data['photo_url'] != null) {
          String photoUrl = data['photo_url'];
          if (photoUrl.startsWith('/uploads/')) {
            data['photo_url'] = ApiConstants.baseUrl + photoUrl;
            print('ApiService: URL photo convertie en absolue: ${data['photo_url']}');
          }
        }
        
        return data;
      } else {
        print('ApiService: Erreur lors de la récupération des données: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ApiService: Erreur lors de la récupération des données: $e');
      return null;
    }
  }
  
  // Méthode pour supprimer un compte utilisateur
  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      final response = await http.delete(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.deleteAccount),
        headers: _headers,
        body: jsonEncode({
          'password': password
        })
      );
      
      // Gérer la réponse en fonction du code de statut
      if (response.statusCode == 200) {
        await _removeToken(); // Supprimer le token après suppression du compte
        return {
          'success': true,
          'message': 'Compte supprimé avec succès'
        };
      } else {
        // Tenter de décoder la réponse
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['detail'] ?? 'Erreur lors de la suppression du compte'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erreur lors de la suppression du compte'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }
  
  // Méthode pour se déconnecter
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await http.post(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.logout),
          headers: _headers
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    } finally {
      // Supprimer le token même en cas d'erreur
      await _removeToken();
    }
  }
  
  // Méthode pour récupérer les données de progression de l'utilisateur
  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
          'data': null
        };
      }
      
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.userProgress),
        headers: _headers
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data
        };
      } else {
        // Si le serveur n'a pas encore implémenté cette fonctionnalité,
        // on renvoie des données factices pour le moment
        return {
          'success': true,
          'data': {
            'completed_lessons': 3,
            'total_lessons': 20,
            'current_streak': 2,
            'progress_percentage': 15.0,
          }
        };
      }
    } catch (e) {
      print('Erreur lors de la récupération des données de progression: $e');
      
      // Renvoyer des données factices en cas d'erreur
      return {
        'success': true,
        'data': {
          'completed_lessons': 3,
          'total_lessons': 20,
          'current_streak': 2,
          'progress_percentage': 15.0,
        }
      };
    }
  }
} 