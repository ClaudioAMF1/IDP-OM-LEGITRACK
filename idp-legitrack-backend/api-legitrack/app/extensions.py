from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flasgger import Swagger
from flask_migrate import Migrate # <--- Adicionado

# Inicializamos as extensões vazias aqui para evitar circular imports
db = SQLAlchemy()
jwt = JWTManager()
swagger = Swagger()
migrate = Migrate() # <--- Adicionado