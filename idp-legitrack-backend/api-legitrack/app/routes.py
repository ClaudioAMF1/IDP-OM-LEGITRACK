from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy.orm import joinedload
from .extensions import db
from .models import TB_Projeto, TP_Temas, TB_Interesses, TB_User, RL_Favoritos, TB_Notificacao

bp = Blueprint('api', __name__, url_prefix='/api')

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

def _montar_json_projeto(projeto, user_favoritos_ids):
    """
    Padroniza o objeto JSON do projeto para o Flutter.
    """
    return {
        "id": str(projeto.id_projeto),
        "titulo": projeto.titulo_projeto,
        "descricao": projeto.descricao,
        "status": projeto.ultima_situacao.ds_situacao if projeto.ultima_situacao else "Em tramitação",
        "data": projeto.data_hora.strftime("%d de %b. de %Y") if projeto.data_hora else "",
        "is_favorite": projeto.id_projeto in user_favoritos_ids
    }

# ============================================================================
# ROTAS DE PROJETOS (HOME & BUSCA)
# ============================================================================

@bp.route("/projetos", methods=["POST"])
@jwt_required()
def listar_projetos():
    """
    Lista projetos filtrados
    ---
    tags:
      - Projetos
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: false
        schema:
          type: object
          properties:
            ids_temas:
              type: array
              items:
                type: integer
              description: Lista de IDs de temas para filtrar
            busca:
              type: string
              description: Termo para busca textual
    responses:
      200:
        description: Lista de projetos retornada com sucesso
      500:
        description: Erro interno
    """
    current_user_id = int(get_jwt_identity())
    dados = request.get_json() or {}
    
    ids_temas = dados.get('ids_temas', [])
    termo_busca = dados.get('busca', '')

    try:
        query = db.select(TB_Projeto).options(
            joinedload(TB_Projeto.ultima_situacao),
            joinedload(TB_Projeto.ultima_tramitacao)
        )

        if termo_busca:
            t = f"%{termo_busca}%"
            query = query.filter(
                (TB_Projeto.titulo_projeto.ilike(t)) | 
                (TB_Projeto.descricao.ilike(t))
            )

        if ids_temas and isinstance(ids_temas, list):
            query = query.filter(TB_Projeto.temas.any(TP_Temas.id_tema.in_(ids_temas)))

        query = query.order_by(TB_Projeto.data_hora.desc().nullslast())
        
        projetos_encontrados = db.session.scalars(query.limit(50)).unique().all()

        favoritos_query = db.select(RL_Favoritos.id_projeto).filter_by(id_user=current_user_id)
        meus_favoritos_ids = set(db.session.scalars(favoritos_query).all())

        projetos_json = [
            _montar_json_projeto(p, meus_favoritos_ids) 
            for p in projetos_encontrados
        ]

        return jsonify(projetos_json), 200

    except Exception as e:
        print(f"ERRO: {e}")
        return jsonify({"erro": "Erro ao buscar projetos"}), 500

@bp.route("/projetos/<int:id_projeto>", methods=["GET"])
@jwt_required()
def detalhes_projeto(id_projeto):
    """
    Obtém detalhes de um projeto específico
    ---
    tags:
      - Projetos
    security:
      - Bearer: []
    parameters:
      - name: id_projeto
        in: path
        type: integer
        required: true
        description: ID do projeto na Câmara
    responses:
      200:
        description: Detalhes do projeto
      404:
        description: Projeto não encontrado
    """
    current_user_id = int(get_jwt_identity())
    
    projeto = db.session.get(TB_Projeto, id_projeto)
    if not projeto:
        return jsonify({"erro": "Projeto não encontrado"}), 404

    is_fav = db.session.query(RL_Favoritos).filter_by(
        id_user=current_user_id, id_projeto=id_projeto
    ).first() is not None

    timeline = []
    for tram in projeto.tramitacoes: 
        timeline.append({
            "data": tram.data_hora.strftime("%d de %b. de %Y"),
            "titulo": tram.situacao.ds_situacao if tram.situacao else "Tramitação",
            "orgao": "Câmara dos Deputados",
            "descricao": tram.tipo_tramitacao.ds_tramitacao if tram.tipo_tramitacao else ""
        })

    return jsonify({
        "id": str(projeto.id_projeto),
        "titulo": projeto.titulo_projeto,
        "descricao": projeto.descricao,
        "status": projeto.ultima_situacao.ds_situacao if projeto.ultima_situacao else "",
        "data": projeto.data_hora.strftime("%d de %b. de %Y"),
        "is_favorite": is_fav,
        "timeline": timeline
    }), 200

# ============================================================================
# ROTAS DE FAVORITOS
# ============================================================================

@bp.route("/favoritos", methods=["GET"])
@jwt_required()
def listar_favoritos():
    """
    Lista os favoritos do usuário logado
    ---
    tags:
      - Favoritos
    security:
      - Bearer: []
    responses:
      200:
        description: Lista de projetos favoritos
    """
    current_user_id = int(get_jwt_identity())
    
    favoritos = db.session.scalars(
        db.select(RL_Favoritos).filter_by(id_user=current_user_id)
        .options(joinedload(RL_Favoritos.projeto))
    ).all()

    projetos_json = []
    for fav in favoritos:
        if fav.projeto:
            p_json = _montar_json_projeto(fav.projeto, {fav.projeto.id_projeto})
            projetos_json.append(p_json)

    return jsonify(projetos_json), 200

@bp.route("/favoritar/<int:id_projeto>", methods=["POST"])
@jwt_required()
def toggle_favorito(id_projeto):
    """
    Adiciona ou remove um projeto dos favoritos
    ---
    tags:
      - Favoritos
    security:
      - Bearer: []
    parameters:
      - name: id_projeto
        in: path
        type: integer
        required: true
    responses:
      200:
        description: Status atualizado (is_favorite true/false)
      404:
        description: Projeto não encontrado
    """
    current_user_id = int(get_jwt_identity())
    
    projeto = db.session.get(TB_Projeto, id_projeto)
    if not projeto:
        return jsonify({"erro": "Projeto inválido"}), 404

    existente = db.session.query(RL_Favoritos).filter_by(
        id_user=current_user_id, id_projeto=id_projeto
    ).first()

    if existente:
        db.session.delete(existente)
        msg = "Removido dos favoritos"
        is_favorite = False
    else:
        novo = RL_Favoritos(id_user=current_user_id, id_projeto=id_projeto)
        db.session.add(novo)
        msg = "Adicionado aos favoritos"
        is_favorite = True
    
    db.session.commit()
    return jsonify({"mensagem": msg, "is_favorite": is_favorite}), 200

# ============================================================================
# ROTAS DE INTERESSES
# ============================================================================

@bp.route("/temas", methods=["GET"])
def listar_temas():
    """
    Lista todos os temas disponíveis (Público)
    ---
    tags:
      - Interesses
    responses:
      200:
        description: Lista de temas com ID e Label
    """
    temas = db.session.scalars(db.select(TP_Temas).order_by(TP_Temas.ds_tema)).all()
    lista = [{"id": t.id_tema, "label": t.ds_tema} for t in temas]
    return jsonify(lista), 200

@bp.route("/usuario/interesses", methods=["GET", "POST"])
@jwt_required()
def gerenciar_interesses():
    """
    Gerencia os interesses do usuário
    ---
    tags:
      - Interesses
    security:
      - Bearer: []
    get:
      summary: Retorna os temas que o usuário segue
      responses:
        200:
          description: Lista de nomes de temas
    post:
      summary: Atualiza a lista de temas do usuário
      parameters:
        - name: body
          in: body
          required: true
          schema:
            type: object
            properties:
              temas:
                type: array
                items:
                  type: string
                description: 'Lista de NOMES dos temas. Exemplo: ["Saúde", "Educação"]' 
      responses:
        200:
          description: Sucesso
    """
    current_user_id = int(get_jwt_identity())

    if request.method == "GET":
        interesses = db.session.scalars(
            db.select(TB_Interesses).filter_by(id_user=current_user_id)
            .options(joinedload(TB_Interesses.tema))
        ).all()
        nomes_temas = [i.tema.ds_tema for i in interesses if i.tema]
        return jsonify(nomes_temas), 200

    if request.method == "POST":
        data = request.get_json()
        nomes_temas_recebidos = data.get('temas', [])

        try:
            db.session.query(TB_Interesses).filter_by(id_user=current_user_id).delete()
            
            if nomes_temas_recebidos:
                temas_db = db.session.scalars(
                    db.select(TP_Temas).filter(TP_Temas.ds_tema.in_(nomes_temas_recebidos))
                ).all()

                for tema in temas_db:
                    novo = TB_Interesses(id_user=current_user_id, id_interesse=tema.id_tema)
                    db.session.add(novo)
            
            db.session.commit()
            return jsonify({"mensagem": "Interesses atualizados"}), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({"erro": str(e)}), 500

# ============================================================================
# ROTAS DE NOTIFICAÇÕES
# ============================================================================

@bp.route("/notificacoes", methods=["GET"])
@jwt_required()
def listar_notificacoes():
    """
    Lista notificações do usuário
    ---
    tags:
      - Notificações
    security:
      - Bearer: []
    responses:
      200:
        description: Lista de notificações
    """
    current_user_id = int(get_jwt_identity())
    
    notificacoes = db.session.scalars(
        db.select(TB_Notificacao)
        .filter_by(id_user=current_user_id)
        .order_by(TB_Notificacao.data_hora.desc())
    ).all()

    resp = []
    for n in notificacoes:
        resp.append({
            "id": n.id,
            "title": n.titulo,
            "description": n.descricao,
            "date": n.data_hora.strftime("%d de %b. de %Y"),
            "isUnread": not n.lida
        })
    
    return jsonify(resp), 200

@bp.route("/notificacoes/<int:id_notificacao>/ler", methods=["POST"])
@jwt_required()
def marcar_notificacao_lida(id_notificacao):
    """
    Marca uma notificação como lida
    ---
    tags:
      - Notificações
    security:
      - Bearer: []
    parameters:
      - name: id_notificacao
        in: path
        type: integer
        required: true
    responses:
      200:
        description: Sucesso
    """
    current_user_id = int(get_jwt_identity())
    
    notificacao = db.session.get(TB_Notificacao, id_notificacao)
    
    if notificacao and notificacao.id_user == current_user_id:
        notificacao.lida = True
        db.session.commit()
        return jsonify({"ok": True}), 200
        
    return jsonify({"erro": "Notificação não encontrada"}), 404