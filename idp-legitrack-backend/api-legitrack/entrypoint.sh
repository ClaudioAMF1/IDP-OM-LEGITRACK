#!/bin/bash
set -e

echo "🔄 Aguardando o banco de dados estar pronto..."

# Aguarda o PostgreSQL estar disponível
until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
  echo "⏳ PostgreSQL não está disponível ainda - aguardando..."
  sleep 2
done

echo "✅ PostgreSQL está pronto!"

# Executa o comando passado como argumento
exec "$@"
