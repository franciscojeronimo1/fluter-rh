import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/auth_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyToken = 'auth_token';
const String _keyUser = 'auth_user';

class AuthService {
  AuthService({ApiClient? apiClient})
      : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// Realiza login e persiste token e usuário.
  /// Lança [Exception] com mensagem do backend em caso de erro.
  Future<AuthResponse> login(String email, String password) async {
    final res = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final message = body?['error'] as String? ?? 'Erro no login';
      throw Exception(message);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final auth = AuthResponse.fromJson(data);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, auth.token);
    await prefs.setString(_keyUser, jsonEncode({
      'id': auth.user.id,
      'name': auth.user.name,
      'email': auth.user.email,
      'role': auth.user.role,
      'organizationId': auth.user.organizationId,
    }));

    return auth;
  }

  /// Retorna o token salvo ou null se não houver sessão.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Retorna o usuário salvo (após login) ou null.
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyUser);
    if (json == null) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    return User.fromJson(map);
  }

  /// Remove token e usuário (logout).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  /// Indica se há um token salvo (usuário logado).
  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
