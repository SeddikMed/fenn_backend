import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'category_games/sport_games.dart';
import 'category_games/culture_games.dart';
import 'category_games/cuisine_games.dart';
import 'category_games/travel_games.dart';
import 'category_games/technology_games.dart';
import 'category_games/business_games.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  // Liste de dégradés pour chaque catégorie
  final List<LinearGradient> categoryGradients = const [
    LinearGradient(
      colors: [Color(0xFF4A5C7A), Color(0xFFA9B6C7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFF6ECB71)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFD32F2F), Color(0xFFE88A89)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF6A1B9A), Color(0xFFC278D5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF0277BD), Color(0xFF8DCFF1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFEF6C00), Color(0xFFFAD29F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF00897B), Color(0xFF95D9D5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catégories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: 7,
        itemBuilder: (context, index) {
          return _CategoryItem(
            title: _getTitle(index),
            icon: _getIcon(index),
            gradient: categoryGradients[index],
            onTap: () => _navigateToCategory(context, index),
          );
        },
      ),
    );
  }

  void _navigateToCategory(BuildContext context, int index) {
    Widget screen;
    
    switch(index) {
      case 0: // Basic
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie Basic en développement')),
        );
        return;
      case 1: // Sports
        screen = const SportGamesScreen();
        break;
      case 2: // History
        screen = const CultureGamesScreen();
        break;
      case 3: // Geography
        screen = const TravelGamesScreen();
        break;
      case 4: // Algeria
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie Algeria en développement')),
        );
        return;
      case 5: // Technology
        screen = const TechnologyGamesScreen();
        break;
      case 6: // Nature
        screen = const BusinessGamesScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie en développement')),
        );
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  String _getTitle(int index) {
    switch(index) {
      case 0: return 'Basic';
      case 1: return 'Sports';
      case 2: return 'History';
      case 3: return 'Geography';
      case 4: return 'Algeria';
      case 5: return 'Technology';
      case 6: return 'Nature';
      default: return '';
    }
  }

  IconData _getIcon(int index) {
    switch(index) {
      case 0: return Icons.library_books;
      case 1: return Icons.sports_soccer;
      case 2: return Icons.history_edu;
      case 3: return Icons.public;
      case 4: return Icons.flag;
      case 5: return Icons.computer;
      case 6: return Icons.forest;
      default: return Icons.category;
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}