import 'api_service.dart';

class AuthService {
  AuthService(this._apiService);

  final ApiService _apiService;
  String? _email;
  bool _isEmailVerified = false;

  bool get isLoggedIn => _email != null;
  bool get isEmailVerified => _isEmailVerified;
  String get userEmail => _email ?? 'guest@nutripal.app';

  // =============== EMAIL/PASSWORD LOGIN ===============

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.length < 6) return null;
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      final user =
          (data['user'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      if (token.isEmpty) return null;

      _apiService.setToken(token);
      _email = (user['email'] ?? email).toString();
      _isEmailVerified = user['isEmailVerified'] ?? false;

      return user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // =============== EMAIL/PASSWORD REGISTRATION ===============

  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty || email.isEmpty || password.length < 6) return null;
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      final user =
          (data['user'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      if (token.isEmpty) return null;

      final devVerificationToken = (data['devVerificationToken'] ?? '')
          .toString();
      if (devVerificationToken.isNotEmpty) {
        user['devVerificationToken'] = devVerificationToken;
      }

      _apiService.setToken(token);
      _email = (user['email'] ?? email).toString();
      _isEmailVerified = user['isEmailVerified'] ?? false;

      return user;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // =============== EMAIL VERIFICATION ===============

  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _apiService.post('/auth/verify-email', {
        'token': token,
      });
      _isEmailVerified = true;
      return true;
    } catch (e) {
      print('Email verification error: $e');
      return false;
    }
  }

  Future<bool?> checkEmailVerificationStatus() async {
    try {
      final response = await _apiService.get('/auth/me');
      final data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final user =
          (data['user'] ?? <String, dynamic>{}) as Map<String, dynamic>;

      if (user.isEmpty) return null;

      final resolvedEmail = (user['email'] ?? '').toString();
      if (resolvedEmail.isNotEmpty) {
        _email = resolvedEmail;
      }
      _isEmailVerified = user['isEmailVerified'] == true;

      return _isEmailVerified;
    } catch (e) {
      print('Check verification status error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> resendVerificationEmail(String email) async {
    try {
      final response = await _apiService.post(
        '/auth/resend-verification-email',
        {'email': email},
      );
      final data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final devVerificationToken = (data['devVerificationToken'] ?? '')
          .toString();

      return {'ok': true, 'devVerificationToken': devVerificationToken};
    } catch (e) {
      print('Resend verification error: $e');
      return null;
    }
  }

  // =============== GOOGLE OAUTH ===============

  Future<Map<String, dynamic>?> loginWithGoogle({
    required String googleId,
    required String email,
    required String name,
    String? profilePictureUrl,
  }) async {
    try {
      final response = await _apiService.post('/auth/google', {
        'googleId': googleId,
        'email': email,
        'name': name,
        'profilePictureUrl': profilePictureUrl,
      });

      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      final user =
          (data['user'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      if (token.isEmpty) return null;

      _apiService.setToken(token);
      _email = (user['email'] ?? email).toString();
      _isEmailVerified =
          user['isEmailVerified'] ?? true; // Google auto-verifies

      return user;
    } catch (e) {
      print('Google login error: $e');
      return null;
    }
  }

  // =============== PASSWORD RESET ===============

  Future<bool> forgotPassword(String email) async {
    try {
      await _apiService.post('/auth/forgot-password', {'email': email});
      return true;
    } catch (e) {
      print('Forgot password error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      await _apiService.post('/auth/reset-password', {
        'token': token,
        'newPassword': newPassword,
      });
      return true;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  // =============== LOGOUT ===============

  void logout() {
    _apiService.setToken(null);
    _email = null;
    _isEmailVerified = false;
  }
}
