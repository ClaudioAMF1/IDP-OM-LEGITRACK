import time
import requests
from datetime import datetime, timedelta
from sqlalchemy import text
from sqlalchemy.exc import OperationalError
from . import create_app, db
from .models import (
    TP_Situacao, TP_Tramitacao, TB_Projeto, RL_Tramitacoes, TB_Notificacao, RL_Favoritos
)

app = create_app()
app.app_context().push()

# ============================================================================
# FUNÇÕES DE SUPORTE
# ============================================================================

def wait_for_db():
    print("WORKER: Aguardando o banco de dados ficar pronto...")
    retries = 0
    max_retries = 10
    while retries < max_retries:
        try:
            db.session.execute(text('SELECT 1'))
            print("WORKER: Conexão com o banco de dados estabelecida!")
            return True
        except OperationalError:
            retries += 1
            time.sleep(5)
        except Exception as e:
            print(f"WORKER: Erro: {e}")
            retries += 1
            time.sleep(5)
            
    print(f"WORKER: ERRO CRÍTICO! Sem conexão com banco.")
    return False

def sicronizar_tabelas_tp(url, model_class, id_field_name, ds_field_name, api_id_key, api_desc_key):
    """Sincroniza tabelas de domínio (Metadados)"""
    tabela_nome = model_class.__tablename__
    # print(f"WORKER: Checando '{tabela_nome}'...") # Log reduzido para não poluir
    
    try:
        resposta = requests.get(url, timeout=10)
        if not resposta.ok: return

        dados_api = resposta.json().get('dados', [])
        if not dados_api: return
        
        # Carrega dados locais para comparação rápida
        itens_locais = db.session.scalars(db.select(model_class)).all()
        mapa_locais = {getattr(i, id_field_name): i for i in itens_locais}
        
        novos = []

        for item in dados_api:
            try:
                if not isinstance(item, dict): continue
                uid = int(item.get(api_id_key))
                desc = item.get(api_desc_key)
                
                if uid not in mapa_locais:
                    args = {id_field_name: uid, ds_field_name: desc}
                    novos.append(model_class(**args))
            except: continue

        if novos:
            db.session.add_all(novos)
            db.session.commit()
            print(f"WORKER: '{tabela_nome}' atualizada: +{len(novos)} itens.")

    except Exception as e:
        db.session.rollback()
        print(f"WORKER: Erro ao sync '{tabela_nome}': {e}")

# ============================================================================
# SINCRONIZAÇÃO DE PROJETOS E NOTIFICAÇÕES
# ============================================================================

def gerar_notificacao_mudanca(projeto, nova_tramitacao):
    """
    Verifica quem favoritou este projeto e cria notificação
    """
    try:
        # Busca IDs dos usuários que favoritaram este projeto
        favoritos = db.session.scalars(
            db.select(RL_Favoritos).filter_by(id_projeto=projeto.id_projeto)
        ).all()
        
        notificacoes = []
        for fav in favoritos:
            titulo = f"Movimentação: {projeto.titulo_projeto[:30]}..."
            desc = f"Nova tramitação: {nova_tramitacao.situacao.ds_situacao if nova_tramitacao.situacao else 'Atualização'}"
            
            notif = TB_Notificacao(
                id_user=fav.id_user,
                id_projeto=projeto.id_projeto,
                titulo=titulo,
                descricao=desc,
                lida=False
            )
            notificacoes.append(notif)
        
        if notificacoes:
            db.session.add_all(notificacoes)
            # O commit acontece no loop principal
            print(f"WORKER: 🔔 {len(notificacoes)} notificações geradas para o projeto {projeto.id_projeto}")

    except Exception as e:
        print(f"WORKER: Erro ao gerar notificação: {e}")

def sicronizar_projetos(tempo_de_espera):
    """Busca projetos alterados no intervalo de tempo"""
    
    # Define janela de busca (últimos X minutos + margem)
    dt_fim = datetime.now()
    dt_inicio = dt_fim - timedelta(seconds=tempo_de_espera + 300) # +5min de margem
    
    url = (
        f"https://dadosabertos.camara.leg.br/api/v2/proposicoes"
        f"?dataInicio={dt_inicio.strftime('%Y-%m-%d')}"
        f"&dataFim={dt_fim.strftime('%Y-%m-%d')}"
        f"&pagina=1&itens=100&ordem=ASC&ordenarPor=id"
    )

    print(f"WORKER: Buscando atualizações de projetos ({dt_inicio.strftime('%H:%M')} - {dt_fim.strftime('%H:%M')})...")
    
    todos_resumos = []
    
    # 1. Paginação da Busca
    while url:
        try:
            resp = requests.get(url, timeout=10)
            if not resp.ok: break
            
            dados = resp.json()
            todos_resumos.extend(dados.get('dados', []))
            
            url = next((link['href'] for link in dados.get('links', []) if link['rel'] == 'next'), None)
            time.sleep(0.5)
        except: break

    if not todos_resumos:
        print("WORKER: Nenhuma alteração recente encontrada na Câmara.")
        return

    print(f"WORKER: {len(todos_resumos)} projetos com movimentação recente. Analisando...")

    # 2. Processamento Detalhado
    cnt_novos = 0
    cnt_atualizados = 0

    for resumo in todos_resumos:
        try:
            pid = int(resumo['id'])
            projeto = db.session.get(TB_Projeto, pid)
            eh_novo = False

            if not projeto:
                projeto = TB_Projeto(id_projeto=pid)
                db.session.add(projeto)
                eh_novo = True
                cnt_novos += 1
            else:
                cnt_atualizados += 1

            # Atualiza dados básicos
            projeto.titulo_projeto = resumo.get('ementa')
            projeto.descricao = f"{resumo.get('siglaTipo')} {resumo.get('numero')}/{resumo.get('ano')}"
            projeto.ano_inicio = str(resumo.get('ano'))

            # Busca Tramitações (Para detectar mudanças)
            resp_tram = requests.get(f"https://dadosabertos.camara.leg.br/api/v2/proposicoes/{pid}/tramitacoes", timeout=10)
            if resp_tram.ok:
                trams = resp_tram.json().get('dados', [])
                seqs_existentes = {t.sequencia for t in projeto.tramitacoes}
                
                novas_trams_objs = []
                for t in trams:
                    seq = int(t['sequencia'])
                    if seq not in seqs_existentes:
                        nova = RL_Tramitacoes(
                            id_projeto=pid,
                            sequencia=seq,
                            data_hora=datetime.fromisoformat(t['dataHora']),
                            id_situacao=int(t['codSituacao']),
                            id_tramitacao=int(t['codTipoTramitacao'])
                        )
                        db.session.add(nova)
                        novas_trams_objs.append(nova)
                
                # SE TIVER TRAMITAÇÃO NOVA E NÃO FOR PROJETO NOVO, NOTIFICA!
                if novas_trams_objs and not eh_novo:
                    # Pega a mais recente para notificar
                    ultima = novas_trams_objs[-1]
                    # Necessário flush para garantir que a tramitação tenha IDs para relacionamento
                    db.session.flush() 
                    gerar_notificacao_mudanca(projeto, ultima)

                # Atualiza status final
                if trams:
                    ult = trams[-1]
                    projeto.data_hora = datetime.fromisoformat(ult['dataHora'])
                    projeto.id_ultima_situacao = int(ult['codSituacao'])
                    projeto.id_ultima_tramitacao = int(ult['codTipoTramitacao'])

            db.session.commit()

        except Exception as e:
            db.session.rollback()
            print(f"WORKER: Erro no projeto {resumo.get('id')}: {e}")

    print(f"WORKER: Ciclo fim. {cnt_novos} novos, {cnt_atualizados} atualizados.")

# ============================================================================
# LOOP PRINCIPAL
# ============================================================================

if __name__ == "__main__":
    # Intervalo de busca (em segundos). 
    # Câmara não atualiza tão rápido, 10 min (600s) é saudável.
    INTERVALO = 600 

    if not wait_for_db():
        exit(1)

    print(f"WORKER: Iniciando monitoramento (Intervalo: {INTERVALO}s)")

    while True:
        # 1. Sync Tabelas Auxiliares
        sicronizar_tabelas_tp(
            "https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codSituacao",
            TP_Situacao, "id_situacao", "ds_situacao", "cod", "nome"
        )
        sicronizar_tabelas_tp(
            "https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codTipoTramitacao",
            TP_Tramitacao, "id_tramitacao", "ds_tramitacao", "cod", "nome"
        )
        
        # 2. Sync Projetos e Gera Notificações
        sicronizar_projetos(INTERVALO)
        
        print(f"WORKER: Dormindo...")
        time.sleep(INTERVALO)