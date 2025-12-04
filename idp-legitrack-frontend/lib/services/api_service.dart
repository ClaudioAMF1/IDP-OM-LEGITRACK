import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _authService = AuthService();

  // Helper para obter headers com autenticação
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }
    return ApiConfig.headersWithAuth(token);
  }

  // ========== PROJETOS ==========

  /// Lista projetos com filtros opcionais
  Future<Map<String, dynamic>> listarProjetos({
    List<int>? idsTemas,
    String? busca,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{};

      if (idsTemas != null && idsTemas.isNotEmpty) {
        body['ids_temas'] = idsTemas;
      }
      if (busca != null && busca.isNotEmpty) {
        body['busca'] = busca;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projetosEndpoint}'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar projetos',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Obter detalhes de um projeto específico
  Future<Map<String, dynamic>> obterDetalhesProjeto(int idProjeto) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projetoDetalheEndpoint(idProjeto)}'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar detalhes do projeto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // ========== FAVORITOS ==========

  /// Listar favoritos do usuário
  Future<Map<String, dynamic>> listarFavoritos() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favoritosEndpoint}'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar favoritos',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Toggle favorito (adiciona ou remove)
  Future<Map<String, dynamic>> toggleFavorito(int idProjeto) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favoritarEndpoint(idProjeto)}'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao favoritar/desfavoritar projeto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // ========== TEMAS/INTERESSES ==========

  /// Listar todos os temas disponíveis
  Future<Map<String, dynamic>> listarTemas() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.temasEndpoint}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar temas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Obter interesses do usuário
  Future<Map<String, dynamic>> obterInteressesUsuario() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioInteressesEndpoint}'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar interesses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Atualizar interesses do usuário
  Future<Map<String, dynamic>> atualizarInteresses(List<int> idsTemas) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioInteressesEndpoint}'),
            headers: headers,
            body: jsonEncode({'ids_temas': idsTemas}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao atualizar interesses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // ========== NOTIFICAÇÕES ==========

  /// Listar notificações do usuário
  Future<Map<String, dynamic>> listarNotificacoes() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificacoesEndpoint}'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar notificações',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Marcar notificação como lida
  Future<Map<String, dynamic>> marcarNotificacaoLida(int idNotificacao) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.marcarNotificacaoLidaEndpoint(idNotificacao)}'),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao marcar notificação como lida',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}
