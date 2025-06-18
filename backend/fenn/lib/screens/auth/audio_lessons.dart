import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AudioLessonsScreen extends StatelessWidget {
  const AudioLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Audio Lessons'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Vous pourrez ajouter vos fichiers audio ici
            _buildAudioItem('Lesson 1', 'Description du fichier audio 1'),
            _buildAudioItem('Lesson 2', 'Description du fichier audio 2'),
            // Ajoutez autant d'items que nécessaire
          ],
        ),
      ),
    );
  }

  Widget _buildAudioItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF8D99AE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.audiotrack, color: const Color(0xFFFF8B1F), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_circle_fill, color: const Color(0xFFFF8B1F)),
            onPressed: () {
              // Ajoutez la logique de lecture ici
            },
          ),
        ],
      ),
    );
  }
}