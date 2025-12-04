from flask import Flask
from .extensions import db, jwt, swagger, migrate # <--- Adicione migrate

def create_app():
    app = Flask(__name__)

    # Configurações (Idealmente use variáveis de ambiente .env)
    # Nota: No Docker, o host do banco geralmente é o nome do serviço (ex: 'db')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@db:5432/legitrack_db'
    app.config['JWT_SECRET_KEY'] = 'sua-chave-super-secreta-mude-isso-em-producao'
    
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
    migrate.init_app(app, db) # <--- Adicionado: Habilita comandos 'flask db'

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