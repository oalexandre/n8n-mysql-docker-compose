#!/bin/bash

# Script de inicialização para desenvolvimento
# Este script garante que todas as pastas e permissões estejam corretas

set -e

echo "🚀 Iniciando n8n em modo DESENVOLVIMENTO..."

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

# Criar pastas necessárias
echo "📁 Criando estrutura de pastas..."
mkdir -p docker_data/mysql
mkdir -p docker_data/n8n

# Ajustar ownership e permissões de forma segura
echo "🔧 Ajustando permissões..."
# n8n roda como UID 1000 (usuário 'node' no container)
# MySQL roda como UID 999 (usuário 'mysql' no container)
chown -R 1000:1000 docker_data/n8n
chown -R 999:999 docker_data/mysql
chmod -R 755 docker_data/

# Iniciar containers
echo "🐳 Iniciando containers Docker..."
$DOCKER_COMPOSE up -d

# Aguardar alguns segundos
echo "⏳ Aguardando containers iniciarem..."
sleep 5

# Mostrar status
echo ""
echo "✅ Containers iniciados!"
echo ""
$DOCKER_COMPOSE ps
echo ""
echo "📊 Acesse os serviços:"
echo "  - n8n: http://localhost:5678"
echo "  - phpMyAdmin: http://localhost:8080"
echo ""
echo "📝 Ver logs: $DOCKER_COMPOSE logs -f"
echo "🛑 Parar: $DOCKER_COMPOSE down"
