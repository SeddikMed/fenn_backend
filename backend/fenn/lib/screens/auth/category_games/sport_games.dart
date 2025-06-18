import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'sport_games/player_identification_game.dart';
import 'sport_games/algerian_sport_quiz.dart';

class SportGamesScreen extends StatelessWidget {
  const SportGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sports Algériens'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bannière d'introduction
                _buildIntroductionBanner(),
                const SizedBox(height: 30),
                
                // Titre de la section
                const Text(
                  'Jeux Éducatifs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Améliorez votre anglais tout en découvrant les sports algériens',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 25),
                
                // Mini-jeux sur le sport algérien
                _buildGameCard(
                  context: context,
                  title: 'Identification des Athlètes',
                  description: 'Retrouvez les noms des stars du sport algérien',
                  icon: Icons.person,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlayerIdentificationGame()),
                    );
                  },
                ),
                const SizedBox(height: 15),
                
                _buildGameCard(
                  context: context,
                  title: 'Quiz sur les Sports Algériens',
                  description: 'Testez vos connaissances sur l\'histoire sportive algérienne',
                  icon: Icons.quiz,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AlgerianSportQuiz()),
                    );
                  },
                ),
                const SizedBox(height: 30),
                
                // Section de vocabulaire
                const Text(
                  'Vocabulaire du Sport',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Liste de vocabulaire
                _buildVocabularyItem('football', 'كرة القدم', 'soccer'),
                _buildVocabularyItem('joueur', 'لاعب', 'player'),
                _buildVocabularyItem('équipe', 'فريق', 'team'),
                _buildVocabularyItem('championnat', 'بطولة', 'championship'),
                _buildVocabularyItem('stade', 'ملعب', 'stadium'),
                _buildVocabularyItem('athlète', 'رياضي', 'athlete'),
                _buildVocabularyItem('boxe', 'ملاكمة', 'boxing'),
                _buildVocabularyItem('course', 'سباق', 'race'),
                _buildVocabularyItem('médaille', 'ميدالية', 'medal'),
                _buildVocabularyItem('judo', 'جودو', 'judo'),
                _buildVocabularyItem('natation', 'سباحة', 'swimming'),
                
                // Espace pour l'indicateur de défilement
                const SizedBox(height: 50),
              ],
            ),
          ),
          
          // Indicateur de défilement fixe en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_vertical,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Faites glisser pour voir plus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bannière d'introduction
  Widget _buildIntroductionBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Les Sports Algériens',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Découvrez l\'histoire riche du sport algérien tout en améliorant votre vocabulaire anglais. Du football à la boxe, en passant par l\'athlétisme et le judo, explorez les accomplissements sportifs de l\'Algérie à travers des jeux éducatifs interactifs.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Carte de jeu
  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Item de vocabulaire
  Widget _buildVocabularyItem(String french, String arabic, String english) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              french,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              arabic,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              english,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 