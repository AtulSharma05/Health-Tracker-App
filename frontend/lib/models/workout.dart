/// Workout Model - Matches backend schema
class Workout {
  final String? id;
  final String userId;
  final String exerciseName;
  final String workoutType;
  final int duration; // in minutes
  final double caloriesBurned;
  final DateTime date;
  final int? sets;
  final int? reps;
  final double? weight;
  final String? notes;
  final String intensityLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Workout({
    this.id,
    required this.userId,
    required this.exerciseName,
    required this.workoutType,
    required this.duration,
    required this.caloriesBurned,
    required this.date,
    this.sets,
    this.reps,
    this.weight,
    this.notes,
    this.intensityLevel = 'moderate',
    required this.createdAt,
    this.updatedAt,
  });
  
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      exerciseName: json['exerciseName'] ?? '',
      workoutType: json['workoutType'] ?? 'other',
      duration: json['duration'] ?? 0,
      caloriesBurned: (json['caloriesBurned'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight']?.toDouble(),
      notes: json['notes'],
      intensityLevel: json['intensityLevel'] ?? 'moderate',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      // userId is set by backend from auth token, not sent in request
      'exerciseName': exerciseName,
      'workoutType': workoutType,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'date': date.toIso8601String(),
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (notes != null) 'notes': notes,
      'intensityLevel': intensityLevel,
    };
  }
}
