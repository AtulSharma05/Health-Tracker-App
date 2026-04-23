import '../utils/serving_unit_converter.dart';

class Food {
  final String id;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final double fiberG;
  final double servingSizeG;
  final List<String> mealSlots;
  final List<String> tags;

  Food({
    required this.id,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.fiberG,
    required this.servingSizeG,
    required this.mealSlots,
    required this.tags,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'other',
      caloriesPer100g: (json['caloriesPer100g'] ?? 0).toDouble(),
      proteinG: (json['proteinG'] ?? 0).toDouble(),
      carbsG: (json['carbsG'] ?? 0).toDouble(),
      fatsG: (json['fatsG'] ?? 0).toDouble(),
      fiberG: (json['fiberG'] ?? 0).toDouble(),
      servingSizeG: (json['servingSizeG'] ?? 100).toDouble(),
      mealSlots: List<String>.from(json['mealSlots'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// Calculate nutrition based on quantity in grams
  Map<String, double> calculateNutrition(double quantityG) {
    final multiplier = quantityG / 100.0;
    return {
      'calories': caloriesPer100g * multiplier,
      'protein': proteinG * multiplier,
      'carbs': carbsG * multiplier,
      'fats': fatsG * multiplier,
      'fiber': fiberG * multiplier,
    };
  }

  /// Calculate nutrition based on quantity + unit
  /// Example: calculateNutritionByUnit(1.0, 'cup') for rice
  Map<String, double> calculateNutritionByUnit(
    double quantity,
    String unit,
  ) {
    final grams = ServingUnitConverter.convertToGrams(name, quantity, unit);
    return calculateNutrition(grams);
  }

  /// Get available units for this food
  List<String> getAvailableUnits() {
    return ServingUnitConverter.getAvailableUnits(name);
  }

  /// Suggest serving size quantity based on recommended unit
  double suggestServingQuantity(String unit) {
    return ServingUnitConverter.suggestQuantity(unit);
  }
}
