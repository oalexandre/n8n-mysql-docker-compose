# n8n com Docker Compose, MySQL e SSL Automático

Setup completo e pronto para uso do n8n com MySQL, phpMyAdmin e SSL automático via Let's Encrypt.

## O que é este projeto?

Este repositório facilita o deploy do **n8n** (plataforma de automação de workflows) com:
- MySQL 8.0 como banco de dados
- phpMyAdmin para gerenciar o MySQL
- Dados persistidos localmente para backups fáceis
- SSL automático em produção (Let's Encrypt + Traefik)
- Scripts de inicialização que configuram tudo automaticamente

## O que ele oferece?

- ✅ **Dois ambientes**: Desenvolvimento (localhost) e Produção (SSL automático)
- ✅ **Zero configuração manual**: Scripts detectam sua versão do Docker Compose
- ✅ **Permissões seguras**: 755 com ownership correto (não usa 777)
- ✅ **SSL automático**: Certificados Let's Encrypt com renovação automática
- ✅ **Backup fácil**: Todos os dados em uma pasta local (`docker_data/`)
- ✅ **Compatível com sudo**: Funciona perfeitamente em servidores

---

## Como usar em Desenvolvimento

### Pré-requisitos
- Docker (20.10+)
- Docker Compose (V2 recomendado: `docker compose` | V1 legado: `docker-compose`)

### Instalação

```bash
# 1. Clone o repositório
git clone <seu-repositorio>
cd <pasta-do-repositorio>

# 2. Configure o .env
cp .env.example .env
nano .env  # Altere as senhas se desejar

# 3. Inicie com o script (recomendado)
./start.sh
# OU com sudo se necessário
sudo ./start.sh
```

### Acesso

- **n8n**: http://localhost:5678
- **phpMyAdmin**: http://localhost:8080
- **Usuário/Senha**: Definidos no `.env` (padrão: admin/admin)

### Comandos úteis

```bash
# Ver logs
docker compose logs -f n8n

# Parar
docker compose down

# Reiniciar
docker compose restart
```

---

## Como usar em Produção

### Pré-requisitos adicionais

1. **Servidor com IP público** (VPS, Cloud, etc)
2. **Domínio próprio** configurado
3. **DNS apontando para o servidor**:
   ```
   n8n.seudominio.com    -> IP do servidor
   pma.seudominio.com    -> IP do servidor
   ```
4. **Portas 80 e 443 abertas** no firewall

### Instalação

```bash
# 1. Clone o repositório no servidor
git clone <seu-repositorio>
cd <pasta-do-repositorio>

# 2. Configure o .env para produção
cp .env.example .env
nano .env
```

**Configure estas variáveis no .env:**
```bash
ENVIRONMENT=production
DOMAIN=seudominio.com
N8N_SUBDOMAIN=n8n
PHPMYADMIN_SUBDOMAIN=pma
LETSENCRYPT_EMAIL=seu-email@seudominio.com

# IMPORTANTE: Altere TODAS as senhas!
MYSQL_ROOT_PASSWORD=senha-forte-aqui
MYSQL_PASSWORD=outra-senha-forte
N8N_BASIC_AUTH_PASSWORD=senha-admin-forte
```

```bash
# 3. Inicie com o script (recomendado)
sudo ./start-prod.sh
```

### Acesso

Aguarde 2-3 minutos para o SSL ser emitido, depois acesse:

- **n8n**: https://n8n.seudominio.com
- **phpMyAdmin**: https://pma.seudominio.com
- **Usuário/Senha**: Definidos no `.env`

### Comandos úteis

```bash
# Ver logs
sudo docker compose -f docker-compose.prod.yml logs -f

# Ver logs do SSL/Traefik
sudo docker compose -f docker-compose.prod.yml logs -f traefik

# Parar
sudo docker compose -f docker-compose.prod.yml down

# Reiniciar
sudo docker compose -f docker-compose.prod.yml restart
```

---

## Estrutura de Dados

```
docker_data/
├── mysql/          # Banco de dados MySQL
├── n8n/            # Workflows e configurações do n8n
└── letsencrypt/    # Certificados SSL (somente produção)
```

## Backup

```bash
# Criar backup
tar -czf backup-n8n-$(date +%Y%m%d).tar.gz docker_data/

# Restaurar backup
tar -xzf backup-n8n-YYYYMMDD.tar.gz
```

---

## Troubleshooting

### n8n não inicia (erro de permissão)

```bash
# Parar containers
docker compose down  # ou: sudo docker compose -f docker-compose.prod.yml down

# Rodar o script novamente
sudo ./start.sh      # dev
sudo ./start-prod.sh # prod
```

### SSL não está sendo emitido (produção)

1. **Verifique DNS**: `nslookup n8n.seudominio.com`
2. **Verifique portas**: `sudo ufw status` (80 e 443 devem estar abertas)
3. **Veja logs do Traefik**: `docker compose -f docker-compose.prod.yml logs traefik`
4. **Aguarde**: Pode demorar 2-5 minutos

### Resetar tudo

**CUIDADO: Apaga todos os dados!**

```bash
docker compose down
rm -rf docker_data/
./start.sh  # ou ./start-prod.sh
```

---

## Configuração Avançada

### Arquivo .env completo

```bash
# Environment (development ou production)
ENVIRONMENT=development

# Production SSL Configuration
DOMAIN=exemplo.com
N8N_SUBDOMAIN=n8n
PHPMYADMIN_SUBDOMAIN=pma
LETSENCRYPT_EMAIL=seu-email@exemplo.com

# MySQL Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=n8n
MYSQL_USER=n8n
MYSQL_PASSWORD=n8npassword
MYSQL_PORT=3306

# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=admin
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

# phpMyAdmin Configuration
PHPMYADMIN_PORT=8080

# Data Persistence
DATA_FOLDER=./docker_data
```

### Comandos manuais (sem scripts)

**Desenvolvimento:**
```bash
mkdir -p docker_data/n8n docker_data/mysql
sudo chown -R 1000:1000 docker_data/n8n
sudo chown -R 999:999 docker_data/mysql
sudo chmod -R 755 docker_data/
docker compose up -d
```

**Produção:**
```bash
mkdir -p docker_data/n8n docker_data/mysql docker_data/letsencrypt
sudo chown -R 1000:1000 docker_data/n8n
sudo chown -R 999:999 docker_data/mysql
sudo chown -R root:root docker_data/letsencrypt
sudo chmod -R 755 docker_data/
docker compose -f docker-compose.prod.yml up -d
```

### Docker Compose: V1 vs V2

Os scripts detectam automaticamente qual versão você tem:

- **V2 (recomendado)**: `docker compose` - Plugin integrado, melhor performance
- **V1 (legado)**: `docker-compose` - Standalone, será descontinuado

Se não tiver nenhuma versão: [Instalar Docker Compose V2](https://docs.docker.com/compose/install/linux/)

---

## Segurança

### Permissões de arquivos
- ✅ **755** (rwxr-xr-x): Apenas o dono pode escrever - SEGURO
- ❌ **777** (rwxrwxrwx): Qualquer processo pode escrever - INSEGURO

Este projeto usa **755** com ownership correto para cada serviço.

### Produção
- SSL configurado automaticamente (renovação a cada 90 dias)
- Redirect HTTP → HTTPS automático
- Apenas portas 80 e 443 expostas
- Configure firewall adicional (ufw, iptables)

### Recomendações
- Altere TODAS as senhas no `.env` antes de produção
- Nunca commite o arquivo `.env` (já está no .gitignore)
- Faça backups regulares da pasta `docker_data/`
- Use autenticação de dois fatores no n8n
- Mantenha Docker e imagens atualizadas

---

## Licença

Este projeto é fornecido como está, sem garantias.
