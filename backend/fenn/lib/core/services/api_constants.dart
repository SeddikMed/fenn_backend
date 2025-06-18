import 'dart:io';

class ApiConstants {
  // Forcer l'utilisation d'une adresse IP spécifique
  // Changer cette valeur selon votre environnement
  static const bool USE_FORCED_IP = true;
  static const String FORCED_IP = 'http://192.168.1.25:8000';
  
  // Déterminer l'URL de base en fonction de la plateforme
  static String get baseUrl {
    // Si on force l'utilisation d'une IP spécifique
    if (USE_FORCED_IP) {
      print('ApiConstants: Utilisation de l\'IP forcée: $FORCED_IP');
      return FORCED_IP;
    }
    
    print('ApiConstants: Détection de la plateforme: Android=${Platform.isAndroid}, iOS=${Platform.isIOS}');
    
    // Détection d'émulateur (cette méthode n'est pas fiable à 100%)
    if (Platform.isAndroid) {
      String? brand = Platform.environment['BRAND'];
      String? product = Platform.environment['PRODUCT'];
      bool isEmulator = brand == 'google' || brand == 'Android' || 
                        product?.contains('sdk') == true || 
                        product?.contains('emulator') == true;
                        
      print('ApiConstants: Émulateur Android détecté: $isEmulator');
      
      if (isEmulator) {
        return 'http://10.0.2.2:8000';
      }
    } else if (Platform.isIOS) {
      bool isEmulator = !isPhysicalDevice();
      print('ApiConstants: Émulateur iOS détecté: $isEmulator');
      
      if (isEmulator) {
        return 'http://localhost:8000';
      }
    }
    
    // Par défaut pour les appareils physiques
    return 'http://192.168.1.25:8000';
  }
  
  // Fonction pour déterminer si nous sommes sur un appareil physique
  static bool isPhysicalDevice() {
    try {
      // Cette méthode n'est pas fiable à 100%
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
  
  // Points de terminaison
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/users/me';
  static const String resetPassword = '/auth/reset-password';
  static const String updatePassword = '/auth/password';
  static const String profile = '/users/profile';
  static const String uploadImage = '/users/upload-image';
  static const String userProgress = '/users/progress';
  static const String deleteAccount = '/users/account';
  static const String logout = '/auth/logout';
} 