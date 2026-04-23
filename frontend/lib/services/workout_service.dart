import '../config/api_config.dart';
import '../models/workout.dart';
import '../models/workout_stats.dart';
import 'api_service.dart';

/// Workout Service
/// Handles all workout-related API calls
class WorkoutService {
  final ApiService _apiService;
  
  WorkoutService(this._apiService);
  
  /// Get all workouts for the current user
  Future<List<Workout>> getWorkouts() async {
    try {
      final response = await _apiService.get(ApiConfig.workoutEndpoint);
      
      // Backend returns: {success: true, data: {workouts: [...]}}
      final List<dynamic> workoutsJson = response.data['data']?['workouts'] ?? response.data['workouts'] ?? response.data;
      return workoutsJson.map((json) => Workout.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch workouts: $e');
    }
  }
  
  /// Get a specific workout by ID
  Future<Workout> getWorkout(String id) async {
    try {
      final response = await _apiService.get('${ApiConfig.workoutEndpoint}/$id');
      final workoutData = response.data['data']?['workout'] ?? response.data['workout'] ?? response.data;
      return Workout.fromJson(workoutData);
    } catch (e) {
      throw Exception('Failed to fetch workout: $e');
    }
  }
  
  /// Create a new workout
  Future<Workout> createWorkout(Workout workout) async {
    try {
      final response = await _apiService.post(ApiConfig.workoutEndpoint, workout.toJson());
      
      // Backend returns: {success: true, data: {workout: {...}}}
      final workoutData = response.data['data']?['workout'] ?? response.data['workout'] ?? response.data;
      return Workout.fromJson(workoutData);
    } catch (e) {
      throw Exception('Failed to create workout: $e');
    }
  }
  
  /// Create a new workout from parameters
  Future<Workout> createWorkoutFromParams({
    required String exerciseName,
    required String workoutType,
    required int duration,
    required double caloriesBurned,
    DateTime? date,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
    String intensityLevel = 'moderate',
  }) async {
    final workout = Workout(
      userId: 'current_user', // Will be set by backend from token
      exerciseName: exerciseName,
      workoutType: workoutType,
      duration: duration,
      caloriesBurned: caloriesBurned,
      date: date ?? DateTime.now(),
      sets: sets,
      reps: reps,
      weight: weight,
      notes: notes,
      intensityLevel: intensityLevel,
      createdAt: DateTime.now(),
    );
    
    return createWorkout(workout);
  }
  
  /// Update an existing workout
  Future<Workout> updateWorkout(String id, Workout workout) async {
    try {
      final response = await _apiService.put('${ApiConfig.workoutEndpoint}/$id', workout.toJson());
      
      final workoutData = response.data['data']?['workout'] ?? response.data['workout'] ?? response.data;
      return Workout.fromJson(workoutData);
    } catch (e) {
      throw Exception('Failed to update workout: $e');
    }
  }
  
  /// Delete a workout
  Future<void> deleteWorkout(String id) async {
    try {
      await _apiService.delete('${ApiConfig.workoutEndpoint}/$id');
    } catch (e) {
      throw Exception('Failed to delete workout: $e');
    }
  }
  
  /// Get workout statistics
  Future<WorkoutStats> getStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final response = await _apiService.get(
        ApiConfig.workoutStatsEndpoint,
        queryParameters: queryParams,
      );
      
      return WorkoutStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch workout stats: $e');
    }
  }
}
