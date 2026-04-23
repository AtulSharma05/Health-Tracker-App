class WorkoutPlan {
  final String goal;
  final String experience;
  final int daysPerWeek;
  final List<String> equipment;
  final List<String> targetMuscles;
  final int duration;
  final List<WorkoutDay> days;
  final DateTime createdAt;
  final String? plan; // AI-generated text plan

  WorkoutPlan({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.equipment,
    required this.targetMuscles,
    required this.duration,
    required this.days,
    required this.createdAt,
    this.plan,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      goal: json['goal'] ?? '',
      experience: json['experience'] ?? '',
      daysPerWeek: json['daysPerWeek'] ?? 0,
      equipment: List<String>.from(json['equipment'] ?? []),
      targetMuscles: List<String>.from(json['targetMuscles'] ?? []),
      duration: json['duration'] ?? 60,
      days: (json['days'] as List?)
              ?.map((day) => WorkoutDay.fromJson(day))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      plan: json['plan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'experience': experience,
      'daysPerWeek': daysPerWeek,
      'equipment': equipment,
      'targetMuscles': targetMuscles,
      'duration': duration,
      'days': days.map((day) => day.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      if (plan != null) 'plan': plan,
    };
  }
}

class WorkoutDay {
  final int dayNumber;
  final String focus;
  final List<Exercise> exercises;
  final int estimatedDuration;

  WorkoutDay({
    required this.dayNumber,
    required this.focus,
    required this.exercises,
    required this.estimatedDuration,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dayNumber: json['dayNumber'] ?? 0,
      focus: json['focus'] ?? '',
      exercises: (json['exercises'] as List?)
              ?.map((ex) => Exercise.fromJson(ex))
              .toList() ??
          [],
      estimatedDuration: json['estimatedDuration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'focus': focus,
      'exercises': exercises.map((ex) => ex.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
    };
  }
}

class Exercise {
  final String name;
  final String muscleGroup;
  final String? equipment;
  final int sets;
  final int reps;
  final int? restSeconds;
  final String? notes;
  final String? gifUrl; // Exercise demonstration GIF

  Exercise({
    required this.name,
    required this.muscleGroup,
    this.equipment,
    required this.sets,
    required this.reps,
    this.restSeconds,
    this.notes,
    this.gifUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      muscleGroup: json['muscleGroup'] ?? '',
      equipment: json['equipment'],
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      restSeconds: json['restSeconds'],
      notes: json['notes'],
      gifUrl: json['gifUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'notes': notes,
      if (gifUrl != null) 'gifUrl': gifUrl,
    };
  }
}
