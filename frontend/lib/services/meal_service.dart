import 'package:flutter/foundation.dart';
import '../models/meal_entry.dart';
import '../models/nutrition_stats.dart';
import 'api_service.dart';

class MealService extends ChangeNotifier {
  MealService(this._apiService);

  final ApiService _apiService;
  final List<MealEntry> _entries = [];
  final List<DailyCaloriesStat> _dailyCalories = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<MealEntry> get entries => List<MealEntry>.from(_entries)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<DailyCaloriesStat> get dailyCalories => List<DailyCaloriesStat>.from(_dailyCalories)
    ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> fetchMeals() async {
    if (_apiService.token == null) {
      _entries.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/meals');
      final data = response.data as Map<String, dynamic>;
      final meals = (data['meals'] as List<dynamic>? ?? [])
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _entries
        ..clear()
        ..addAll(meals);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(MealEntry meal) async {
    await _apiService.post('/meals', meal.toCreatePayload());
    await fetchMeals();
    await fetchStats();
  }

  Future<void> removeMeal(String id) async {
    await _apiService.delete('/meals/$id');
    await fetchMeals();
    await fetchStats();
  }

  Future<void> fetchStats({int periodDays = 7}) async {
    if (_apiService.token == null) {
      _dailyCalories.clear();
      notifyListeners();
      return;
    }

    final response = await _apiService.get('/meals/stats?periodDays=$periodDays');
    final data = response.data as Map<String, dynamic>;
    final points = (data['dailyCalories'] as List<dynamic>? ?? [])
        .map((e) => DailyCaloriesStat.fromJson(e as Map<String, dynamic>))
        .toList();

    final normalizedPoints = points.isNotEmpty ? points : _buildDailyFromEntries(periodDays);
    _dailyCalories
      ..clear()
      ..addAll(normalizedPoints);
    notifyListeners();
  }

  List<DailyCaloriesStat> _buildDailyFromEntries(int periodDays) {
    final start = DateTime.now().subtract(Duration(days: periodDays - 1));
    final byDay = <String, int>{};

    for (final meal in _entries) {
      final localDay = DateTime(meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
      if (localDay.isBefore(DateTime(start.year, start.month, start.day))) {
        continue;
      }
      final key = '${localDay.year.toString().padLeft(4, '0')}-${localDay.month.toString().padLeft(2, '0')}-${localDay.day.toString().padLeft(2, '0')}';
      byDay[key] = (byDay[key] ?? 0) + meal.calories;
    }

    return byDay.entries
        .map((e) => DailyCaloriesStat(
              date: DateTime.parse(e.key),
              calories: e.value,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int get totalCalories => _entries.fold(0, (sum, m) => sum + m.calories);
  int get totalProtein => _entries.fold(0, (sum, m) => sum + m.protein);
  int get totalCarbs => _entries.fold(0, (sum, m) => sum + m.carbs);
  int get totalFats => _entries.fold(0, (sum, m) => sum + m.fats);

  List<MealEntry> get todayEntries {
    final now = DateTime.now();
    return _entries.where((m) => _isSameLocalDay(m.createdAt, now)).toList();
  }

  int get todayCalories => todayEntries.fold(0, (sum, m) => sum + m.calories);
  int get todayProtein => todayEntries.fold(0, (sum, m) => sum + m.protein);
  int get todayCarbs => todayEntries.fold(0, (sum, m) => sum + m.carbs);
  int get todayFats => todayEntries.fold(0, (sum, m) => sum + m.fats);

  bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
