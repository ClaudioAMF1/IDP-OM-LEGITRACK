import os
from sqlalchemy import create_engine, text

# Pega a URL do ambiente ou usa a default do Docker
# Importante: O host 'db' é o nome do serviço no docker-compose
DB_URI = os.getenv('SQLALCHEMY_DATABASE_URI', 'postgresql://user:password@db:5432/legitrack_db')

def create_schemas():
    # Cria a engine de conexão direta (sem passar pelo Flask app context)
    engine = create_engine(DB_URI)

    try:
        with engine.connect() as conn:
            with conn.begin():
                # Schema para dados legislativos (Projetos, Tramitações, Temas)
                conn.execute(text("CREATE SCHEMA IF NOT EXISTS camara"))
                print('✅ Schema "camara" criado/verificado!')
                
                # Schema para dados de usuários (Login, Favoritos, Notificações)
                conn.execute(text("CREATE SCHEMA IF NOT EXISTS usuarios"))
                print('✅ Schema "usuarios" criado/verificado!')
                
                # (Opcional) Schema para expansão futura
                conn.execute(text("CREATE SCHEMA IF NOT EXISTS senado"))
                print('✅ Schema "senado" criado/verificado!')
                
    except Exception as e:
        print(f"❌ Erro crítico ao criar schemas: {e}")
        # Não damos exit(1) aqui para não quebrar o container inteiro se for apenas um erro de conexão temporário

if __name__ == "__main__":
    print("--- [SCHEMA CREATOR] INICIANDO ---")
    create_schemas()
    print("--- [SCHEMA CREATOR] CONCLUÍDO ---")