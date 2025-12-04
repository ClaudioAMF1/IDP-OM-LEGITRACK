FROM python:3.11

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala dependências do sistema necessárias para o PostgreSQL (psycopg2)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copia o arquivo de requisitos e instala as libs Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia todo o código do projeto para dentro do container
COPY . .

# Copia e torna o entrypoint executável
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expõe a porta 5000 (onde o Flask roda)
EXPOSE 5000

# Define o entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Comando padrão ao iniciar (pode ser sobrescrito pelo docker-compose)
CMD ["python", "app.py"]