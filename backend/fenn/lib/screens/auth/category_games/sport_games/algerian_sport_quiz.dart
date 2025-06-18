import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AlgerianSportQuiz extends StatefulWidget {
  const AlgerianSportQuiz({super.key});

  @override
  State<AlgerianSportQuiz> createState() => _AlgerianSportQuizState();
}

class _AlgerianSportQuizState extends State<AlgerianSportQuiz> {
  // Liste des questions du quiz
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'When did Algeria win its first Africa Cup of Nations (AFCON)?',
      'options': ['1982', '1990', '2019', '1980'],
      'correctAnswer': '1990',
      'explanation': 'L\'Algérie a remporté sa première Coupe d\'Afrique des Nations en 1990 en battant le Nigéria 1-0 en finale à Alger, avec un but de Chérif Oudjani.',
    },
    {
      'question': 'Which Algerian boxer won a gold medal at the 1996 Olympic Games in Atlanta?',
      'options': ['Hocine Soltani', 'Mohamed Allalou', 'Mustapha Moussa', 'Mohamed Benguesmia'],
      'correctAnswer': 'Hocine Soltani',
      'explanation': 'Hocine Soltani a remporté la médaille d\'or dans la catégorie des poids légers (-60 kg) aux Jeux Olympiques d\'Atlanta en 1996.',
    },
    {
      'question': 'Who was the first Algerian athlete to win an Olympic gold medal?',
      'options': ['Hassiba Boulmerka', 'Noureddine Morceli', 'Taoufik Makhloufi', 'Nouria Mérah-Benida'],
      'correctAnswer': 'Hassiba Boulmerka',
      'explanation': 'Hassiba Boulmerka est devenue la première athlète algérienne à remporter une médaille d\'or olympique en 1992 à Barcelone dans l\'épreuve du 1500m.',
    },
    {
      'question': 'In which year did Algeria qualify for its first FIFA World Cup?',
      'options': ['1982', '1986', '1990', '2010'],
      'correctAnswer': '1982',
      'explanation': 'L\'Algérie s\'est qualifiée pour sa première Coupe du Monde de la FIFA en 1982 en Espagne, où elle a créé la surprise en battant l\'Allemagne de l\'Ouest 2-1.',
    },
    {
      'question': 'Which Algerian judoka won a silver medal at the 2008 Olympic Games in Beijing?',
      'options': ['Amar Benikhlef', 'Soraya Haddad', 'Ali Idir', 'Mohammed Meridja'],
      'correctAnswer': 'Amar Benikhlef',
      'explanation': 'Amar Benikhlef a remporté la médaille d\'argent en judo dans la catégorie des -90 kg aux Jeux Olympiques de Pékin en 2008.',
    },
    {
      'question': 'Who was the coach when Algeria won the 2019 Africa Cup of Nations?',
      'options': ['Rabah Madjer', 'Vahid Halilhodžić', 'Djamel Belmadi', 'Christian Gourcuff'],
      'correctAnswer': 'Djamel Belmadi',
      'explanation': 'Djamel Belmadi était le sélectionneur de l\'équipe d\'Algérie lorsqu\'elle a remporté la Coupe d\'Afrique des Nations 2019 en Égypte, battant le Sénégal 1-0 en finale.',
    },
    {
      'question': 'Which Algerian runner won the 1500m gold medal at the 1996 Olympics?',
      'options': ['Noureddine Morceli', 'Taoufik Makhloufi', 'Hassiba Boulmerka', 'Nouria Mérah-Benida'],
      'correctAnswer': 'Noureddine Morceli',
      'explanation': 'Noureddine Morceli a remporté la médaille d\'or du 1500m aux Jeux Olympiques d\'Atlanta en 1996. Il a également été champion du monde à trois reprises et a battu plusieurs records du monde.',
    },
    {
      'question': 'Which female Algerian boxer qualified for the Olympic Games in 2020 (held in 2021)?',
      'options': ['Imane Khelif', 'Fatima Zahra', 'Soraya Haddad', 'Nawel Hamidi'],
      'correctAnswer': 'Imane Khelif',
      'explanation': 'Imane Khelif s\'est qualifiée pour les Jeux Olympiques de Tokyo en 2021 (initialement prévus en 2020) dans la catégorie des 60 kg.',
    },
    {
      'question': 'Who holds the record for the most international goals scored for Algeria\'s men\'s national football team?',
      'options': ['Islam Slimani', 'Rabah Madjer', 'Lakhdar Belloumi', 'Riyad Mahrez'],
      'correctAnswer': 'Islam Slimani',
      'explanation': 'Islam Slimani détient le record du plus grand nombre de buts marqués pour l\'équipe nationale d\'Algérie avec plus de 40 buts internationaux.',
    },
    {
      'question': 'Which Algerian volleyball club has won the most African Club Championships?',
      'options': ['GS Pétroliers', 'MC Alger', 'ES Sétif', 'WA Tlemcen'],
      'correctAnswer': 'GS Pétroliers',
      'explanation': 'Le GS Pétroliers (anciennement MC Alger) est le club algérien de volleyball le plus titré au niveau continental avec plusieurs victoires en Championnat d\'Afrique des clubs champions.',
    },
  ];
  
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedOption;
  bool _showExplanation = false;
  bool _showResults = false;
  
  @override
  void initState() {
    super.initState();
    // Mélanger les questions
    _questions.shuffle();
  }
  
  void _checkAnswer(String option) {
    if (_answered) return;
    
    setState(() {
      _answered = true;
      _selectedOption = option;
      _showExplanation = true;
      
      if (option == _questions[_currentIndex]['correctAnswer']) {
        _score++;
      }
    });
  }
  
  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOption = null;
        _showExplanation = false;
      });
    } else {
      // Fin du quiz
      setState(() {
        _showResults = true;
      });
    }
  }
  
  void _restartQuiz() {
    setState(() {
      _questions.shuffle();
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedOption = null;
      _showExplanation = false;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quiz sur les Sports Algériens'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _showResults ? _buildResultsScreen() : _buildQuizScreen(),
    );
  }
  
  Widget _buildQuizScreen() {
    final currentQuestion = _questions[_currentIndex];
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progression
            Container(
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentIndex + 1) / _questions.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Question counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Question
            Text(
              currentQuestion['question'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 30),
            
            // Options
            ...List.generate(
              currentQuestion['options'].length,
              (index) => _buildOptionButton(currentQuestion['options'][index]),
            ),
            
            // Indicateur de défilement si non répondu
            if (!_answered && !_showExplanation) _buildScrollIndicator(),
            
            SizedBox(height: 50),
            
            // Explanation
            if (_showExplanation)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedOption == currentQuestion['correctAnswer']
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _selectedOption == currentQuestion['correctAnswer']
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _selectedOption == currentQuestion['correctAnswer']
                              ? 'Correct!'
                              : 'Incorrect!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _selectedOption == currentQuestion['correctAnswer']
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentQuestion['explanation'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _currentIndex < _questions.length - 1
                              ? 'Next Question'
                              : 'See Results',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionButton(String option) {
    final currentQuestion = _questions[_currentIndex];
    final bool isCorrect = option == currentQuestion['correctAnswer'];
    final bool isSelected = option == _selectedOption;
    
    // Couleur du bouton
    Color buttonColor = Colors.white;
    if (_answered) {
      if (isCorrect) {
        buttonColor = Colors.green.shade100;
      } else if (isSelected) {
        buttonColor = Colors.red.shade100;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _checkAnswer(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: _answered ? (isCorrect || isSelected ? 1 : 0) : 1,
          side: BorderSide(
            color: _answered
                ? isCorrect
                    ? Colors.green
                    : isSelected
                        ? Colors.red
                        : Colors.transparent
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: _answered && (isCorrect || isSelected)
                      ? isCorrect
                          ? Colors.green.shade800
                          : Colors.red.shade800
                      : Colors.black87,
                  fontWeight: _answered && isCorrect ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (_answered)
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : isSelected
                        ? Icons.cancel
                        : null,
                color: isCorrect ? Colors.green : Colors.red,
              ),
          ],
        ),
      ),
    );
  }
  
  // Indicateur de défilement
  Widget _buildScrollIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Center(
        child: Column(
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
        ),
      ),
    );
  }
  
  Widget _buildResultsScreen() {
    final percentage = (_score / _questions.length) * 100;
    String resultText;
    Color resultColor;
    IconData resultIcon;
    
    if (percentage >= 80) {
      resultText = 'Félicitations! Vous êtes un expert du sport algérien!';
      resultColor = Colors.green;
      resultIcon = Icons.emoji_events;
    } else if (percentage >= 60) {
      resultText = 'Bon travail! Vous connaissez bien le sport algérien.';
      resultColor = Colors.blue;
      resultIcon = Icons.thumb_up;
    } else if (percentage >= 40) {
      resultText = 'Pas mal! Continuez à apprendre sur le sport algérien.';
      resultColor = Colors.orange;
      resultIcon = Icons.star_half;
    } else {
      resultText = 'Vous avez encore beaucoup à apprendre sur le sport algérien!';
      resultColor = Colors.red;
      resultIcon = Icons.school;
    }
    
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                resultIcon,
                color: resultColor,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Completed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Score: $_score/${_questions.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryButton,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _score / _questions.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: resultColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                resultText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: resultColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _restartQuiz,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: AppColors.primaryButton),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Back to Games',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryButton,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 