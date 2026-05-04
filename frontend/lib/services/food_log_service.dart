import 'dart:convert';
import 'dart:typed_data';
import 'api_service.dart';

class FoodLogService {
  final ApiService _apiService;

  FoodLogService(this._apiService);

  /// Send image bytes to backend for AI food analysis.
  /// Returns a map with: foodName, calories, protein, carbs, fats, fiber,
  /// confidence, servingSize, ingredients.
  Future<Map<String, dynamic>> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final base64Image = base64Encode(imageBytes);

    final response = await _apiService.post('/food-log/analyze', {
      'imageBase64': base64Image,
      'mimeType': mimeType,
    });

    final data = response.data as Map<String, dynamic>;
    return data['analysis'] as Map<String, dynamic>;
  }

  /// Save the AI-analyzed (and possibly user-edited) result as a meal.
  Future<Map<String, dynamic>> saveAnalysis({
    required String foodName,
    required String mealType,
    required int calories,
    required int protein,
    required int carbs,
    required int fats,
    int fiber = 0,
    double confidence = 0,
  }) async {
    final response = await _apiService.post('/food-log/save', {
      'foodName': foodName,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'confidence': confidence,
    });

    return response.data as Map<String, dynamic>;
  }

  /// Get AI food log history.
  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _apiService.get('/food-log');
    final data = response.data as Map<String, dynamic>;
    final logs = (data['logs'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    return logs;
  }
}
