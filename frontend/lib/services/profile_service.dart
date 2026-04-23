import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user_profile.dart';
import 'api_service.dart';

class ProfileService extends ChangeNotifier {
  ProfileService(this._apiService);

  final ApiService _apiService;
  bool _isLoading = false;
  UserProfile? _profile;
  MacroCalculations? _calculations;

  bool get isLoading => _isLoading;
  UserProfile? get profile => _profile;
  MacroCalculations? get calculations => _calculations;

  Future<void> fetchProfile() async {
    if (_apiService.token == null) {
      _profile = null;
      _calculations = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/profile');
      final data = response.data as Map<String, dynamic>;
      final profileJson = data['profile'] as Map<String, dynamic>?;
      final calcJson = data['calculations'] as Map<String, dynamic>?;

      _profile = profileJson == null ? null : UserProfile.fromJson(profileJson);
      _calculations = calcJson == null
          ? null
          : MacroCalculations.fromJson(calcJson);
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put('/profile', profile.toJson());
      final data = response.data as Map<String, dynamic>;
      _profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
      _calculations = MacroCalculations.fromJson(
        data['calculations'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractDioMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Cannot connect to backend server.';
    }

    return error.message ?? 'Profile request failed.';
  }
}
