from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from .extensions import db
from .models import TB_User

bp = Blueprint('auth', __name__, url_prefix='/auth')

@bp.route('/registrar', methods=['POST'])
def registrar():
    """
    Registra um novo usuário
    ---
    tags:
      - Autenticação
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            username:
              type: string
            email:
              type: string
            password:
              type: string
    responses:
      201:
        description: Usuário criado com sucesso
      409:
        description: Usuário já existente
    """
    data = request.get_json()
    
    # Verifica se usuário ou email já existem
    if TB_User.query.filter((TB_User.username == data.get("username")) | (TB_User.email == data.get("email"))).first():
        return jsonify({"error": "Usuário ou Email já cadastrados"}), 409

    user = TB_User(username=data["username"], email=data["email"])
    user.set_password(data["password"])
    
    try:
        db.session.add(user)
        db.session.commit()
        return jsonify({"message": "Usuário criado com sucesso"}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "Erro ao criar usuário"}), 500

@bp.route('/login', methods=['POST'])
def login():
    """
    Login de usuário e geração de Token JWT
    ---
    tags:
      - Autenticação
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            email:
              type: string
            password:
              type: string
    responses:
      200:
        description: Token gerado com sucesso
      401:
        description: Credenciais inválidas
    """
    data = request.get_json()
    user = TB_User.query.filter_by(email=data.get("email")).first()

    if user and user.check_password(data.get("password")):
        # Cria o token JWT. A 'identity' é o ID do usuário (string)
        access_token = create_access_token(identity=str(user.id))
        
        return jsonify({
            "access_token": access_token,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email
            }
        }), 200

    return jsonify({"error": "Email ou senha inválidos"}), 401

@bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """
    Retorna os dados do usuário logado (usado na tela de Perfil)
    ---
    tags:
      - Autenticação
    security:
      - Bearer: []
    responses:
      200:
        description: Dados do usuário
      404:
        description: Usuário não encontrado
    """
    current_user_id = get_jwt_identity()
    user = db.session.get(TB_User, int(current_user_id))
    
    if not user:
        return jsonify({"error": "Usuário não encontrado"}), 404
    
    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "criado_em": user.criado_em.isoformat()
    }), 200