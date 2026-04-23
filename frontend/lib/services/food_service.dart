import 'package:dio/dio.dart';
import '../models/food.dart';
import 'api_service.dart';

class FoodService {
  final ApiService _apiService;

  FoodService(this._apiService);

  /// Search for foods by name with autocomplete support (optimized)
  Future<List<Food>> searchFoods(String searchQuery, {String? category}) async {
    try {
      final queryParams = {
        'q': searchQuery,
        'limit': 20,
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _apiService.get(
        '/foods/search?${_buildQueryString(queryParams)}',
      );

      if (response.statusCode == 200) {
        final foods = (response.data['foods'] as List)
            .map((f) => Food.fromJson(f as Map<String, dynamic>))
            .toList();
        return foods;
      }
      return [];
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }

  /// Get all foods in a category
  Future<List<Food>> getFoodsByCategory(String category) async {
    try {
      final response = await _apiService.get('/foods?category=$category&limit=100');

      if (response.statusCode == 200) {
        final foods = (response.data['foods'] as List)
            .map((f) => Food.fromJson(f as Map<String, dynamic>))
            .toList();
        return foods;
      }
      return [];
    } catch (e) {
      print('Error fetching foods by category: $e');
      return [];
    }
  }

  /// Get all available foods
  Future<List<Food>> getAllFoods() async {
    try {
      final response = await _apiService.get('/foods?limit=500');

      if (response.statusCode == 200) {
        final foods = (response.data['foods'] as List)
            .map((f) => Food.fromJson(f as Map<String, dynamic>))
            .toList();
        return foods;
      }
      return [];
    } catch (e) {
      print('Error fetching all foods: $e');
      return [];
    }
  }

  String _buildQueryString(Map<String, dynamic> params) {
    return params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&');
  }
}
