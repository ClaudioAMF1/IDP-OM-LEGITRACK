class ApiConfig {
  // URL base da API
  // Para desenvolvimento local: use 'http://10.0.2.2:5000' para Android Emulator
  // ou 'http://localhost:5000' para Web/Desktop
  // ou o IP da sua máquina para dispositivos físicos (ex: 'http://192.168.1.100:5000')
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Endpoints de autenticação
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/registrar';
  static const String meEndpoint = '/auth/me';

  // Endpoints de projetos
  static const String projetosEndpoint = '/api/projetos';
  static String projetoDetalheEndpoint(int id) => '/api/projetos/$id';

  // Endpoints de favoritos
  static const String favoritosEndpoint = '/api/favoritos';
  static String favoritarEndpoint(int id) => '/api/favoritar/$id';

  // Endpoints de interesses (temas)
  static const String temasEndpoint = '/api/temas';
  static const String usuarioInteressesEndpoint = '/api/usuario/interesses';

  // Endpoints de notificações
  static const String notificacoesEndpoint = '/api/notificacoes';
  static String marcarNotificacaoLidaEndpoint(int id) =>
      '/api/notificacoes/$id/ler';

  // Configurações de timeout
  static const Duration timeout = Duration(seconds: 30);

  // Headers padrão
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers com autenticação
  static Map<String, String> headersWithAuth(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
