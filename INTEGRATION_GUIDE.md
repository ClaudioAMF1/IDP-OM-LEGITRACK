# Guia de Integração Backend-Frontend LegiTrack

Este guia explica como o backend e frontend estão integrados e como executar o projeto completo.

## 📋 Resumo da Integração

O projeto LegiTrack foi integrado com sucesso! Agora o frontend Flutter se conecta ao backend Flask através de uma API REST completa.

### ✅ O que foi implementado:

#### Backend (Flask)
- ✅ Configuração de CORS para permitir requisições do frontend
- ✅ Arquivo `.env` para configurações (banco de dados, JWT, etc.)
- ✅ API REST completa com endpoints para:
  - Autenticação (login, registro, perfil)
  - Projetos de lei (listagem, detalhes, busca)
  - Favoritos (adicionar/remover)
  - Interesses/Temas (listar, atualizar preferências)
  - Notificações (listar, marcar como lida)

#### Frontend (Flutter)
- ✅ Dependências HTTP instaladas (`http`, `flutter_secure_storage`, `shared_preferences`)
- ✅ Configuração de API (`api_config.dart`)
- ✅ Serviço de Autenticação (`auth_service.dart`)
- ✅ Serviço de API (`api_service.dart`)
- ✅ Integração completa em todas as telas:
  - Tela de Login
  - Tela de Registro
  - Tela de Interesses (com carregamento dinâmico de temas)
  - Tela Home (com projetos do backend)
  - Tela de Favoritos
  - Tela de Notificações

## 🚀 Como Executar o Projeto

### 1. Executar o Backend

#### Opção A: Com Docker (Recomendado)

```bash
# IMPORTANTE: Navegue para o diretório correto
cd idp-legitrack-backend/api-legitrack

# Inicie os containers
docker-compose up -d

# Aguarde alguns segundos para o banco de dados inicializar

# Execute as migrations (primeira vez apenas)
docker-compose exec api flask db upgrade

# Verifique se está rodando
docker-compose ps
```

O backend estará disponível em: `http://localhost:5000`

Para ver os logs:
```bash
docker-compose logs -f api
```

Para parar os containers:
```bash
docker-compose down
```

#### Opção B: Sem Docker

```bash
cd idp-legitrack-backend/api-legitrack

# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt

# Configurar banco de dados
flask db upgrade

# Executar servidor
python app.py
```

### 2. Executar o Frontend

#### Para Android Emulator:

```bash
cd idp-legitrack-frontend

# Instalar dependências
flutter pub get

# Executar no emulador
flutter run
```

**Importante:** O emulador Android usa `10.0.2.2` para acessar o localhost da máquina host. A configuração já está correta em `lib/config/api_config.dart`.

#### Para Web:

```bash
cd idp-legitrack-frontend

# Atualizar a URL da API em lib/config/api_config.dart
# Trocar de: static const String baseUrl = 'http://10.0.2.2:5000';
# Para: static const String baseUrl = 'http://localhost:5000';

flutter run -d chrome
```

#### Para dispositivo físico:

1. Descubra o IP da sua máquina na rede local (ex: `192.168.1.100`)
2. Atualize em `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:5000';
   ```
3. Execute: `flutter run`

## 🔧 Configurações Importantes

### Backend - Arquivo .env

O arquivo `.env` está em `idp-legitrack-backend/api-legitrack/.env`:

```env
# Configurações do Flask
FLASK_ENV=development
FLASK_DEBUG=True

# Banco de Dados
DB_HOST=db
DB_PORT=5432
DB_USER=user
DB_PASSWORD=password
DB_NAME=legitrack_db

# JWT Secret (MUDE EM PRODUÇÃO!)
JWT_SECRET_KEY=dev-secret-key-change-in-production-12345678

# CORS
CORS_ORIGINS=*
```

### Frontend - Configuração de API

O arquivo está em `idp-legitrack-frontend/lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Para Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Para Web/Desktop
  // static const String baseUrl = 'http://localhost:5000';

  // Para dispositivo físico
  // static const String baseUrl = 'http://SEU_IP:5000';
}
```

## 📡 Endpoints da API

### Autenticação
- `POST /auth/registrar` - Criar nova conta
- `POST /auth/login` - Fazer login
- `GET /auth/me` - Obter dados do usuário logado

### Projetos
- `POST /api/projetos` - Listar projetos (com filtros)
- `GET /api/projetos/<id>` - Detalhes de um projeto

### Favoritos
- `GET /api/favoritos` - Listar favoritos
- `POST /api/favoritar/<id>` - Adicionar/remover favorito

### Interesses
- `GET /api/temas` - Listar todos os temas
- `GET /api/usuario/interesses` - Interesses do usuário
- `POST /api/usuario/interesses` - Atualizar interesses

### Notificações
- `GET /api/notificacoes` - Listar notificações
- `POST /api/notificacoes/<id>/ler` - Marcar como lida

## 🔐 Autenticação

O sistema usa JWT (JSON Web Tokens) para autenticação:

1. Usuário faz login em `/auth/login`
2. Backend retorna um token JWT
3. Frontend armazena o token de forma segura usando `flutter_secure_storage`
4. Todas as requisições subsequentes incluem o header:
   ```
   Authorization: Bearer <token>
   ```

## 🐛 Resolução de Problemas

### Backend não inicia
- Verifique se o Docker está rodando
- Verifique se a porta 5000 está livre
- Verifique os logs: `docker-compose logs api`

### Frontend não conecta ao backend
- Verifique se o backend está rodando
- Verifique a URL em `api_config.dart`
- Para Android Emulator, use `10.0.2.2` ao invés de `localhost`
- Verifique se não há firewall bloqueando a conexão

### Erro de CORS
- Verifique se o backend tem CORS configurado
- Verifique o arquivo `.env` e a configuração de `CORS_ORIGINS`

### Token expirado
- Faça logout e login novamente
- O token JWT tem validade configurada no backend

## 📚 Documentação da API

Com o backend rodando, acesse:
- Swagger UI: `http://localhost:5000/`

## 🔄 Fluxo Completo da Aplicação

1. **Registro/Login**
   - Usuário se registra ou faz login
   - Backend retorna token JWT
   - Token é armazenado de forma segura

2. **Seleção de Interesses**
   - Frontend busca temas disponíveis do backend
   - Usuário seleciona seus interesses
   - Interesses são salvos no backend

3. **Tela Principal**
   - Frontend busca projetos filtrados pelos interesses do usuário
   - Projetos são exibidos na tela home
   - Usuário pode favoritar projetos

4. **Favoritos**
   - Toggle de favorito atualiza o backend
   - Lista de favoritos é sincronizada

5. **Notificações**
   - Backend envia notificações sobre mudanças nos projetos
   - Frontend exibe notificações
   - Usuário pode marcar como lida

## ✨ Melhorias Futuras

- [ ] Implementar refresh token
- [ ] Adicionar cache de requisições
- [ ] Implementar pull-to-refresh nas listas
- [ ] Adicionar tratamento de erros mais robusto
- [ ] Implementar loading states em todas as telas
- [ ] Adicionar testes automatizados

## 📝 Notas

- O projeto está configurado para desenvolvimento
- Em produção, altere as configurações de segurança
- Use HTTPS em produção
- Altere o `JWT_SECRET_KEY` para um valor forte
- Configure CORS adequadamente para permitir apenas origens confiáveis
