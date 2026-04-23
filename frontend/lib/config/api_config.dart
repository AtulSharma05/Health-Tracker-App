import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String appName = 'NutriPal';
  static const String appVersion = '1.0.0';
  static const String _devIp = '127.0.0.1';

  // Workout integration endpoints
  static const String workoutEndpoint = '/workouts';
  static const String workoutStatsEndpoint = '/workouts/stats';
  static const String workoutPlansGenerateEndpoint = '/workout-plans/generate';
  static const String workoutPlansRecommendEndpoint = '/workout-plans/recommend-exercises';
  static const String workoutPlansPredictEndpoint = '/workout-plans/predict-sets';
  static const String workoutPlansStatusEndpoint = '/workout-plans/status';
  static const String exercisesSearchEndpoint = '/exercises/search';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api/v1';
    }
    // Android emulator should use 10.0.2.2 to access host machine localhost.
    return 'http://10.0.2.2:4000/api/v1';
  }

  static String get localDeviceBaseUrl => 'http://$_devIp:4000/api/v1';

  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'ws://localhost:8001';
    }
    // Android emulator
    return 'ws://10.0.2.2:8001';
  }

  static String get poseWebSocketUrl {
    return '$wsBaseUrl/ws/pose-analysis';
  }
}
