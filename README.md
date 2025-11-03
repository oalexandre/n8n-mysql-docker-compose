# n8n com Docker Compose e MySQL

Este repositório tem como objetivo facilitar a criação de um ambiente n8n usando Docker Compose com MySQL como banco de dados, com persistência de dados no disco do host para facilitar backups.

## Características

- **n8n**: Ferramenta de automação de workflows
- **MySQL 8.0**: Banco de dados para persistência dos dados do n8n
- **phpMyAdmin**: Interface web para gerenciar o banco de dados MySQL
- **Persistência de Dados**: Todos os dados são armazenados na pasta `docker_data/` no host
- **Configuração via .env**: Todas as credenciais e configurações centralizadas em arquivo .env
- **Backup Facilitado**: Como os dados estão persistidos em uma pasta local, basta fazer backup da pasta `docker_data/`
- **SSL Automático em Produção**: Traefik + Let's Encrypt para HTTPS automático com renovação de certificados
- **Dois Modos**: Desenvolvimento (localhost) e Produção (domínio próprio com SSL)
- **Scripts de Inicialização**: `start.sh` e `start-prod.sh` configuram tudo automaticamente
- **Funciona com sudo**: Configurado para funcionar perfeitamente mesmo rodando Docker com sudo

## Pré-requisitos

- **Docker** (versão 20.10 ou superior)
- **Docker Compose**

### Sobre Docker Compose

Existem duas versões do Docker Compose:

#### ✅ Recomendado: Docker Compose V2 (plugin integrado)
```bash
# Comando: docker compose (sem hífen)
docker compose version
```
- **Mais novo e mantido ativamente**
- Integrado ao Docker CLI
- Melhor performance
- Instalado automaticamente com Docker Desktop
- Linux: Vem com as versões mais recentes do Docker Engine

#### ⚠️  Legado: Docker Compose V1 (standalone)
```bash
# Comando: docker-compose (com hífen)
docker-compose version
```
- Versão antiga (standalone Python)
- Ainda funciona, mas não é mais recomendado
- Suportado pelos scripts deste projeto para compatibilidade

**Os scripts deste projeto detectam automaticamente qual versão você tem instalada e usam o comando correto!**

Se você não tiver nenhuma das duas versões, instale o Docker Compose V2:
- **Docker Desktop**: Já vem incluído
- **Linux**: [Instruções de instalação](https://docs.docker.com/compose/install/linux/)

## Instalação

1. Clone este repositório:
```bash
git clone <seu-repositorio>
cd <pasta-do-repositorio>
```

2. Copie o arquivo `.env.example` para `.env` e configure suas credenciais:
```bash
cp .env.example .env
```

3. Edite o arquivo `.env` e altere as senhas padrão:
```bash
nano .env
```

**Nota:** Não precisa criar pastas manualmente. Os scripts `start.sh` e `start-prod.sh` fazem isso automaticamente!

## Configuração

O arquivo `.env` contém todas as configurações necessárias:

```bash
# Environment (development ou production)
ENVIRONMENT=development

# Production SSL Configuration
# Usado apenas quando ENVIRONMENT=production
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

**IMPORTANTE:** Altere todas as senhas antes de usar em produção!

## Uso

Este projeto suporta dois ambientes: **Desenvolvimento** e **Produção**.

### Modo Desenvolvimento (Localhost)

#### Iniciar os serviços (Recomendado)

Use o script de inicialização que configura tudo automaticamente:

```bash
# Forma simples (recomendado)
./start.sh

# Ou com sudo se necessário
sudo ./start.sh
```

O script `start.sh` vai:
- Detectar automaticamente se você usa `docker-compose` ou `docker compose`
- Criar as pastas necessárias
- Ajustar permissões automaticamente
- Iniciar os containers
- Mostrar os URLs de acesso

#### Iniciar manualmente (Alternativa)

Se preferir iniciar manualmente:

```bash
# Criar pastas
mkdir -p docker_data/n8n docker_data/mysql

# Ajustar ownership (n8n=UID 1000, MySQL=UID 999)
sudo chown -R 1000:1000 docker_data/n8n
sudo chown -R 999:999 docker_data/mysql

# Ajustar permissões (755 é mais seguro que 777)
sudo chmod -R 755 docker_data/

# Iniciar containers
# Use 'docker compose' (recomendado) OU 'docker-compose' (legado)
docker compose up -d
# OU
docker-compose up -d
```

### Verificar o status dos containers

```bash
# V2 (recomendado)
docker compose ps

# V1 (legado)
docker-compose ps
```

### Ver os logs

```bash
# Ver todos os logs
docker compose logs -f    # V2
docker-compose logs -f    # V1

# Ver apenas logs do n8n
docker compose logs -f n8n    # V2
docker-compose logs -f n8n    # V1

# Ver apenas logs do MySQL
docker compose logs -f mysql    # V2
docker-compose logs -f mysql    # V1

# Ver apenas logs do phpMyAdmin
docker compose logs -f phpmyadmin    # V2
docker-compose logs -f phpmyadmin    # V1
```

### Parar os serviços

```bash
docker compose down    # V2 (recomendado)
docker-compose down    # V1 (legado)
```

### Reiniciar os serviços

```bash
docker compose restart    # V2 (recomendado)
docker-compose restart    # V1 (legado)
```

#### Acesso aos Serviços (Desenvolvimento)

Após iniciar os serviços em modo desenvolvimento:

**n8n:**
- **URL**: http://localhost:5678
- **Usuário**: admin (definido no .env)
- **Senha**: admin (definido no .env)

**phpMyAdmin:**
- **URL**: http://localhost:8080
- **Servidor**: mysql
- **Usuário**: root ou n8n
- **Senha**: Conforme definido no .env

---

### Modo Produção (SSL Automático)

Use o arquivo `docker-compose.prod.yml` para produção com SSL automático via Let's Encrypt.

#### Pré-requisitos para Produção

1. **Servidor com IP público** (VPS, Cloud, etc)
2. **Domínio próprio** configurado
3. **Registros DNS** apontando para o IP do servidor:
   ```
   n8n.seudominio.com    -> IP do servidor
   pma.seudominio.com    -> IP do servidor
   ```
4. **Portas 80 e 443** abertas no firewall

#### Configurar para Produção

1. Edite o arquivo `.env`:
```bash
# Altere estas variáveis
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

2. Inicie os serviços em modo produção:

**Forma Simples (Recomendado):**
```bash
# Com o script que configura tudo automaticamente
./start-prod.sh

# Ou com sudo se necessário
sudo ./start-prod.sh
```

O script `start-prod.sh` vai:
- Detectar automaticamente se você usa `docker-compose` ou `docker compose`
- Verificar se o .env está configurado
- Criar as pastas necessárias
- Ajustar permissões automaticamente
- Iniciar os containers em modo produção
- Mostrar os URLs de acesso

**Forma Manual (Alternativa):**
```bash
# Criar pastas
mkdir -p docker_data/n8n docker_data/mysql docker_data/letsencrypt

# Ajustar ownership (n8n=UID 1000, MySQL=UID 999)
sudo chown -R 1000:1000 docker_data/n8n
sudo chown -R 999:999 docker_data/mysql
sudo chown -R root:root docker_data/letsencrypt

# Ajustar permissões (755 é mais seguro que 777)
sudo chmod -R 755 docker_data/

# Iniciar containers
# Use 'docker compose' (recomendado) OU 'docker-compose' (legado)
docker compose -f docker-compose.prod.yml up -d
# OU
docker-compose -f docker-compose.prod.yml up -d
```

#### Acesso aos Serviços (Produção)

Após iniciar em modo produção, os certificados SSL serão emitidos automaticamente:

**n8n:**
- **URL**: https://n8n.seudominio.com
- **SSL**: Automático via Let's Encrypt
- **Usuário**: admin (definido no .env)
- **Senha**: Conforme definido no .env

**phpMyAdmin:**
- **URL**: https://pma.seudominio.com
- **SSL**: Automático via Let's Encrypt
- **Servidor**: mysql
- **Usuário**: root ou n8n
- **Senha**: Conforme definido no .env

#### Gerenciamento da Produção

```bash
# Ver logs (V2 recomendado / V1 legado)
docker compose -f docker-compose.prod.yml logs -f
docker-compose -f docker-compose.prod.yml logs -f

# Ver logs do Traefik (gerenciador SSL)
docker compose -f docker-compose.prod.yml logs -f traefik
docker-compose -f docker-compose.prod.yml logs -f traefik

# Parar serviços
docker compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml down

# Reiniciar serviços
docker compose -f docker-compose.prod.yml restart
docker-compose -f docker-compose.prod.yml restart
```

**Dica:** Se você usar os scripts `start.sh` ou `start-prod.sh`, eles mostrarão os comandos corretos para seu sistema no final da execução!

## Estrutura de Dados

Todos os dados são armazenados na pasta `docker_data/`:

```
docker_data/
├── mysql/          # Dados do banco MySQL
├── n8n/            # Dados e configurações do n8n
└── letsencrypt/    # Certificados SSL (apenas em produção)
    └── acme.json   # Certificados do Let's Encrypt
```

## Backup

Para fazer backup dos dados, basta copiar a pasta `docker_data/`:

```bash
# Criar backup
tar -czf backup-n8n-$(date +%Y%m%d).tar.gz docker_data/

# Restaurar backup
tar -xzf backup-n8n-YYYYMMDD.tar.gz
```

## Troubleshooting

**Nota sobre comandos:** Os exemplos abaixo usam `docker compose` (V2 recomendado). Se você usa a versão legado, substitua por `docker-compose`.

### Desenvolvimento

#### O n8n não consegue conectar ao MySQL

Aguarde alguns segundos para o MySQL inicializar completamente. O docker-compose está configurado com healthcheck, mas pode demorar um pouco.

#### Erro de permissão na pasta docker_data (n8n não inicia)

Se você vir o erro `EACCES: permission denied, open '/home/node/.n8n/config'`, o n8n não consegue escrever na pasta. Solução:

**Opção 1 - Usar o script (recomendado):**
```bash
# Parar os containers
docker compose down

# Rodar o script que ajusta tudo
sudo ./start.sh
```

**Opção 2 - Ajustar permissões manualmente:**
```bash
# Parar os containers
docker compose down

# Ajustar ownership para o UID do n8n (1000)
sudo chown -R 1000:1000 docker_data/n8n/

# Ajustar permissões
sudo chmod -R 755 docker_data/n8n/

# Reiniciar
docker compose up -d
```

**Opção 3 - Resetar pasta do n8n:**
```bash
# Parar os containers
docker compose down

# Remover apenas a pasta do n8n
rm -rf docker_data/n8n/

# Reiniciar (o Docker criará a pasta com permissões corretas)
docker compose up -d
```

#### Resetar todos os dados

**CUIDADO: Isso apagará todos os dados!**

```bash
docker compose down
rm -rf docker_data/
docker compose up -d
```

### Produção

#### n8n não inicia - Erro de permissão

Se você vir o erro `EACCES: permission denied` nos logs do n8n em produção:

**Opção 1 - Usar o script (recomendado):**
```bash
# Parar os containers
sudo docker compose -f docker-compose.prod.yml down

# Rodar o script que ajusta tudo
sudo ./start-prod.sh
```

**Opção 2 - Ajustar manualmente:**
```bash
# Parar os containers
sudo docker compose -f docker-compose.prod.yml down

# Ajustar ownership
sudo chown -R 1000:1000 docker_data/n8n/

# Ajustar permissões
sudo chmod -R 755 docker_data/n8n/

# Reiniciar
sudo docker compose -f docker-compose.prod.yml up -d
```

#### Certificado SSL não está sendo emitido

1. Verifique se as portas 80 e 443 estão abertas:
```bash
sudo ufw status
# Ou
sudo iptables -L
```

2. Verifique se o DNS está configurado corretamente:
```bash
nslookup n8n.seudominio.com
nslookup pma.seudominio.com
```

3. Verifique os logs do Traefik:
```bash
docker compose -f docker-compose.prod.yml logs traefik
```

4. Aguarde alguns minutos - o Let's Encrypt pode demorar para emitir o certificado.

#### Erro "acme.json: open /letsencrypt/acme.json: permission denied"

Ajuste as permissões da pasta:
```bash
chmod -R 755 docker_data/letsencrypt/
```

#### Site não abre após configurar produção

1. Verifique se todos os containers estão rodando:
```bash
docker compose -f docker-compose.prod.yml ps
```

2. Verifique os logs:
```bash
docker compose -f docker-compose.prod.yml logs -f
```

3. Teste se o servidor está acessível:
```bash
curl -I http://n8n.seudominio.com
```

#### Renovação de certificados

Os certificados são renovados automaticamente pelo Traefik. Não é necessária nenhuma ação manual!

Para verificar quando o certificado expira:
```bash
echo | openssl s_client -servername n8n.seudominio.com -connect n8n.seudominio.com:443 2>/dev/null | openssl x509 -noout -dates
```

## Segurança

### Permissões de Arquivos

Este projeto usa permissões seguras configuradas automaticamente pelos scripts:

- **n8n**: Pasta `docker_data/n8n/` pertence ao UID 1000 (usuário `node` no container)
- **MySQL**: Pasta `docker_data/mysql/` pertence ao UID 999 (usuário `mysql` no container)
- **Traefik**: Pasta `docker_data/letsencrypt/` pertence ao root
- **Permissões**: 755 (rwxr-xr-x) - somente o dono pode escrever, outros podem ler

**Por que NÃO usar 777?**
- ✅ **755**: Seguro - apenas o processo correto pode modificar os dados
- ❌ **777**: Inseguro - qualquer processo pode modificar os dados

Os scripts `start.sh` e `start-prod.sh` configuram isso automaticamente usando `chown` e `chmod 755`.

### Geral
- **SEMPRE** altere as senhas padrão do arquivo `.env`
- **NUNCA** commite o arquivo `.env` no Git (já está no .gitignore)
- Use senhas fortes e únicas para cada serviço
- Considere usar secrets do Docker Swarm ou variáveis de ambiente do sistema em produção

### Produção
- O SSL é configurado automaticamente via Let's Encrypt (renovação automática a cada 90 dias)
- O Traefik redireciona automaticamente HTTP para HTTPS
- Certifique-se de que apenas as portas 80 e 443 estão expostas publicamente
- Configure um firewall (ufw, iptables, security groups) para proteger outras portas
- Considere usar autenticação de dois fatores no n8n
- Mantenha backups regulares da pasta `docker_data/`

### Recomendações Adicionais
- Use fail2ban para proteção contra brute force
- Configure rate limiting no Traefik se necessário
- Monitore os logs regularmente
- Mantenha o Docker e as imagens atualizadas

## Licença

Este projeto é fornecido como está, sem garantias.
