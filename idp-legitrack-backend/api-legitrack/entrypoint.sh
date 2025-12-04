#!/bin/bash
set -e

echo "🔄 Aguardando o banco de dados estar pronto..."

# Aguarda o PostgreSQL estar disponível
until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
  echo "⏳ PostgreSQL não está disponível ainda - aguardando..."
  sleep 2
done

echo "✅ PostgreSQL está pronto!"

# Se for o container api (não worker), executa migrations e seed
if [ "$1" = "python" ] && [ "$2" = "app.py" ]; then
  echo "🔄 Executando migrations..."
  flask db upgrade || echo "⚠️  Migrations falharam ou já estão aplicadas"

  echo "🌱 Populando banco de dados..."
  python -m app.seed || echo "⚠️  Seed falhou ou já está populado"
fi

# Executa o comando passado como argumento
exec "$@"
