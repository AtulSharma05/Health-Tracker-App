import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final Dio _dio;
  String? _token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);
  Future<Response<dynamic>> post(String path, Map<String, dynamic> data) => _dio.post(path, data: data);
  Future<Response<dynamic>> put(String path, Map<String, dynamic> data) => _dio.put(path, data: data);
  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}
