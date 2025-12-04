import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';

  String? _cachedToken;
  Map<String, dynamic>? _cachedUser;

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Armazena o token e dados do usuário
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _userIdKey, value: data['user']['id'].toString());
        await _storage.write(key: _usernameKey, value: data['user']['username']);
        await _storage.write(key: _emailKey, value: data['user']['email']);

        _cachedToken = data['token'];
        _cachedUser = data['user'];

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Erro ao fazer login'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e'
      };
    }
  }

  // Registro
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Erro ao registrar'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e'
      };
    }
  }

  // Obter dados do usuário logado
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meEndpoint}'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedUser = data;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Obter token armazenado
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  // Verificar se está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Obter dados do usuário em cache
  Future<Map<String, dynamic>?> getCachedUser() async {
    if (_cachedUser != null) return _cachedUser;

    final userId = await _storage.read(key: _userIdKey);
    final username = await _storage.read(key: _usernameKey);
    final email = await _storage.read(key: _emailKey);

    if (userId != null && username != null && email != null) {
      _cachedUser = {
        'id': int.parse(userId),
        'username': username,
        'email': email,
      };
      return _cachedUser;
    }

    return null;
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
    _cachedToken = null;
    _cachedUser = null;
  }
}
