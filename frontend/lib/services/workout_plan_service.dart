import '../config/api_config.dart';
import '../models/workout_plan.dart';
import 'api_service.dart';

class WorkoutPlanService {
  final ApiService _apiService;

  WorkoutPlanService(this._apiService);

  /// Generate personalized workout plan
  Future<WorkoutPlan> generatePlan({
    required String goal,
    required String experience,
    required int daysPerWeek,
    List<String>? equipment,
    List<String>? targetMuscles,
    int? duration,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.workoutPlansGenerateEndpoint, {
        'goal': goal,
        'experience': experience,
        'daysPerWeek': daysPerWeek,
        'equipment': equipment ?? [],
        'targetMuscles': targetMuscles ?? [],
        'duration': duration ?? 60,
      });

      if (response.data['success'] == true) {
        return WorkoutPlan.fromJson(response.data['data']['plan']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to generate plan');
      }
    } catch (e) {
      throw Exception('Failed to generate workout plan: $e');
    }
  }

  /// Get exercise recommendations
  Future<List<Map<String, dynamic>>> getExerciseRecommendations({
    String? muscleGroup,
    List<String>? equipment,
    String? difficulty,
    int? limit,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.workoutPlansRecommendEndpoint, {
        'muscleGroup': muscleGroup,
        'equipment': equipment ?? [],
        'difficulty': difficulty,
        'limit': limit ?? 10,
      });

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          response.data['data']['exercises'] ?? [],
        );
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get recommendations');
      }
    } catch (e) {
      throw Exception('Failed to get exercise recommendations: $e');
    }
  }

  /// Check AI Planner service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final response = await _apiService.get(
        ApiConfig.workoutPlansStatusEndpoint,
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        return {'status': 'offline', 'message': 'Service unavailable'};
      }
    } catch (e) {
      return {'status': 'offline', 'message': 'Service unavailable'};
    }
  }
}
