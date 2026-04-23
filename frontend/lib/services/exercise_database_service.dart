import '../config/api_config.dart';
import 'api_service.dart';

/// Service to fetch exercise details from the database
class ExerciseDatabaseService {
  final ApiService _apiService;
  
  // Cache to avoid repeated API calls
  final Map<String, Map<String, dynamic>> _exerciseCache = {};
  
  ExerciseDatabaseService(this._apiService);
  
  /// Search for exercise details by name
  /// Returns exercise with GIF URL, instructions, etc.
  Future<Map<String, dynamic>?> getExerciseDetails(String exerciseName) async {
    // Check cache first
    final cacheKey = exerciseName.toLowerCase().trim();
    if (_exerciseCache.containsKey(cacheKey)) {
      return _exerciseCache[cacheKey];
    }
    
    try {
      final response = await _apiService.get(
        ApiConfig.exercisesSearchEndpoint,
        queryParameters: {'name': exerciseName},
      );
      
      if (response.data['success'] == true) {
        final exercise = response.data['data']['exercise'];
        _exerciseCache[cacheKey] = exercise;
        return exercise;
      }
      return null;
    } catch (e) {
      print('Error fetching exercise details: $e');
      return null;
    }
  }
  
  /// Clear the exercise cache
  void clearCache() {
    _exerciseCache.clear();
  }
}
