class DailyCaloriesStat {
  final DateTime date;
  final int calories;

  DailyCaloriesStat({
    required this.date,
    required this.calories,
  });

  factory DailyCaloriesStat.fromJson(Map<String, dynamic> json) {
    return DailyCaloriesStat(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      calories: (json['calories'] ?? 0) as int,
    );
  }
}
