/// Workout Statistics Model
/// Matches backend /workouts/stats response structure
class WorkoutStats {
  final StatsOverview overview;
  final List<WorkoutByType> workoutsByType;
  final List<TopExercise> topExercises;
  final List<WeeklyProgress> weeklyProgress;
  final StatsPeriod period;

  WorkoutStats({
    required this.overview,
    required this.workoutsByType,
    required this.topExercises,
    required this.weeklyProgress,
    required this.period,
  });

  factory WorkoutStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return WorkoutStats(
      overview: StatsOverview.fromJson(data['overview'] ?? {}),
      workoutsByType: (data['workoutsByType'] as List<dynamic>?)
              ?.map((e) => WorkoutByType.fromJson(e))
              .toList() ??
          [],
      topExercises: (data['topExercises'] as List<dynamic>?)
              ?.map((e) => TopExercise.fromJson(e))
              .toList() ??
          [],
      weeklyProgress: (data['weeklyProgress'] as List<dynamic>?)
              ?.map((e) => WeeklyProgress.fromJson(e))
              .toList() ??
          [],
      period: StatsPeriod.fromJson(data['period'] ?? {}),
    );
  }
}

/// Stats Overview - Basic aggregated statistics
class StatsOverview {
  final int totalWorkouts;
  final double totalDuration; // in minutes
  final double totalCalories;
  final double avgDuration;
  final double avgCalories;
  final int currentStreak; // days

  StatsOverview({
    required this.totalWorkouts,
    required this.totalDuration,
    required this.totalCalories,
    required this.avgDuration,
    required this.avgCalories,
    required this.currentStreak,
  });

  factory StatsOverview.fromJson(Map<String, dynamic> json) {
    return StatsOverview(
      totalWorkouts: json['totalWorkouts'] ?? 0,
      totalDuration: (json['totalDuration'] ?? 0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
      avgDuration: (json['avgDuration'] ?? 0).toDouble(),
      avgCalories: (json['avgCalories'] ?? 0).toDouble(),
      currentStreak: json['currentStreak'] ?? 0,
    );
  }
}

/// Workouts grouped by type
class WorkoutByType {
  final String type; // cardio, strength, flexibility, sports, other
  final int count;
  final double totalDuration;
  final double totalCalories;

  WorkoutByType({
    required this.type,
    required this.count,
    required this.totalDuration,
    required this.totalCalories,
  });

  factory WorkoutByType.fromJson(Map<String, dynamic> json) {
    return WorkoutByType(
      type: json['_id'] ?? 'other',
      count: json['count'] ?? 0,
      totalDuration: (json['totalDuration'] ?? 0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
    );
  }
}

/// Top exercises by frequency
class TopExercise {
  final String name;
  final int count;
  final double avgDuration;
  final double avgCalories;

  TopExercise({
    required this.name,
    required this.count,
    required this.avgDuration,
    required this.avgCalories,
  });

  factory TopExercise.fromJson(Map<String, dynamic> json) {
    return TopExercise(
      name: json['_id'] ?? '',
      count: json['count'] ?? 0,
      avgDuration: (json['avgDuration'] ?? 0).toDouble(),
      avgCalories: (json['avgCalories'] ?? 0).toDouble(),
    );
  }
}

/// Weekly progress data for charts
class WeeklyProgress {
  final int year;
  final int week;
  final int workoutCount;
  final double totalDuration;
  final double totalCalories;

  WeeklyProgress({
    required this.year,
    required this.week,
    required this.workoutCount,
    required this.totalDuration,
    required this.totalCalories,
  });

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? {};
    return WeeklyProgress(
      year: id['year'] ?? DateTime.now().year,
      week: id['week'] ?? 1,
      workoutCount: json['workoutCount'] ?? 0,
      totalDuration: (json['totalDuration'] ?? 0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
    );
  }
  
  /// Get a readable label for the week
  String get label => 'W$week';
}

/// Stats period information
class StatsPeriod {
  final DateTime startDate;
  final DateTime endDate;

  StatsPeriod({
    required this.startDate,
    required this.endDate,
  });

  factory StatsPeriod.fromJson(Map<String, dynamic> json) {
    return StatsPeriod(
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now().subtract(const Duration(days: 30)),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
    );
  }
}
