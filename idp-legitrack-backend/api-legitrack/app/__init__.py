from flask import Flask
from .extensions import db, jwt, swagger, migrate, cors
import os
from dotenv import load_dotenv

def create_app():
    app = Flask(__name__)

    # Carrega variáveis de ambiente do arquivo .env
    load_dotenv()

    # Configurações do Banco de Dados
    db_host = os.getenv('DB_HOST', 'db')
    db_port = os.getenv('DB_PORT', '5432')
    db_user = os.getenv('DB_USER', 'user')
    db_password = os.getenv('DB_PASSWORD', 'password')
    db_name = os.getenv('DB_NAME', 'legitrack_db')

    database_uri = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'

    app.config['SQLALCHEMY_DATABASE_URI'] = database_uri
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'fallback-secret-key-change-this')

    # Configuração do CORS - Permite requisições do frontend
    app.config['CORS_HEADERS'] = 'Content-Type'
    cors_origins = os.getenv('CORS_ORIGINS', '*')

    # Configuração do Swagger
    app.config['SWAGGER'] = {
        'title': 'Legitrack API',
        'uiversion': 3,
        'description': 'API para monitoramento de projetos de lei da Câmara dos Deputados'
    }

    # Inicializa as extensões com o app configurado
    db.init_app(app)
    jwt.init_app(app)
    swagger.init_app(app)
    migrate.init_app(app, db)

    # Configura CORS com as origens do .env
    if cors_origins == '*':
        cors.init_app(app, resources={r"/*": {"origins": "*"}})
    else:
        origins_list = [origin.strip() for origin in cors_origins.split(',')]
        cors.init_app(app, resources={r"/*": {"origins": origins_list}})

    # Registra as rotas
    with app.app_context():
        try:
            # Importar rotas aqui para registrar Blueprints
            from .routes import bp as main_bp
            from .auth import bp as auth_bp

            app.register_blueprint(main_bp)
            app.register_blueprint(auth_bp)

            print("✅ Blueprints registrados com sucesso")
        except Exception as e:
            print(f"❌ Erro ao registrar blueprints: {e}")
            raise

    return app