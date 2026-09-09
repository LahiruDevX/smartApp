import '../../core/network/api_client.dart';

class AuthService {
  AuthService(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await api.post(
      '/api/auth/login',
      {
        'email': email.trim(),
        'password': password,
      },
    );

    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response format from server');
    }

    final token = res['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Authentication token was not provided by server');
    }

    await api.saveToken(token);

    final user = res['user'] as Map<String, dynamic>?;
    if (user != null) {
      api.setCurrentUser(user);
    } else {
      // Fallback
      api.setCurrentUser({
        'email': email,
        'role': email.contains('admin') ? 'admin' : (email.contains('teacher') ? 'teacher' : 'student'),
      });
    }

    return user ?? api.currentUser!;
  }

  Future<void> logout() async {
    await api.logout();
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    try {
      final res = await api.getAuthed('/api/auth/me');
      if (res is Map && res['user'] is Map<String, dynamic>) {
        final user = res['user'] as Map<String, dynamic>;
        api.setCurrentUser(user);
        return user;
      }
    } catch (_) {
      // ignore
    }
    return api.currentUser;
  }
}
