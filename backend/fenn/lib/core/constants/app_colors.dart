// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primaryButton = Color(0xFFFF8B1F);
  static const Color background = Color(0xFFDAE6B2);

  // Textes
  static const Color textPrimary = Color(0xFF303E5D);
  static const Color textSecondary = Color(0xFF4A5C7A); // AJOUTÉ

  // Champs de formulaire
  static const Color textFieldBackground = Color(0xFF8D99AE);
  static const Color textFieldText = Color(0xFF303E5D);
  static const Color error = Color(0xFFEF0C0C);

  // Méthode pour l'opacité
  static Color get textFieldBackgroundWithOpacity50 => textFieldBackground.withOpacity(0.5);
}