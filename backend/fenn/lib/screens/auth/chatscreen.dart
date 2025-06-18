import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/chat_service.dart';
import 'dart:math' as math;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showCorrectionHelp = false;
  
  // Variable pour suivre l'onglet d'aide actuellement sélectionné
  int _selectedHelpTab = 0;
  
  // Variables pour le suivi des quiz
  String? _lastQuizQuestion;
  String? _lastQuizAnswer;
  List<String>? _lastQuizChoices;
  
  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Méthode pour défiler automatiquement vers le bas
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _chatService.getChatHistory();
      
      setState(() {
        _messages.clear();
        for (var msg in history) {
          _messages.add(ChatMessage(
            text: msg['content'],
            isUser: msg['role'] == 'user',
            id: msg['id'],
            videoUrl: msg['video_url'],
          ));
        }
      });
      // Défiler vers le bas après avoir chargé l'historique
      _scrollToBottom();
    } catch (e) {
      _showError("Impossible de charger l'historique des messages");
    } finally {
      setState(() {
        _isLoading = false;
        
        // Si l'historique est vide, ajouter un message de bienvenue
        if (_messages.isEmpty) {
          _messages.add(ChatMessage(
            text: "Bonjour ! Je suis votre assistant d'apprentissage d'anglais. Comment puis-je vous aider aujourd'hui ?",
            isUser: false,
            id: 'welcome',
          ));
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAE6B2),
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.transparent),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/mascotte_tete.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FENNEC AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Text(
                        'ONLINE',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              setState(() {
                _showCorrectionHelp = !_showCorrectionHelp;
              });
            },
            tooltip: "Aide et fonctionnalités",
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _restartChat,
            tooltip: "Redémarrer le chat",
          ),
        ],
        backgroundColor: const Color(0xFF4A5C7A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_showCorrectionHelp)
            _buildCombinedHelp(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      // Filtrer pour n'afficher QUE les messages du backend (chatbot)
                      final displayMessages = _messages.where((msg) =>
                        !msg.isUser && msg.id != 'welcome' && msg.text.trim().isNotEmpty
                      ).toList();
                      if (displayMessages.isEmpty) {
                        return Center(
                          child: Text(
                            "Commencez la conversation…",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: displayMessages.length,
                        itemBuilder: (context, index) {
                          final message = displayMessages[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildCombinedHelp() {
    // Liste des titres des onglets
    final List<String> tabs = ['Langues', 'Commandes', 'Quiz', 'Fonctionnalités'];
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et bouton de fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aide et fonctionnalités',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: const Color(0xFF4A5C7A),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16.0),
                onPressed: () {
                  setState(() {
                    _showCorrectionHelp = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          
          // Onglets de navigation
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedHelpTab == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedHelpTab = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4A5C7A) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Contenu de l'onglet sélectionné
          _buildSelectedTabContent(),
        ],
      ),
    );
  }
  
  // Méthode pour afficher le contenu de l'onglet sélectionné
  Widget _buildSelectedTabContent() {
    switch (_selectedHelpTab) {
      case 0:
        return _buildLanguesTabContent();
      case 1: 
        return _buildCommandesTabContent();
      case 2:
        return _buildQuizTabContent();
      case 3:
        return _buildFonctionnalitesTabContent();
      default:
        return Container();
    }
  }
  
  // Contenu de l'onglet Langues
  Widget _buildLanguesTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Langues supportées:',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF4A5C7A)
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: [
            Chip(
              label: Text('Français', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('English', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('دارجة', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Text(
          'Le chatbot détecte automatiquement la langue utilisée dans votre message et répond dans la même langue. Vous pouvez discuter en français, anglais ou darija.',
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Exemples: "Comment vas-tu?" (fr), "How are you?" (en), "Labas?" (dz)',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }
  
  // Contenu de l'onglet Commandes
  Widget _buildCommandesTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correction de phrases:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A5C7A),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Pour corriger une phrase, commencez votre message par l\'un des mots suivants :',
          style: TextStyle(color: const Color(0xFF4A5C7A)),
        ),
        const SizedBox(height: 4.0),
        Wrap(
          spacing: 8.0,
          children: [
            Chip(
              label: Text('corrige', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF4A5C7A),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('correct', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF4A5C7A),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('saha7', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('check', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF4A5C7A),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          'Exemple: "corrige I has a book" ou "saha7 she go to school"',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.blue[800],
          ),
        ),
        
        const Divider(height: 24.0),
        
        Text(
          'Autres commandes utiles:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A5C7A),
          ),
        ),
        const SizedBox(height: 8.0),
        _buildCommandCard(
          command: 'score / nati9a', 
          description: 'Affiche votre score actuel et vos progrès'
        ),
        _buildCommandCard(
          command: 'erreurs / akhta2', 
          description: 'Montre vos erreurs les plus fréquentes'
        ),
        _buildCommandCard(
          command: 'salut / hello / salam', 
          description: 'Commence une conversation'
        ),
      ],
    );
  }
  
  // Contenu de l'onglet Quiz
  Widget _buildQuizTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz linguistiques:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A5C7A),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Pour lancer un quiz, utilisez l\'un de ces mots-clés en fonction de votre langue préférée:',
          style: TextStyle(color: const Color(0xFF4A5C7A)),
        ),
        const SizedBox(height: 12.0),
        
        _buildCommandCard(
          command: 'quiz', 
          description: 'Lance un quiz en français'
        ),
        _buildCommandCard(
          command: 'ikhtibir / test / su2al', 
          description: 'Lance un quiz en darija'
        ),
        _buildCommandCard(
          command: 'quiz débutant / quiz intermédiaire / quiz avancé', 
          description: 'Lance un quiz avec un niveau spécifique'
        ),
        
        const Divider(height: 16.0),
        
        Text(
          'Comment répondre:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A5C7A),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Répondez simplement avec la lettre correspondant à votre choix (A, B, C ou D).',
          style: TextStyle(color: const Color(0xFF4A5C7A)),
        ),
      ],
    );
  }
  
  // Contenu de l'onglet Fonctionnalités
  Widget _buildFonctionnalitesTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités disponibles:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A5C7A),
          ),
        ),
        const SizedBox(height: 12.0),
        
        // Communication en darija
        _buildFeatureItem(
          icon: Icons.chat,
          title: 'Communication en darija',
          description: 'Le chatbot comprend et peut répondre en darija.',
          example: 'salam, kifach nqadr nsta3ml had tatbi9?',
        ),
        
        // Traductions
        _buildFeatureItem(
          icon: Icons.translate,
          title: 'Traductions',
          description: 'Demandez la traduction de mots (français/anglais/darija).',
          example: 'cha ma3na "apple"? / que veut dire "tuffaha"?',
        ),
        
        // Recherche d'informations
        _buildFeatureItem(
          icon: Icons.search,
          title: 'Recherche d\'informations',
          description: 'Posez des questions sur du vocabulaire ou des points de grammaire.',
          example: 'comment conjuguer les verbes au passé?',
        ),
        
        // Score personnel
        _buildFeatureItem(
          icon: Icons.score,
          title: 'Score personnel',
          description: 'Suivez votre progression et vos points accumulés.',
          example: 'score / nati9a',
        ),
      ],
    );
  }
  
  // Helper pour afficher une commande avec sa description
  Widget _buildCommandCard({required String command, required String description}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              command,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A5C7A),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              description,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required String example,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF4A5C7A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A5C7A),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  'Ex: "$example"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    debugPrint('Affichage message: isUser=${message.isUser}, id=${message.id}, text="${message.text}"');
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFFF8B1F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: Radius.circular(message.isUser ? 16.0 : 0.0),
            bottomRight: Radius.circular(message.isUser ? 0.0 : 16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text.isNotEmpty ? message.text : '(Message vide)',
              style: TextStyle(
                color: message.isUser ? Colors.white : const Color(0xFF303E5D),
                fontSize: 15.0,
              ),
            ),
            if (message.videoUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline, size: 20, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      "Voir l'explication vidéo",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!message.isUser && message.id != 'welcome') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _sendFeedback(message.id, 'helpful'),
                    child: Icon(Icons.thumb_up, size: 16, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
  onTap: () => _sendFeedback(message.id, 'not_helpful'),
  child: Icon(Icons.thumb_down, size: 16, color: Colors.red),
),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendFeedback(String messageId, String feedbackType) async {
    try {
      final success = await _chatService.sendFeedback(messageId, feedbackType);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merci pour votre feedback!')),
        );
      }
    } catch (e) {
      _showError('Impossible d\'envoyer le feedback');
    }
  }

  void _restartChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Bienvenue ! Comment puis-je vous aider aujourd'hui ?",
        isUser: false,
        id: 'welcome',
      ));
      _lastQuizQuestion = null;
      _lastQuizAnswer = null;
      _lastQuizChoices = null;
    });
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDAE6B2),
        boxShadow: [
          BoxShadow(
            color: Colors.transparent.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Color(0xFF303E5D)),
              decoration: InputDecoration(
                hintText: 'Chat...',
                hintStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF8D99AE).withOpacity(1),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: const Color(0xFFFF8B1F),
            child: IconButton(
              icon: const Icon(Icons.send, color: Color(0xFFFFFFFF)),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  // Extraction des informations de quiz depuis la réponse du chatbot
  // Nouvelle méthode : extraction des données de quiz à partir du champ quiz_data de la réponse JSON
  void _extractQuizDataFromJson(Map<String, dynamic> data) {
    if (data.containsKey('quiz_data')) {
      print("Quiz détecté dans la réponse chatbot (champ quiz_data présent)");
      final quizData = data['quiz_data'];
      final questionText = quizData['question_text']?.toString() ?? '';
      final correctAnswer = quizData['correct_answer']?.toString() ?? '';
      final explanation = quizData['explanation']?.toString() ?? '';
      _lastQuizQuestion = questionText;
      _lastQuizAnswer = correctAnswer;
      // Extraction des choix à partir du texte de la question si possible
      _lastQuizChoices = [];
      RegExp choiceRegex = RegExp(r'([A-D])\.\s*(.*?)(?=\n[A-D]\\.|\n\n|$)', dotAll: true);
      Iterable<Match> choiceMatches = choiceRegex.allMatches(questionText);
      for (Match match in choiceMatches) {
        if (match.groupCount >= 2) {
          String letter = match.group(1) ?? "";
          String choice = match.group(2)?.trim() ?? "";
          _lastQuizChoices!.add("$letter. $choice");
        }
      }
      print("Contenu complet du quiz: $questionText");
      print("Réponse correcte: $correctAnswer");
      print("Explication: $explanation");
    } else {
      _lastQuizQuestion = null;
      _lastQuizAnswer = null;
      _lastQuizChoices = null;
    }
  }

  // Vérification des réponses aux quiz
  bool _isQuizAnswer(String text) {
    // Vérifier si le texte est une seule lettre A, B, C ou D (avec ou sans point)
    String trimmed = text.trim().toUpperCase();
    
    // Accepte A, B, C, D, A., B., C., D., ou même "réponse A"
    bool isAnswer = trimmed == "A" || trimmed == "B" || trimmed == "C" || trimmed == "D" ||
                    trimmed == "A." || trimmed == "B." || trimmed == "C." || trimmed == "D." ||
                    trimmed.endsWith(" A") || trimmed.endsWith(" B") || 
                    trimmed.endsWith(" C") || trimmed.endsWith(" D");
    
    print("Vérifiant si '$trimmed' est une réponse de quiz: $isAnswer");
    print("État actuel du quiz - Question existe: ${_lastQuizQuestion != null}, Réponse attendue: $_lastQuizAnswer");
    
    // Retourner true seulement si c'est une réponse au format attendu ET qu'un quiz est actif
    return isAnswer && _lastQuizQuestion != null;
  }

  String _evaluateQuizAnswer(String userAnswer) {
    print("Évaluation de la réponse au quiz: $userAnswer");
    
    if (_lastQuizQuestion == null || _lastQuizAnswer == null) {
      print("Impossible d'évaluer: pas de question ou réponse en attente");
      return "Je ne me souviens pas d'avoir posé une question de quiz récemment.";
    }
    
    // Extraire juste la lettre de la réponse de l'utilisateur (A, B, C, D)
    String normalizedAnswer = userAnswer.trim().toUpperCase();
    
    // Extraire la dernière lettre si la réponse est du format "réponse X"
    if (normalizedAnswer.length > 1 && !normalizedAnswer.startsWith("A") && 
        !normalizedAnswer.startsWith("B") && !normalizedAnswer.startsWith("C") && 
        !normalizedAnswer.startsWith("D")) {
      normalizedAnswer = normalizedAnswer.substring(normalizedAnswer.length - 1);
    }
    
    // Supprimer le point s'il est présent
    normalizedAnswer = normalizedAnswer.replaceAll(".", "");
    
    // Assurer que c'est juste une lettre
    if (normalizedAnswer.length > 1) {
      normalizedAnswer = normalizedAnswer.substring(0, 1);
    }
    
    String expectedAnswer = _lastQuizAnswer?.toUpperCase().replaceAll(".", "") ?? "";
    print("Réponse normalisée: '$normalizedAnswer', réponse attendue: '$expectedAnswer'");
    
    if (normalizedAnswer == expectedAnswer) {
      print("Réponse correcte!");
      String questionText = _lastQuizQuestion?.split("\n").first ?? "la question";
      return "✅ Correct! C'est la bonne réponse à $questionText!\n\nVoulez-vous essayer un autre quiz? Dites 'quiz' pour continuer.";
    } else {
      print("Réponse incorrecte!");
      return "❌ Désolé, ce n'est pas la bonne réponse. La réponse correcte était: $_lastQuizAnswer.\n\nVoulez-vous essayer un autre quiz? Dites 'quiz' pour continuer.";
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Vérifier si c'est une réponse à un quiz
    bool isQuizAnswer = _isQuizAnswer(messageText);
    print("Envoi d'un message: '$messageText', est une réponse de quiz: $isQuizAnswer");
    print("État du quiz - Question définie: ${_lastQuizQuestion != null}, Réponse attendue: $_lastQuizAnswer");

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        id: DateTime.now().toString(),
      ));
      _messageController.clear();
      _isLoading = true;
    });
    
    // Défiler vers le bas après l'envoi du message utilisateur
    _scrollToBottom();

    try {
      if (isQuizAnswer && _lastQuizQuestion != null) {
        print("Traitement local de la réponse au quiz");
        // Traiter localement la réponse au quiz
        final evaluationResponse = _evaluateQuizAnswer(messageText);
        
        setState(() {
          _messages.add(ChatMessage(
            text: evaluationResponse,
            isUser: false,
            id: DateTime.now().toString(),
          ));
          _isLoading = false;
        });
        
        // Réinitialiser les données du quiz après la réponse
        print("Réinitialisation des données du quiz");
        _lastQuizQuestion = null;
        _lastQuizAnswer = null;
        _lastQuizChoices = null;
      } else {
        // Envoyer la requête normale au serveur
        print("Envoi du message au serveur");
        final response = await _chatService.sendMessage(messageText);
        debugPrint("Réponse complète du serveur: ${response.toString()}");

        // Extraire les données de quiz si présentes dans le JSON
        _extractQuizDataFromJson(response);

        setState(() {
          // Si quiz_data existe, afficher la question du quiz, sinon afficher la réponse normale
          if (response.containsKey('quiz_data')) {
            debugPrint('Ajout message bot (quiz): "${response['quiz_data']['question_text']}"');
            _messages.add(ChatMessage(
              text: response['quiz_data']['question_text'] ?? '',
              isUser: false,
              id: response['id'] ?? DateTime.now().toString(),
              videoUrl: response['video_url'],
            ));
          } else if (response.containsKey('text') && response['text'] != null) {
            debugPrint('Ajout message bot (text): "${response['text']}"');
            _messages.add(ChatMessage(
              text: response['text'] ?? '',
              isUser: false,
              id: response['id'] ?? DateTime.now().toString(),
              videoUrl: response['video_url'],
            ));
          } else {
            debugPrint('Réponse invalide du serveur: ${response.toString()}');
            _messages.add(ChatMessage(
              text: '(Erreur: réponse invalide du serveur)',
              isUser: false,
              id: DateTime.now().toString(),
            ));
          }
          _isLoading = false;
        });
      }
      
      // Défiler vers le bas après avoir reçu la réponse
      _scrollToBottom();
    } catch (e) {
      print("Erreur lors de l'envoi du message: $e");
      setState(() {
        _isLoading = false;
      });
      _showError('Impossible d\'envoyer le message');
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String id;
  final String? videoUrl;

  ChatMessage({
    required this.text, 
    required this.isUser, 
    required this.id, 
    this.videoUrl,
  });
}