#!/bin/bash

# Script de inicialização para produção
# Este script garante que todas as pastas e permissões estejam corretas

set -e

echo "🚀 Iniciando n8n em modo PRODUÇÃO..."

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
docker-compose -f docker-compose.prod.yml up -d

# Aguardar alguns segundos
echo "⏳ Aguardando containers iniciarem..."
sleep 5

# Mostrar status
echo ""
echo "✅ Containers iniciados!"
echo ""
docker-compose -f docker-compose.prod.yml ps
echo ""
echo "📊 Acesse os serviços:"
echo "  - n8n: https://${N8N_SUBDOMAIN}.${DOMAIN}"
echo "  - phpMyAdmin: https://${PHPMYADMIN_SUBDOMAIN}.${DOMAIN}"
echo ""
echo "⚠️  IMPORTANTE: O certificado SSL pode demorar alguns minutos para ser emitido."
echo "   Aguarde 2-3 minutos e acesse os URLs acima."
echo ""
echo "📝 Ver logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "🔒 Ver logs SSL: docker-compose -f docker-compose.prod.yml logs -f traefik"
echo "🛑 Parar: docker-compose -f docker-compose.prod.yml down"
