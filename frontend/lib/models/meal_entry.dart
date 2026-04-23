class MealEntry {
  final String id;
  final String mealName;
  final String mealType;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final DateTime createdAt;

  MealEntry({
    required this.id,
    required this.mealName,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.createdAt,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse((json['createdAt'] ?? '').toString());
    return MealEntry(
      id: (json['_id'] ?? json['id']).toString(),
      mealName: (json['mealName'] ?? '').toString(),
      mealType: (json['mealType'] ?? 'Snack').toString(),
      calories: (json['calories'] ?? 0) as int,
      protein: (json['protein'] ?? 0) as int,
      carbs: (json['carbs'] ?? 0) as int,
      fats: (json['fats'] ?? 0) as int,
      createdAt: (parsed ?? DateTime.now()).toLocal(),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'mealName': mealName,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}
