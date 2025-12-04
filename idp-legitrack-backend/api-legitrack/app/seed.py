import time
import requests
from datetime import datetime, timedelta
from . import create_app, db
from .models import (
    TP_Situacao, TP_Tramitacao, TP_Temas, TB_Projeto, RL_Tramitacoes,
    TB_User, TB_Notificacao
)
from sqlalchemy.exc import OperationalError
from sqlalchemy import text
from urllib.parse import urlparse, parse_qs

app = create_app()
app.app_context().push()

def wait_for_db():
    print("SEEDER: Aguardando o banco de dados ficar pronto...")
    retries = 0
    max_retries = 10
    while retries < max_retries:
        try:
            db.session.execute(text('SELECT 1'))
            print("SEEDER: Conexão com o banco de dados estabelecida!")
            return True
        except OperationalError:
            retries += 1
            wait_time = 5
            print(f"SEEDER: Banco ainda não está pronto. Tentando novamente em {wait_time}s... (Tentativa {retries}/{max_retries})")
            time.sleep(wait_time)
        except Exception as e:
            print(f"SEEDER: Erro inesperado ao esperar pelo banco: {e}")
            retries += 1
            time.sleep(5)
            
    print(f"SEEDER: ERRO CRÍTICO! Não foi possível conectar ao banco após {max_retries} tentativas. Encerrando.")
    return False

def sicronizar_tabelas_tp(url, model_class, id_field_name, ds_field_name, api_id_key, api_desc_key):
    tabela_nome = model_class.__tablename__
    print(f"SEEDER: Iniciando sicronização da tabela '{tabela_nome}'...")
    
    try:
        resposta = requests.get(url, timeout=10)
        resposta.raise_for_status()
        dados_api = resposta.json().get('dados', {})

        if not dados_api:
            print(f"SEEDER: Nenhum dado recebido da API para '{tabela_nome}'. Pulando.")
            return
        
        itens_locais = model_class.query.all()
        mapa_itens_locais = {getattr(item, id_field_name): item for item in itens_locais}
        print(f"SEEDER: {len(mapa_itens_locais)} itens existem localmente em '{tabela_nome}'.")

        itens_para_salvar = []
        itens_atualizados = 0
        itens_novos = 0

        #Comparação
        for item_api in dados_api:
            try:
                if not isinstance(item_api, dict):
                    continue

                id_api_str = item_api.get(api_id_key)
                desc_api = item_api.get(api_desc_key)

                if not id_api_str or not desc_api:
                    continue

                id_api = int(id_api_str)
                item_local = mapa_itens_locais.get(id_api) 

                if item_local: #Se já está no banco, atualiza se necessário
                    if getattr(item_local, ds_field_name) != desc_api:
                        setattr(item_local, ds_field_name, desc_api)
                        itens_para_salvar.append(item_local)
                        itens_atualizados += 1
                else: #Se não está no banco, insere
                    novo_item_args = {id_field_name: id_api, ds_field_name: desc_api}
                    novo_item = model_class(**novo_item_args)
                    itens_para_salvar.append(novo_item)
                    itens_novos += 1
                
            except (AttributeError, ValueError, TypeError) as e:
                print(f"SEEDER: [AVISO] ERRO em item individual (API enviou lixo? {item_api}). Erro: {e}. Pulando item.")
                continue

        if itens_para_salvar:
            print(f"SEEDER: {itens_novos} itens novos, {itens_atualizados} itens atualizados para '{tabela_nome}'. Salvando...")
            try:
                db.session.add_all(itens_para_salvar)
                db.session.commit()
                print(f"SEEDER: Sincronização de '{tabela_nome}' completa.")
            except Exception as e:
                db.session.rollback()
                print(f"SEEDER: [ERRO] ERRO ao salvar no banco para '{tabela_nome}': {e}")
        else:
            print(f"SEEDER: Tabela '{tabela_nome}' já está atualizada.")

    except requests.exceptions.RequestException as e:
        print(f"SEEDER: [ERRO] ERRO DE REDE GERAL ao buscar '{tabela_nome}': {e}")
    except Exception as e:
        print(f"SEEDER: [ERRO] ERRO INESPERADO (fora do loop) ao sicronizar '{tabela_nome}': {e}")
        db.session.rollback()

def processar_pagina_de_projetos(projetos_desta_pagina):
    """
    Recebe uma lista de projetos (1 página) e salva
    todos eles (Projeto, Tramitações, Temas) no banco.
    """
    projetos_atualizados = 0
    projetos_novos = 0
    novas_tramitacoes_total = 0

    if not projetos_desta_pagina:
        return 0, 0, 0

    for projeto_resumido in projetos_desta_pagina:
        id_api = None
        try:
            id_api_str = projeto_resumido.get('id')
            if not id_api_str:
                print(f"SEEDER (Projetos): [AVISO] Item de projeto resumido sem ID. Pulando item.")
                continue
            
            id_api = int(id_api_str)
            projeto_db = db.session.get(TB_Projeto, id_api)

            if not projeto_db:
                projeto_db = TB_Projeto(id_projeto=id_api)
                db.session.add(projeto_db)
                projetos_novos += 1
            else:
                projetos_atualizados += 1

            projeto_db.titulo_projeto = projeto_resumido.get('ementa')
            projeto_db.descricao = f"{projeto_resumido.get('siglaTipo')} {projeto_resumido.get('numero')}/{projeto_resumido.get('ano')}"
            projeto_db.ano_inicio = str(projeto_resumido.get('ano'))

            sequencias_existentes = {t.sequencia for t in projeto_db.tramitacoes}
            url_tram = f"https://dadosabertos.camara.leg.br/api/v2/proposicoes/{id_api}/tramitacoes"
            resposta_tram = requests.get(url_tram, timeout=10)
            resposta_tram.raise_for_status()
            tramitacoes_api = resposta_tram.json().get('dados', [])

            novas_tramitacoes_para_salvar = []
            
            if not tramitacoes_api:
                pass # Silencioso para não poluir log
            else:
                for item_tram_api in tramitacoes_api:
                    try:
                        if not isinstance(item_tram_api, dict):
                            continue
                        
                        seq_api = int(item_tram_api['sequencia'])
                        
                        if seq_api not in sequencias_existentes:
                            nova_tram = RL_Tramitacoes(
                                id_projeto = id_api,
                                sequencia = seq_api,
                                data_hora = datetime.fromisoformat(item_tram_api['dataHora']),
                                id_situacao = int(item_tram_api['codSituacao']),
                                id_tramitacao = int(item_tram_api['codTipoTramitacao'])
                            )
                            novas_tramitacoes_para_salvar.append(nova_tram)
                            
                    except (ValueError, TypeError, KeyError, AttributeError):
                        pass # Silencioso

                if novas_tramitacoes_para_salvar:
                    db.session.add_all(novas_tramitacoes_para_salvar)
                    novas_tramitacoes_total += len(novas_tramitacoes_para_salvar)

                ultimo_status = tramitacoes_api[-1]
                try:
                    projeto_db.data_hora = datetime.fromisoformat(ultimo_status.get("dataHora"))
                    projeto_db.sigla_orgao = ultimo_status.get("siglaOrgao")
                    projeto_db.despacho = ultimo_status.get("despacho")
                    projeto_db.id_ultima_situacao = int(ultimo_status.get("codSituacao"))
                    projeto_db.id_ultima_tramitacao = int(ultimo_status.get("codTipoTramitacao"))
                except (ValueError, TypeError):
                     pass

            resposta_tema = requests.get(f'https://dadosabertos.camara.leg.br/api/v2/proposicoes/{id_api}/temas', timeout=10)
            resposta_tema.raise_for_status()
            projeto_temas_api = resposta_tema.json().get("dados", [])

            if projeto_temas_api:
                temas_existentes_ids = {tema.id_tema for tema in projeto_db.temas}
                for tema_api in projeto_temas_api:
                    try:
                        if not isinstance(tema_api, dict):
                           continue
                        
                        id_tema_api = int(tema_api.get('cod'))
                        if id_tema_api not in temas_existentes_ids:
                            tema_db = db.session.get(TP_Temas, id_tema_api)
                            if tema_db:
                                projeto_db.temas.append(tema_db)
                    except (ValueError, TypeError, KeyError, AttributeError):
                        pass

            db.session.commit()
            
        except Exception as e:
            print(f"SEEDER (Projetos): [ERRO CRÍTICO] Falha ao processar projeto {id_api}: {e}")
            db.session.rollback()

    return projetos_novos, projetos_atualizados, novas_tramitacoes_total

def get_total_pages():
    try:
        url = 'https://dadosabertos.camara.leg.br/api/v2/proposicoes?pagina=1&itens=1&ordem=ASC&ordenarPor=id'
        print(f"SEEDER: Verificando número total de páginas em: {url}")
        
        resposta = requests.get(url, timeout=10)
        resposta.raise_for_status()
        links_da_api = resposta.json().get('links', [])
        
        for link in links_da_api:
            if link.get('rel') == 'last':
                last_link_href = link.get('href')
                query_params = parse_qs(urlparse(last_link_href).query)
                total_paginas = int(query_params['pagina'][0])
                return total_paginas
                
    except Exception as e:
        print(f"SEEDER: [ERRO CRÍTICO] Não foi possível obter o total de páginas: {e}")
        return None

def seed_dados_teste():
    """Cria usuário admin e notificações fake para testes no app"""
    print("\nSEEDER (Dados de Teste): Verificando usuário 'admin'...")
    
    # 1. Cria Usuário Admin
    admin_user = TB_User.query.filter_by(email="admin@legitrack.com").first()
    if not admin_user:
        admin_user = TB_User(username="Admin Legitrack", email="admin@legitrack.com")
        admin_user.set_password("1234") # Senha fácil para testes
        db.session.add(admin_user)
        db.session.commit()
        print("SEEDER (Dados de Teste): Usuário 'admin@legitrack.com' (senha: 1234) CRIADO.")
    else:
        print("SEEDER (Dados de Teste): Usuário 'admin' já existe.")

    # 2. Cria Notificações Fake
    print("SEEDER (Dados de Teste): Gerando notificações falsas...")
    
    # Limpa anteriores para não duplicar muito
    db.session.query(TB_Notificacao).filter_by(id_user=admin_user.id).delete()
    
    notificacoes = [
        TB_Notificacao(
            id_user=admin_user.id,
            titulo="PL 2338/2023 Avançou!",
            descricao="O Marco Legal da IA teve uma nova movimentação importante no Senado.",
            lida=False, # Vai aparecer com bolinha vermelha
            data_hora=datetime.now() - timedelta(hours=2)
        ),
        TB_Notificacao(
            id_user=admin_user.id,
            titulo="Nova Tramitação em Saúde",
            descricao="Um projeto de seu interesse na área de Saúde foi aprovado na comissão.",
            lida=True,
            data_hora=datetime.now() - timedelta(days=1)
        ),
        TB_Notificacao(
            id_user=admin_user.id,
            titulo="Bem-vindo ao Legitrack",
            descricao="Configure seus interesses para receber atualizações personalizadas.",
            lida=True,
            data_hora=datetime.now() - timedelta(days=5)
        )
    ]
    
    db.session.add_all(notificacoes)
    db.session.commit()
    print("SEEDER (Dados de Teste): 3 Notificações inseridas com sucesso.")


if __name__ == "__main__":
    
    if not wait_for_db():
        exit(1)

    print(f"\n--- [SEED SCRIPT]: {datetime.now()} - INICIANDO CARGA INICIAL ---")
    
    print("\n" + "="*30 + " FASE 1: METADADOS (TP) " + "="*30)
    sicronizar_tabelas_tp(
        url="https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codSituacao",
        model_class=TP_Situacao, id_field_name="id_situacao", ds_field_name="ds_situacao",
        api_id_key="cod", api_desc_key="nome"
    )
    sicronizar_tabelas_tp(
        url="https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codTipoTramitacao",
        model_class=TP_Tramitacao, id_field_name="id_tramitacao", ds_field_name="ds_tramitacao",
        api_id_key="cod", api_desc_key="nome"
    )
    sicronizar_tabelas_tp(
        url="https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codTema",
        model_class=TP_Temas, id_field_name="id_tema", ds_field_name="ds_tema",
        api_id_key="cod", api_desc_key="nome"
    )

    print("\n" + "="*30 + " FASE 2: DADOS DE TESTE (USER/NOTIF) " + "="*30)
    seed_dados_teste()
    
    print("\n" + "="*30 + " FASE 3: PROJETOS (INTERATIVO) " + "="*30)
    
    # Pergunta se quer rodar a carga pesada de projetos
    escolha = input("Deseja buscar projetos na API da Câmara agora? (s/n): ")
    
    if escolha.lower() == 's':
        total_paginas = get_total_pages()
        if total_paginas:
            print(f"SEEDER: Total de páginas disponíveis: {total_paginas}")
            try:
                pagina_inicio = int(input(f"Página INICIAL (ex: 1): "))
                pagina_fim = int(input(f"Página FINAL (ex: 5): "))
                
                if pagina_fim > total_paginas: pagina_fim = total_paginas
                if pagina_inicio < 1: pagina_inicio = 1
                
                print(f"\nSEEDER: Processando {pagina_inicio} até {pagina_fim}...")
                
                for pagina_atual in range(pagina_inicio, pagina_fim + 1):
                    url = f"https://dadosabertos.camara.leg.br/api/v2/proposicoes?pagina={pagina_atual}&itens=100&ordem=ASC&ordenarPor=id"
                    print(f"--- Processando Página {pagina_atual} ---")
                    try:
                        resp = requests.get(url, timeout=20)
                        resp.raise_for_status()
                        pn, pa, tn = processar_pagina_de_projetos(resp.json().get('dados', []))
                        print(f"Status: {pn} novos, {tn} tramitações.")
                        time.sleep(1)
                    except Exception as e:
                        print(f"Erro na pág {pagina_atual}: {e}")

            except ValueError:
                print("Entrada inválida.")
    else:
        print("SEEDER: Pulei a busca de projetos. O banco está pronto com metadados e usuário de teste.")
            
    print(f"\n--- [SEED SCRIPT]: CONCLUÍDO ---")