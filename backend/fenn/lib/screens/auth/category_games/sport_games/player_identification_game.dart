import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:math';

class PlayerIdentificationGame extends StatefulWidget {
  const PlayerIdentificationGame({super.key});

  @override
  State<PlayerIdentificationGame> createState() => _PlayerIdentificationGameState();
}

class _PlayerIdentificationGameState extends State<PlayerIdentificationGame> {
  // Données des athlètes (images locales à ajouter dans assets/images/athletes/)
  final List<Map<String, dynamic>> _athletes = [
    {
      'name': 'Riyad Mahrez',
      'position': 'Football - Right Winger',
      'achievement': 'Captain of Algeria national team',
      'imageAsset': 'assets/images/athletes/mahrez.jpg',
      'options': ['Riyad Mahrez', 'Islam Slimani', 'Yacine Brahimi', 'Sofiane Feghouli'],
    },
    {
      'name': 'Hassiba Boulmerka',
      'position': 'Athletics - Middle-distance runner',
      'achievement': 'Olympic Gold Medalist (1992)',
      'imageAsset': 'assets/images/athletes/boulmerka.jpg',
      'options': ['Hassiba Boulmerka', 'Nouria Mérah-Benida', 'Fatima Yvelain', 'Imane Khelif'],
    },
    {
      'name': 'Noureddine Morceli',
      'position': 'Athletics - 1500m runner',
      'achievement': 'Olympic Gold Medalist (1996)',
      'imageAsset': 'assets/images/athletes/morceli.jpg',
      'options': ['Noureddine Morceli', 'Taoufik Makhloufi', 'Amir Sayoud', 'Makhloufi Halim'],
    },
    {
      'name': 'Hocine Soltani',
      'position': 'Boxing - Lightweight',
      'achievement': 'Olympic Gold Medalist (1996)',
      'imageAsset': 'assets/images/athletes/soltani.jpg',
      'options': ['Hocine Soltani', 'Mohamed Allalou', 'Imane Khelif', 'Mustapha Moussa'],
    },
    {
      'name': 'Djamel Belmadi',
      'position': 'Football - Coach',
      'achievement': 'Africa Cup of Nations winner (2019)',
      'imageAsset': 'assets/images/athletes/belmadi.jpg',
      'options': ['Djamel Belmadi', 'Rabah Madjer', 'Vahid Halilhodžić', 'Christian Gourcuff'],
    },
    {
      'name': 'Taoufik Makhloufi',
      'position': 'Athletics - Middle-distance runner',
      'achievement': 'Olympic Gold Medalist (2012)',
      'imageAsset': 'assets/images/athletes/makhloufi.jpg',
      'options': ['Taoufik Makhloufi', 'Noureddine Morceli', 'Ali Saidi-Sief', 'Ismaïl Sghyr'],
    },
  ];
  
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedOption;
  bool _showCongrats = false;
  
  @override
  void initState() {
    super.initState();
    // Mélanger les questions
    _athletes.shuffle();
  }
  
  void _checkAnswer(String option) {
    if (_answered) return;
    
    setState(() {
      _answered = true;
      _selectedOption = option;
      
      if (option == _athletes[_currentIndex]['name']) {
        _score++;
      }
    });
    
    // Passer à la question suivante après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentIndex < _athletes.length - 1) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedOption = null;
        });
      } else {
        // Fin du jeu
        setState(() {
          _showCongrats = true;
        });
      }
    });
  }
  
  void _restartGame() {
    setState(() {
      _athletes.shuffle();
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedOption = null;
      _showCongrats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Identification des Athlètes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _showCongrats ? _buildCongratsScreen() : _buildGameScreen(),
    );
  }
  
  Widget _buildGameScreen() {
    final currentAthlete = _athletes[_currentIndex];
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score et progression
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score/${_athletes.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Question ${_currentIndex + 1}/${_athletes.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Image de l'athlète (utilisant une image de remplacement si l'asset n'est pas disponible)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  currentAthlete['imageAsset'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Image de remplacement en cas d'erreur
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports, 
                          size: 50, 
                          color: Colors.grey.shade400
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Image non disponible',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Veuillez ajouter les images dans le dossier assets',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Question
            const Text(
              'Who is this athlete?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${currentAthlete['position']} | ${currentAthlete['achievement']}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            
            // Options
            ...List.generate(
              currentAthlete['options'].length, 
              (index) => _buildOptionButton(currentAthlete['options'][index]),
            ),
            
            // Indicateur de défilement
            const SizedBox(height: 20),
            if (!_answered) _buildScrollIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionButton(String option) {
    bool isCorrect = option == _athletes[_currentIndex]['name'];
    bool isSelected = option == _selectedOption;
    
    // Déterminer la couleur du bouton
    Color buttonColor = Colors.white;
    if (_answered) {
      if (isCorrect) {
        buttonColor = Colors.green.shade100;
      } else if (isSelected) {
        buttonColor = Colors.red.shade100;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _checkAnswer(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size.fromHeight(55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(
            color: _answered && (isCorrect || isSelected)
                ? isCorrect ? Colors.green : Colors.red
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _answered && (isCorrect || isSelected)
                      ? isCorrect ? Colors.green.shade800 : Colors.red.shade800
                      : Colors.black87,
                ),
              ),
            ),
            if (_answered && isCorrect)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (_answered && isSelected)
              const Icon(Icons.cancel, color: Colors.red)
            else
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
  
  // Indicateur de défilement
  Widget _buildScrollIndicator() {
    return Column(
      children: [
        Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey.withOpacity(0.6),
          size: 30,
        ),
        Text(
          'Faites défiler pour voir toutes les options',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCongratsScreen() {
    final percentage = (_score / _athletes.length) * 100;
    String message;
    Color messageColor;
    
    if (percentage >= 80) {
      message = 'Excellent! You really know Algerian sports!';
      messageColor = Colors.green;
    } else if (percentage >= 60) {
      message = 'Good job! You have solid knowledge of Algerian athletes.';
      messageColor = Colors.blue;
    } else {
      message = 'Keep learning about Algerian sports stars!';
      messageColor = Colors.orange;
    }
    
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Game Completed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Score: $_score/${_athletes.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryButton,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: messageColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _restartGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Return to Sport Games',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 