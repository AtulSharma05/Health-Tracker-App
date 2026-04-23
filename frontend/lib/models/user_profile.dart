class UserProfile {
  final double weightKg;
  final double heightCm;
  final int age;
  final double? bodyFatPercent;
  final String gender;
  final String activityLevel;
  final String goalType;
  final int aggressiveness;

  UserProfile({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.bodyFatPercent,
    required this.gender,
    required this.activityLevel,
    required this.goalType,
    this.aggressiveness = 2,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      age: (json['age'] as num).toInt(),
      bodyFatPercent: json['bodyFatPercent'] == null ? null : (json['bodyFatPercent'] as num).toDouble(),
      gender: (json['gender'] ?? 'male').toString(),
      activityLevel: (json['activityLevel'] ?? 'moderate').toString(),
      goalType: (json['goalType'] ?? 'recomp').toString(),
      aggressiveness: (json['aggressiveness'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'heightCm': heightCm,
      'age': age,
      'bodyFatPercent': bodyFatPercent,
      'gender': gender,
      'activityLevel': activityLevel,
      'goalType': goalType,
      'aggressiveness': aggressiveness,
    };
  }
}

class MacroCalculations {
  final int bmr;
  final int maintenanceCalories;
  final int recompCalories;
  final int targetCalories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final int proteinCalories;
  final int carbCalories;
  final int fatCalories;
  final Map<String, dynamic> factors;
  final Map<String, dynamic> formulas;
  final String goalLabel;

  MacroCalculations({
    required this.bmr,
    required this.maintenanceCalories,
    required this.recompCalories,
    required this.targetCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.proteinCalories,
    required this.carbCalories,
    required this.fatCalories,
    required this.factors,
    required this.formulas,
    this.goalLabel = '',
  });

  factory MacroCalculations.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as Map<String, dynamic>? ?? {});
    return MacroCalculations(
      bmr: (results['bmr'] ?? 0) as int,
      maintenanceCalories: (results['maintenanceCalories'] ?? 0) as int,
      recompCalories: (results['recompCalories'] ?? 0) as int,
      targetCalories: (results['targetCalories'] ?? 0) as int,
      proteinG: (results['proteinG'] ?? 0) as int,
      carbsG: (results['carbsG'] ?? 0) as int,
      fatsG: (results['fatsG'] ?? 0) as int,
      proteinCalories: (results['proteinCalories'] ?? 0) as int,
      carbCalories: (results['carbCalories'] ?? 0) as int,
      fatCalories: (results['fatCalories'] ?? 0) as int,
      factors: (json['factors'] as Map<String, dynamic>? ?? {}),
      formulas: (json['formulas'] as Map<String, dynamic>? ?? {}),
      goalLabel: ((json['results'] as Map<String, dynamic>?)?['goalLabel'] ?? '').toString(),
    );
  }
}
