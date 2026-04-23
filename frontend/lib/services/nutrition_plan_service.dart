import 'api_service.dart';

class PlannedFoodItem {
  PlannedFoodItem({
    required this.foodName,
    required this.servings,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final String foodName;
  final double servings;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  factory PlannedFoodItem.fromJson(Map<String, dynamic> json) {
    return PlannedFoodItem(
      foodName: (json['foodName'] ?? '').toString(),
      servings: (json['servings'] as num? ?? 0).toDouble(),
      grams: (json['grams'] as num? ?? 0).toDouble(),
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fats: (json['fats'] as num? ?? 0).toDouble(),
    );
  }
}

class PlannedMeal {
  PlannedMeal({
    required this.date,
    required this.mealType,
    required this.items,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final DateTime date;
  final String mealType;
  final List<PlannedFoodItem> items;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map<String, dynamic>? ?? {});
    return PlannedMeal(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      mealType: (json['mealType'] ?? 'Meal').toString(),
      items: (json['foodItems'] as List<dynamic>? ?? [])
          .map((e) => PlannedFoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      calories: (totals['calories'] as num? ?? 0).toDouble(),
      protein: (totals['protein'] as num? ?? 0).toDouble(),
      carbs: (totals['carbs'] as num? ?? 0).toDouble(),
      fats: (totals['fats'] as num? ?? 0).toDouble(),
    );
  }
}

class GeneratedPlan {
  GeneratedPlan({
    required this.planId,
    required this.planName,
    required this.planDescription,
    required this.startDate,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.planTotalCalories,
    required this.planTotalProtein,
    required this.planTotalCarbs,
    required this.planTotalFats,
    required this.meals,
  });

  final String planId;
  final String planName;
  final String? planDescription;
  final DateTime startDate;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFats;
  final double planTotalCalories;
  final double planTotalProtein;
  final double planTotalCarbs;
  final double planTotalFats;
  final List<PlannedMeal> meals;

  factory GeneratedPlan.fromJson(Map<String, dynamic> json) {
    final targets = (json['targets'] as Map<String, dynamic>? ?? {});
    final planTotals = (json['planTotals'] as Map<String, dynamic>? ?? {});
    return GeneratedPlan(
      planId: (json['planId'] ?? '').toString(),
      planName: (json['planName'] ?? 'My Meal Plan').toString(),
      planDescription: (json['planDescription'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()) ?? DateTime.now(),
      targetCalories: (targets['calories'] as num? ?? 0).toDouble(),
      targetProtein: (targets['protein'] as num? ?? 0).toDouble(),
      targetCarbs: (targets['carbs'] as num? ?? 0).toDouble(),
      targetFats: (targets['fats'] as num? ?? 0).toDouble(),
      planTotalCalories: (planTotals['calories'] as num? ?? 0).toDouble(),
      planTotalProtein: (planTotals['protein'] as num? ?? 0).toDouble(),
      planTotalCarbs: (planTotals['carbs'] as num? ?? 0).toDouble(),
      planTotalFats: (planTotals['fats'] as num? ?? 0).toDouble(),
      meals: (json['meals'] as List<dynamic>? ?? [])
          .map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NutritionPlanService {
  NutritionPlanService(this._apiService);

  final ApiService _apiService;

  Future<GeneratedPlan> generatePlan({
    required bool vegetarian,
    required bool vegan,
    required bool dairyFree,
    required bool glutenFree,
    required bool indianOnly,
    bool highProtein = false,
    bool lowCarb = false,
    int calorieMin = 1800,
    int calorieMax = 2400,
  }) async {
    final response = await _apiService.post('/plans/generate', {
      'vegetarian': vegetarian,
      'vegan': vegan,
      'dairyFree': dairyFree,
      'glutenFree': glutenFree,
      'indianOnly': indianOnly,
      // ✨ NEW: Pass macro preferences
      'highProtein': highProtein,
      'lowCarb': lowCarb,
      'calorieRange': {
        'min': calorieMin,
        'max': calorieMax,
      },
    });

    final data = response.data as Map<String, dynamic>;
    return GeneratedPlan.fromJson(data);
  }
}
