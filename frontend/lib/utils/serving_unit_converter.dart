/// Serving size unit converter
/// Converts between grams, cups, pieces, tablespoons, etc.

class ServingUnitConverter {
  // Standard conversion rates (grams per unit)
  static const Map<String, double> gramsPerUnit = {
    'g': 1.0,
    'ml': 1.0, // 1ml water ≈ 1g
    'tsp': 5.0, // 1 teaspoon ≈ 5g
    'tbsp': 15.0, // 1 tablespoon ≈ 15g
    'cup': 240.0, // 1 cup ≈ 240g (varies by ingredient)
    'oz': 28.35, // 1 ounce ≈ 28.35g
    'lb': 453.6, // 1 pound ≈ 453.6g
  };

  // Unit display names
  static const Map<String, String> unitNames = {
    'g': 'grams',
    'ml': 'milliliters',
    'tsp': 'teaspoon',
    'tbsp': 'tablespoon',
    'cup': 'cup',
    'oz': 'ounce',
    'lb': 'pound',
    'piece': 'piece',
  };

  // Ingredient-specific conversions (overrides default)
  static const Map<String, Map<String, double>> ingredientSpecific = {
    'rice': {
      'cup': 185.0, // 1 cup uncooked rice ≈ 185g
      'tbsp': 12.0, // 1 tbsp rice ≈ 12g
    },
    'flour': {
      'cup': 120.0, // 1 cup all-purpose flour ≈ 120g
      'tbsp': 8.0, // 1 tbsp flour ≈ 8g
    },
    'sugar': {
      'cup': 200.0, // 1 cup sugar ≈ 200g
      'tbsp': 12.5, // 1 tbsp sugar ≈ 12.5g
    },
    'butter': {
      'cup': 227.0, // 1 cup butter ≈ 227g
      'tbsp': 14.0, // 1 tbsp butter ≈ 14g
    },
    'milk': {
      'cup': 240.0, // 1 cup milk ≈ 240ml ≈ 240g
      'tbsp': 15.0, // 1 tbsp milk ≈ 15ml
    },
    'paneer': {
      'cup': 200.0, // 1 cup paneer ≈ 200g
      'tbsp': 12.0, // 1 tbsp crumbled paneer ≈ 12g
      'piece': 30.0, // 1 piece paneer (approx) ≈ 30g
    },
    'chicken': {
      'piece': 100.0, // 1 piece chicken breast ≈ 100g
      'oz': 28.35,
    },
    'egg': {
      'piece': 50.0, // 1 large egg ≈ 50g
    },
  };

  /// Convert quantity from one unit to grams
  /// Example: convertToGrams('rice', 1.0, 'cup') → 185.0
  static double convertToGrams(
    String? foodName,
    double quantity,
    String unit,
  ) {
    if (quantity <= 0) return 0;

    // Check ingredient-specific conversion first
    if (foodName != null && foodName.isNotEmpty) {
      final normalizedFood = foodName.toLowerCase();
      if (ingredientSpecific.containsKey(normalizedFood)) {
        final specific = ingredientSpecific[normalizedFood]!;
        if (specific.containsKey(unit)) {
          return quantity * specific[unit]!;
        }
      }
    }

    // Fall back to standard conversion
    if (gramsPerUnit.containsKey(unit)) {
      return quantity * gramsPerUnit[unit]!;
    }

    // Default: assume grams if unit not found
    return quantity;
  }

  /// Convert grams to a specific unit
  /// Example: convertFromGrams('rice', 185.0, 'cup') → 1.0
  static double convertFromGrams(
    String? foodName,
    double grams,
    String unit,
  ) {
    if (grams <= 0) return 0;

    // Check ingredient-specific conversion first
    if (foodName != null && foodName.isNotEmpty) {
      final normalizedFood = foodName.toLowerCase();
      if (ingredientSpecific.containsKey(normalizedFood)) {
        final specific = ingredientSpecific[normalizedFood]!;
        if (specific.containsKey(unit)) {
          return grams / specific[unit]!;
        }
      }
    }

    // Fall back to standard conversion
    if (gramsPerUnit.containsKey(unit)) {
      return grams / gramsPerUnit[unit]!;
    }

    // Default: assume grams
    return grams;
  }

  /// Get available units for a specific food
  static List<String> getAvailableUnits(String? foodName) {
    final baseUnits = ['g', 'ml', 'oz'];

    if (foodName != null && foodName.isNotEmpty) {
      final normalizedFood = foodName.toLowerCase();
      if (ingredientSpecific.containsKey(normalizedFood)) {
        final specific = ingredientSpecific[normalizedFood]!;
        return [
          'g',
          ...specific.keys.where((u) => u != 'g'),
        ];
      }
    }

    return ['g', 'ml', 'cup', 'tbsp', 'oz'];
  }

  /// Format unit for display
  static String formatUnit(String unit) {
    return unitNames[unit] ?? unit;
  }

  /// Suggest quantity based on unit
  /// e.g., 1 cup, 2 tbsp, 100g
  static double suggestQuantity(String unit) {
    switch (unit) {
      case 'cup':
      case 'piece':
        return 1.0;
      case 'tbsp':
      case 'tsp':
        return 2.0;
      default:
        return 100.0; // grams
    }
  }
}
