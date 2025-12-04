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

    app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
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
        origins_list = cors_origins.split(',')
        cors.init_app(app, resources={r"/*": {"origins": origins_list}})

    with app.app_context():
        # Importar rotas aqui para registrar Blueprints
        from .routes import bp as main_bp
        from .auth import bp as auth_bp 

        app.register_blueprint(main_bp)
        app.register_blueprint(auth_bp)

        # NÃO descomente o db.create_all() se estiver usando migrations.
        # As tabelas serão criadas pelo 'flask db upgrade'.
        # db.create_all() 

    return app