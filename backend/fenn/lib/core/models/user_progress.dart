class UserProgress {
  final int completedLessons;
  final int totalLessons;
  final int currentStreak;
  final double progressPercentage;
  
  const UserProgress({
    this.completedLessons = 0,
    this.totalLessons = 0,
    this.currentStreak = 0,
    this.progressPercentage = 0.0,
  });
  
  // Créer une instance à partir des données JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      completedLessons: json['completed_lessons'] ?? 0,
      totalLessons: json['total_lessons'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      progressPercentage: json['progress_percentage']?.toDouble() ?? 0.0,
    );
  }
  
  // Méthode pour mettre à jour l'instance avec de nouvelles données
  UserProgress copyWith({
    int? completedLessons,
    int? totalLessons,
    int? currentStreak,
    double? progressPercentage,
  }) {
    return UserProgress(
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons ?? this.totalLessons,
      currentStreak: currentStreak ?? this.currentStreak,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
  
  // Getter pour obtenir le pourcentage de progression formaté
  String get formattedProgressPercentage {
    return '${progressPercentage.toStringAsFixed(0)}%';
  }
} 