import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

class ChatService {
  final AuthService _authService = AuthService();
  
  // Envoyer un message au chatbot et obtenir une réponse
  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      debugPrint('ChatService: Tentative d\'obtention du token pour envoyer un message');
      final token = await _authService.getIdToken();
      
      if (token == null) {
        debugPrint('ChatService: Impossible d\'obtenir un token d\'authentification');
        throw Exception('Non authentifié');
      }
      
      final baseUrl = ApiConstants.baseUrl;
      final endpoint = '/chat/send';
      final fullUrl = '$baseUrl$endpoint';
      
      debugPrint('ChatService: Token obtenu, longueur: ${token.length}');
      debugPrint('ChatService: Envoi du message au endpoint: $fullUrl');
      
      // Utilisation de l'URL avec /send car l'autre est configuré comme redirection
      final client = http.Client();
      final response = await client.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_input': message,
          'user_id': await _authService.getCurrentUserId() ?? "default",
        }),
      );
      
      client.close();
      
      debugPrint('ChatService: Réponse reçue, status: ${response.statusCode}');
      if (response.statusCode >= 500) {
        debugPrint('ChatService: Erreur serveur: ${response.body}');
        return {
          'success': false,
          'response': 'Le serveur a rencontré un problème. Veuillez réessayer plus tard.'
        };
      }
      
      if (response.statusCode == 404) {
        // Le endpoint n'existe pas, essayons l'ancien endpoint sans "/send"
        debugPrint('ChatService: Endpoint non trouvé, essai avec /chat');
        final fallbackResponse = await http.post(
          Uri.parse('$baseUrl/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'user_input': message,
            'user_id': await _authService.getCurrentUserId() ?? "default",
          }),
        );
        
        if (fallbackResponse.statusCode == 200) {
          final data = jsonDecode(fallbackResponse.body);
          debugPrint('ChatService: Message envoyé avec succès via fallback');
          return data;
        } else {
          debugPrint('ChatService: Échec du fallback: ${fallbackResponse.statusCode}');
        }
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('ChatService: Message envoyé avec succès');
        debugPrint('ChatService: Contenu JSON reçu du backend: ' + response.body);
        
        // Traitement spécial pour les données de quiz
        var responseData = Map<String, dynamic>.from(data);
        
        // Si c'est un quiz, extraire les données de quiz
        if (data.containsKey('quiz_data')) {
          debugPrint('ChatService: Données de quiz détectées');
          responseData['quiz_data'] = data['quiz_data'];
        }
        
        // Si c'est une réponse à un quiz
        if (data.containsKey('quiz_response') && data['quiz_response'] == true) {
          debugPrint('ChatService: Réponse à un quiz détectée');
          responseData['quiz_response'] = true;
        }
        
        return responseData;
      } else if (response.statusCode == 401) {
        debugPrint('ChatService: Erreur d\'authentification, tentative de rafraîchissement du token');
        
        // Token expiré? Essayons de l'effacer et d'en obtenir un nouveau
        await _authService.clearToken();
        final newToken = await _authService.getIdToken();
        
        if (newToken == null) {
          throw Exception('Échec de rafraîchissement du token');
        }
        
        // Réessayer avec le nouveau token
        final retryResponse = await http.post(
          Uri.parse(fullUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode({
            'user_input': message,
            'user_id': await _authService.getCurrentUserId() ?? "default",
          }),
        );
        
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          debugPrint('ChatService: Message envoyé avec succès après rafraîchissement du token');
          
          // Traitement spécial pour les données de quiz
          var responseData = Map<String, dynamic>.from(data);
          
          // Si c'est un quiz, extraire les données de quiz
          if (data.containsKey('quiz_data')) {
            debugPrint('ChatService: Données de quiz détectées après rafraîchissement');
            responseData['quiz_data'] = data['quiz_data'];
          }
          
          // Si c'est une réponse à un quiz
          if (data.containsKey('quiz_response') && data['quiz_response'] == true) {
            debugPrint('ChatService: Réponse à un quiz détectée après rafraîchissement');
            responseData['quiz_response'] = true;
          }
          
          return responseData;
        } else {
          debugPrint('ChatService: Échec après rafraîchissement du token: ${retryResponse.statusCode} - ${retryResponse.body}');
          throw Exception('Échec de l\'envoi du message: ${retryResponse.statusCode}');
        }
      } else {
        debugPrint('ChatService: Réponse API: ${response.statusCode} - ${response.body}');
        
        // Fallback pour le mode hors-ligne ou lorsque l'API n'est pas disponible
        if (response.statusCode >= 500 || response.statusCode == 404) {
          debugPrint('ChatService: Mode hors-ligne ou API indisponible, utilisation de la réponse par défaut');
          return {
            'success': true,
            'response': 'Je suis votre assistant d\'apprentissage d\'anglais. Comment puis-je vous aider aujourd\'hui?'
          };
        }
        
        throw Exception('Échec de l\'envoi du message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Erreur lors de l\'envoi du message: $e');
      return {
        'success': false,
        'response': 'Une erreur est survenue. Veuillez réessayer.'
      };
    }
  }
  
  // Récupérer l'historique des messages
  Future<List<dynamic>> getChatHistory() async {
    try {
      final token = await _authService.getIdToken();
      
      if (token == null) {
        debugPrint('ChatService: Impossible d\'obtenir un token d\'authentification pour l\'historique');
        throw Exception('Non authentifié');
      }
      
      debugPrint('ChatService: Récupération de l\'historique des messages');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Traiter les messages pour inclure les données de quiz
        List<dynamic> messages = data['messages'] ?? [];
        for (var i = 0; i < messages.length; i++) {
          // Conserver les données de quiz dans les messages
          if (messages[i].containsKey('quiz_data')) {
            debugPrint('ChatService: Données de quiz trouvées dans l\'historique');
          }
        }
        
        return messages;
      } else if (response.statusCode == 401) {
        debugPrint('ChatService: Token expiré lors de la récupération de l\'historique, rafraîchissement');
        
        // Token expiré, rafraîchir
        await _authService.clearToken();
        final newToken = await _authService.getIdToken();
        
        if (newToken == null) {
          throw Exception('Échec du rafraîchissement du token');
        }
        
        // Réessayer
        final retryResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/chat/history'),
          headers: {
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          return data['messages'] ?? [];
        } else {
          debugPrint('ChatService: Échec après rafraîchissement: ${retryResponse.statusCode}');
          throw Exception('Échec de la récupération de l\'historique: ${retryResponse.statusCode}');
        }
      } else {
        debugPrint('ChatService: Réponse API pour historique: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de la récupération de l\'historique: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }
  
  // Effacer l'historique des messages
  Future<bool> clearChatHistory() async {
    try {
      final token = await _authService.getIdToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }
      
      debugPrint('ChatService: Effacement de l\'historique des messages');
      
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/chat/clear-history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token expiré, rafraîchir
        await _authService.clearToken();
        final newToken = await _authService.getIdToken();
        
        if (newToken == null) {
          throw Exception('Échec du rafraîchissement du token');
        }
        
        // Réessayer
        final retryResponse = await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/chat/clear-history'),
          headers: {
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          return true;
        } else {
          debugPrint('ChatService: Échec après rafraîchissement: ${retryResponse.statusCode}');
          throw Exception('Échec de la suppression de l\'historique: ${retryResponse.statusCode}');
        }
      } else {
        debugPrint('ChatService: Réponse API pour suppression: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de la suppression de l\'historique: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Erreur lors de la suppression de l\'historique: $e');
      return false;
    }
  }
  
  // Envoyer un feedback sur une réponse
  Future<bool> sendFeedback(String messageId, String feedbackType, {String? feedbackContent}) async {
    try {
      final token = await _authService.getIdToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/chat/feedback'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['message_id'] = messageId;
      request.fields['feedback_type'] = feedbackType;
      
      if (feedbackContent != null) {
        request.fields['feedback_content'] = feedbackContent;
      }
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token expiré, rafraîchir et réessayer
        await _authService.clearToken();
        final newToken = await _authService.getIdToken();
        
        if (newToken == null) {
          throw Exception('Échec du rafraîchissement du token');
        }
        
        // Préparer une nouvelle requête
        final retryRequest = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConstants.baseUrl}/chat/feedback'),
        );
        
        retryRequest.headers['Authorization'] = 'Bearer $newToken';
        retryRequest.fields['message_id'] = messageId;
        retryRequest.fields['feedback_type'] = feedbackType;
        
        if (feedbackContent != null) {
          retryRequest.fields['feedback_content'] = feedbackContent;
        }
        
        final retryResponse = await retryRequest.send();
        
        if (retryResponse.statusCode == 200) {
          return true;
        } else {
          final responseText = await retryResponse.stream.bytesToString();
          debugPrint('ChatService: Échec après rafraîchissement: ${retryResponse.statusCode} - $responseText');
          throw Exception('Échec de l\'envoi du feedback: ${retryResponse.statusCode}');
        }
      } else {
        final responseText = await response.stream.bytesToString();
        debugPrint('ChatService: Réponse API pour feedback: ${response.statusCode} - $responseText');
        throw Exception('Échec de l\'envoi du feedback: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Erreur lors de l\'envoi du feedback: $e');
      return false;
    }
  }
  
  // Récupérer la progression de l'utilisateur
  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final token = await _authService.getIdToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/progress'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expiré, rafraîchir
        await _authService.clearToken();
        final newToken = await _authService.getIdToken();
        
        if (newToken == null) {
          throw Exception('Échec du rafraîchissement du token');
        }
        
        // Réessayer
        final retryResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/chat/progress'),
          headers: {
            'Authorization': 'Bearer $newToken',
          },
        );
        
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          debugPrint('ChatService: Échec après rafraîchissement: ${retryResponse.statusCode}');
          throw Exception('Échec de la récupération de la progression: ${retryResponse.statusCode}');
        }
      } else {
        debugPrint('ChatService: Réponse API pour progression: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de la récupération de la progression: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Erreur lors de la récupération de la progression: $e');
      return {
        'total_score': 0,
        'quizzes': {}
      };
    }
  }
  
  // Mettre à jour la progression de l'utilisateur
  Future<bool> updateProgress(String topic, int score) async {
    try {
      final token = await _authService.getIdToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'topic': topic,
          'score': score,
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token expiré, rafraîchir
        await _authService.clearToken();
        final newToken = await _authService.getIdToken();
        
        if (newToken == null) {
          throw Exception('Échec du rafraîchissement du token');
        }
        
        // Réessayer
        final retryResponse = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/chat/progress'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode({
            'topic': topic,
            'score': score,
          }),
        );
        
        if (retryResponse.statusCode == 200) {
          return true;
        } else {
          debugPrint('ChatService: Échec après rafraîchissement: ${retryResponse.statusCode}');
          throw Exception('Échec de la mise à jour de la progression: ${retryResponse.statusCode}');
        }
      } else {
        debugPrint('ChatService: Réponse API pour mise à jour: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de la mise à jour de la progression: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Erreur lors de la mise à jour de la progression: $e');
      return false;
    }
  }
} 