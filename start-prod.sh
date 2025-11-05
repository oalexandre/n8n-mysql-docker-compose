#!/bin/bash

# Script de inicialização para produção
# Este script garante que todas as pastas e permissões estejam corretas

set -e

echo "🚀 Iniciando n8n em modo PRODUÇÃO..."

# Detectar qual comando Docker Compose usar
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
    echo "ℹ️  Usando: docker-compose (standalone)"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
    echo "ℹ️  Usando: docker compose (Docker CLI plugin - recomendado)"
else
    echo "❌ Erro: Docker Compose não encontrado!"
    echo "   Instale o Docker Compose v2: https://docs.docker.com/compose/install/"
    exit 1
fi

# Verificar se .env existe
if [ ! -f .env ]; then
    echo "❌ Erro: Arquivo .env não encontrado!"
    echo "   Execute: cp .env.example .env"
    echo "   E configure as variáveis de produção"
    exit 1
fi

# Verificar variáveis importantes
source .env
if [ "$DOMAIN" == "exemplo.com" ]; then
    echo "⚠️  AVISO: Você está usando o domínio de exemplo!"
    echo "   Edite o arquivo .env e configure:"
    echo "   - DOMAIN=seudominio.com"
    echo "   - LETSENCRYPT_EMAIL=seu-email@exemplo.com"
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Criar pastas necessárias
echo "📁 Criando estrutura de pastas..."
mkdir -p docker_data/mysql
mkdir -p docker_data/n8n
mkdir -p docker_data/letsencrypt

# Ajustar ownership e permissões de forma segura
echo "🔧 Ajustando permissões..."
# n8n roda como UID 1000 (usuário 'node' no container)
# MySQL roda como UID 999 (usuário 'mysql' no container)
# Traefik roda como root mas precisa ler/escrever acme.json
chown -R 1000:1000 docker_data/n8n
chown -R 999:999 docker_data/mysql
chown -R root:root docker_data/letsencrypt
chmod -R 755 docker_data/

# Ajustar permissão especial para acme.json (Let's Encrypt exige 600)
if [ -f docker_data/letsencrypt/acme.json ]; then
    chmod 600 docker_data/letsencrypt/acme.json
fi

# Iniciar containers
echo "🐳 Iniciando containers Docker em modo produção..."
$DOCKER_COMPOSE -f docker-compose.prod.yml up -d

# Aguardar MySQL estar pronto
echo "⏳ Aguardando MySQL inicializar..."
sleep 10

# Verificar e corrigir problemas de migração do n8n
echo "🔍 Verificando estado das migrações do banco de dados..."

# Aguardar MySQL estar totalmente pronto
MAX_RETRIES=30
RETRY_COUNT=0
until $DOCKER_COMPOSE -f docker-compose.prod.yml exec -T mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "❌ Timeout aguardando MySQL. Verifique os logs."
        exit 1
    fi
    sleep 1
done

echo "✅ MySQL está pronto"

# Verificar se a coluna versionCounter já existe
CHECK_SQL="SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '$MYSQL_DATABASE' AND TABLE_NAME = 'workflow_entity' AND COLUMN_NAME = 'versionCounter';"

COLUMN_EXISTS=$($DOCKER_COMPOSE -f docker-compose.prod.yml exec -T mysql mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -sN -e "$CHECK_SQL" 2>/dev/null || echo "0")

if [ "$COLUMN_EXISTS" -gt 0 ]; then
    echo "🔧 Detectada coluna 'versionCounter' existente. Corrigindo estado da migração..."

    # Marcar a migração como executada para evitar erro "Duplicate column name"
    INSERT_MIGRATION_SQL="INSERT IGNORE INTO migrations (timestamp, name) VALUES (1761047826451, 'AddWorkflowVersionColumn1761047826451');"

    $DOCKER_COMPOSE -f docker-compose.prod.yml exec -T mysql mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "$INSERT_MIGRATION_SQL" 2>/dev/null || true

    echo "✅ Migração corrigida. Reiniciando n8n..."
    $DOCKER_COMPOSE -f docker-compose.prod.yml restart n8n
    sleep 5
fi

# Aguardar alguns segundos adicionais
echo "⏳ Aguardando todos os serviços estabilizarem..."
sleep 5

# Mostrar status
echo ""
echo "✅ Containers iniciados!"
echo ""
$DOCKER_COMPOSE -f docker-compose.prod.yml ps
echo ""
echo "📊 Acesse os serviços:"
echo "  - n8n: https://${N8N_SUBDOMAIN}.${DOMAIN}"
echo "  - phpMyAdmin: https://${PHPMYADMIN_SUBDOMAIN}.${DOMAIN}"
echo ""
echo "⚠️  IMPORTANTE: O certificado SSL pode demorar alguns minutos para ser emitido."
echo "   Aguarde 2-3 minutos e acesse os URLs acima."
echo ""
echo "📝 Ver logs: $DOCKER_COMPOSE -f docker-compose.prod.yml logs -f"
echo "🔒 Ver logs SSL: $DOCKER_COMPOSE -f docker-compose.prod.yml logs -f traefik"
echo "🛑 Parar: $DOCKER_COMPOSE -f docker-compose.prod.yml down"
