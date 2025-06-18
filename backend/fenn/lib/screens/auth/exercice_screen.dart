import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VocabularyExerciseScreen extends StatelessWidget {
  final String category;
  final Color primaryColor;
  final Color secondaryColor;

  const VocabularyExerciseScreen({
    super.key,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apprendre',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choisir la bonne carte',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),

            // Grille de cartes de vocabulaire
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _buildVocabularyCard('forêt', primaryColor, secondaryColor),
                  _buildVocabularyCard('forest', primaryColor, secondaryColor),
                  _buildVocabularyCard('shop', primaryColor, secondaryColor),
                  _buildVocabularyCard('house', primaryColor, secondaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyCard(String word, Color bgColor, Color borderColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      color: bgColor,
      child: Center(
        child: Text(
          word,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}