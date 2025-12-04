import time
import requests
from datetime import datetime
from . import create_app, db
from .models import TP_Situacao, TP_Tramitacao, TP_Temas, TB_Projeto, RL_Tramitacoes
from sqlalchemy.exc import OperationalError
from sqlalchemy import text

app = create_app()
app.app_context().push()

# ============================================================================
# FUNÇÕES DE SUPORTE
# ============================================================================

def wait_for_db():
    print("SEEDER_RECENT: Aguardando o banco de dados ficar pronto...")
    retries = 0
    max_retries = 10
    while retries < max_retries:
        try:
            db.session.execute(text('SELECT 1'))
            print("SEEDER_RECENT: Conexão com o banco de dados estabelecida!")
            return True
        except OperationalError:
            retries += 1
            wait_time = 5
            print(f"SEEDER_RECENT: Banco ainda não está pronto. Tentando novamente em {wait_time}s... (Tentativa {retries}/{max_retries})")
            time.sleep(wait_time)
        except Exception as e:
            print(f"SEEDER_RECENT: Erro inesperado ao esperar pelo banco: {e}")
            retries += 1
            time.sleep(5)
            
    print(f"SEEDER_RECENT: ERRO CRÍTICO! Não foi possível conectar ao banco. Encerrando.")
    return False

def sicronizar_tabelas_tp(url, model_class, id_field_name, ds_field_name, api_id_key, api_desc_key):
    """
    Sincroniza tabelas de domínio (TP_Situacao, TP_Tema, etc)
    necessárias antes de inserir projetos.
    """
    tabela_nome = model_class.__tablename__
    print(f"SEEDER_RECENT: Sincronizando tabela '{tabela_nome}'...")
    
    try:
        resposta = requests.get(url, timeout=10)
        resposta.raise_for_status()
        dados_api = resposta.json().get('dados', {})

        if not dados_api:
            return
        
        # Carrega ids existentes em memória para evitar queries desnecessárias
        itens_locais = db.session.scalars(db.select(model_class)).all()
        mapa_itens_locais = {getattr(item, id_field_name): item for item in itens_locais}

        itens_para_salvar = []

        for item_api in dados_api:
            try:
                if not isinstance(item_api, dict): continue
                
                id_api = int(item_api.get(api_id_key))
                desc_api = item_api.get(api_desc_key)

                if not id_api or not desc_api: continue

                item_local = mapa_itens_locais.get(id_api) 

                if item_local: 
                    if getattr(item_local, ds_field_name) != desc_api:
                        setattr(item_local, ds_field_name, desc_api)
                        itens_para_salvar.append(item_local)
                else:
                    novo_item_args = {id_field_name: id_api, ds_field_name: desc_api}
                    novo_item = model_class(**novo_item_args)
                    itens_para_salvar.append(novo_item)
                
            except Exception:
                continue

        if itens_para_salvar:
            db.session.add_all(itens_para_salvar)
            db.session.commit()
            print(f"SEEDER_RECENT: '{tabela_nome}' atualizada com {len(itens_para_salvar)} registros.")
        else:
            print(f"SEEDER_RECENT: '{tabela_nome}' já está atualizada.")

    except Exception as e:
        print(f"SEEDER_RECENT: [ERRO] Falha ao sincronizar '{tabela_nome}': {e}")
        db.session.rollback()

# ============================================================================
# LÓGICA PRINCIPAL DE PROJETOS
# ============================================================================

def sicronizar_projetos_por_ano(ano_selecionado):
    todos_projetos = []
    MAX_TENTATIVAS = 3
    
    # URL base filtrando por ano(s)
    url = (
        f"https://dadosabertos.camara.leg.br/api/v2/proposicoes"
        f"?{ano_selecionado}"
        f"&pagina=1&itens=100&ordem=ASC&ordenarPor=id"
    )

    print(f"SEEDER_RECENT: Iniciando busca de projetos para: {ano_selecionado}...")

    # 1. Paginação: Busca TODOS os resumos primeiro
    while url:
        print(f"SEEDER_RECENT: Baixando página: {url}")
        
        sucesso = False
        for tentativa in range(MAX_TENTATIVAS):
            try:
                resposta = requests.get(url, timeout=20)
                resposta.raise_for_status()
                sucesso = True
                break
            except Exception as e:
                print(f"SEEDER_RECENT: [ERRO REDE] Tentativa {tentativa+1} falhou: {e}")
                time.sleep(2)
        
        if not sucesso:
            print("SEEDER_RECENT: Falha crítica ao buscar página. Abortando.")
            break
            
        dados_api = resposta.json()
        projetos_pag = dados_api.get('dados', [])
        links = dados_api.get('links', [])

        if not projetos_pag:
            break

        todos_projetos.extend(projetos_pag)

        # Próxima página
        novo_url = None
        for link in links:
            if link.get('rel') == 'next':
                novo_url = link.get('href')
                break
        url = novo_url
        time.sleep(0.5) # Delay leve para ser gentil com a API
    
    if not todos_projetos:
        print("SEEDER_RECENT: Nenhum projeto encontrado.")
        return

    print(f"SEEDER_RECENT: Total de {len(todos_projetos)} projetos encontrados. Iniciando detalhamento...")

    # 2. Detalhamento: Busca detalhes, tramitações e temas para cada um
    count_novos = 0
    count_atualizados = 0

    for i, resumo in enumerate(todos_projetos):
        if (i + 1) % 50 == 0:
            print(f"SEEDER_RECENT: Processando {i+1}/{len(todos_projetos)}...")

        try:
            id_api = int(resumo.get('id'))
            
            # Verifica/Cria Projeto
            projeto = db.session.get(TB_Projeto, id_api)
            if not projeto:
                projeto = TB_Projeto(id_projeto=id_api)
                db.session.add(projeto)
                count_novos += 1
            else:
                count_atualizados += 1

            # Atualiza dados básicos
            projeto.titulo_projeto = resumo.get('ementa')
            projeto.descricao = f"{resumo.get('siglaTipo')} {resumo.get('numero')}/{resumo.get('ano')}"
            projeto.ano_inicio = str(resumo.get('ano'))

            # A. Busca Tramitações
            url_tram = f"https://dadosabertos.camara.leg.br/api/v2/proposicoes/{id_api}/tramitacoes"
            try:
                resp_tram = requests.get(url_tram, timeout=10)
                if resp_tram.ok:
                    trams = resp_tram.json().get('dados', [])
                    seqs_existentes = {t.sequencia for t in projeto.tramitacoes}
                    
                    for t in trams:
                        seq = int(t['sequencia'])
                        if seq not in seqs_existentes:
                            nova = RL_Tramitacoes(
                                id_projeto=id_api,
                                sequencia=seq,
                                data_hora=datetime.fromisoformat(t['dataHora']),
                                id_situacao=int(t['codSituacao']),
                                id_tramitacao=int(t['codTipoTramitacao'])
                            )
                            db.session.add(nova)
                    
                    # Atualiza status final do projeto baseado na última tramitação
                    if trams:
                        ult = trams[-1]
                        projeto.data_hora = datetime.fromisoformat(ult['dataHora'])
                        projeto.sigla_orgao = ult.get('siglaOrgao')
                        projeto.despacho = ult.get('despacho')
                        projeto.id_ultima_situacao = int(ult.get('codSituacao'))
                        projeto.id_ultima_tramitacao = int(ult.get('codTipoTramitacao'))

            except Exception as e:
                print(f"SEEDER_RECENT: Erro ao buscar tramitações do projeto {id_api}: {e}")

            # B. Busca Temas
            url_tema = f"https://dadosabertos.camara.leg.br/api/v2/proposicoes/{id_api}/temas"
            try:
                resp_tema = requests.get(url_tema, timeout=10)
                if resp_tema.ok:
                    temas_api = resp_tema.json().get('dados', [])
                    temas_ids_proj = {tema.id_tema for tema in projeto.temas}
                    
                    for t_api in temas_api:
                        tid = int(t_api['cod'])
                        if tid not in temas_ids_proj:
                            tema_db = db.session.get(TP_Temas, tid)
                            if tema_db:
                                projeto.temas.append(tema_db)
            except Exception:
                pass

            # Commit a cada projeto para salvar progresso
            db.session.commit()

        except Exception as e:
            db.session.rollback()
            print(f"SEEDER_RECENT: Erro crítico no projeto {resumo.get('id')}: {e}")

    print(f"\nSEEDER_RECENT: Finalizado! {count_novos} novos, {count_atualizados} atualizados.")

# ============================================================================
# EXECUÇÃO
# ============================================================================

if __name__ == "__main__":
    if not wait_for_db():
        exit(1)

    print("\n--- [SEEDER RECENT]: ATUALIZAÇÃO POR ANO ---")
    
    # 1. Garante que os metadados existam (senão dá erro de FK)
    sicronizar_tabelas_tp(
        "https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codSituacao",
        TP_Situacao, "id_situacao", "ds_situacao", "cod", "nome"
    )
    sicronizar_tabelas_tp(
        "https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codTipoTramitacao",
        TP_Tramitacao, "id_tramitacao", "ds_tramitacao", "cod", "nome"
    )
    sicronizar_tabelas_tp(
        "https://dadosabertos.camara.leg.br/api/v2/referencias/proposicoes/codTema",
        TP_Temas, "id_tema", "ds_tema", "cod", "nome"
    )

    # 2. Pergunta os anos
    try:
        print("\nDigite os anos que deseja baixar (separados por vírgula).")
        print("Exemplo: '2024' ou '2023,2024'")
        entrada = input("Anos: ")
        
        if entrada.strip():
            # Converte "2023, 2024" em "ano=2023&ano=2024"
            anos = [f"ano={a.strip()}" for a in entrada.split(',')]
            query_anos = "&".join(anos)
            
            sicronizar_projetos_por_ano(query_anos)
        else:
            print("Nenhum ano informado.")
            
    except KeyboardInterrupt:
        print("\nCancelado pelo usuário.")