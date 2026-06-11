import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class UserSession {
  final int? userId;
  final String? name;
  final String? email;
  final String? token;
  final String? avatarUrl;

  UserSession({this.userId, this.name, this.email, this.token, this.avatarUrl});

  bool get isAuthenticated => token != null;
}

class AuthNotifier extends StateNotifier<UserSession> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(UserSession());

  Future<bool> login(String email, String password) async {
    try {
      // For local testing without a live backend running:
      if (email == 'admin@kora.com' && password == 'password') {
        state = UserSession(userId: 1, name: 'Admin User', email: email, token: 'mock-jwt-token', avatarUrl: null);
        _apiClient.setToken('mock-jwt-token');
        return true;
      }

      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'];
        final userId = data['user']['id'];
        final userName = data['user']['name'];
        final avatarUrl = data['user']['avatar_url'];
        
        state = UserSession(userId: userId, name: userName, email: email, token: token, avatarUrl: avatarUrl);
        _apiClient.setToken(token);
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  void updateSession({required String name, required String email, String? avatarUrl}) {
    state = UserSession(
      userId: state.userId,
      name: name,
      email: email,
      token: state.token,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
  }

  Future<void> logout() async {
    state = UserSession();
    _apiClient.setToken(null);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, UserSession>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
