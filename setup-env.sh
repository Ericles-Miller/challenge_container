#!/bin/bash

# Script para configurar variáveis de ambiente de forma segura
# Autor: Challenge Container Setup
# Descrição: Configura o arquivo .env com valores seguros

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir cabeçalho
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}🔧 Configurador de Ambiente Docker${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Função para gerar senha segura
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Função para ler input com valor padrão
read_with_default() {
    local prompt="$1"
    local default="$2"
    local value
    
    read -p "$(echo -e ${YELLOW}${prompt}${NC} [${default}]: )" value
    echo "${value:-$default}"
}

# Função para perguntar sim/não
ask_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$(echo -e ${YELLOW}${prompt}${NC} (s/n): )" response
        case "$response" in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Por favor responda s ou n${NC}";;
        esac
    done
}

# Função principal
main() {
    print_header
    
    # Verificar se .env já existe
    if [ -f ".env" ]; then
        echo -e "${YELLOW}⚠️  Arquivo .env já existe!${NC}"
        if ask_yes_no "Deseja sobrescrever?"; then
            mv .env .env.backup.$(date +%Y%m%d_%H%M%S)
            echo -e "${GREEN}✅ Backup criado: .env.backup${NC}"
        else
            echo -e "${BLUE}ℹ️  Mantendo arquivo .env existente${NC}"
            exit 0
        fi
    fi
    
    echo -e "${GREEN}📝 Vamos configurar seu ambiente!${NC}"
    echo ""
    
    # Coletar informações
    DB_NAME=$(read_with_default "Nome do banco de dados" "challenge_db")
    DB_USER=$(read_with_default "Nome do usuário do banco" "challenge_user")
    APP_PORT=$(read_with_default "Porta da aplicação" "3000")
    
    echo ""
    if ask_yes_no "🔐 Gerar senhas seguras automaticamente?"; then
        ROOT_PASSWORD=$(generate_password)
        USER_PASSWORD=$(generate_password)
        echo -e "${GREEN}✅ Senhas geradas com sucesso!${NC}"
    else
        read -sp "$(echo -e ${YELLOW}Digite a senha do root:${NC} )" ROOT_PASSWORD
        echo ""
        read -sp "$(echo -e ${YELLOW}Digite a senha do usuário:${NC} )" USER_PASSWORD
        echo ""
    fi
    
    # Determinar ambiente
    echo ""
    if ask_yes_no "🐳 Rodar dentro do Docker?"; then
        DB_HOST="mysql"
        NODE_ENV="production"
    else
        DB_HOST="localhost"
        NODE_ENV="development"
    fi
    
    # Criar arquivo .env
    cat > .env << EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=${ROOT_PASSWORD}
MYSQL_DATABASE=${DB_NAME}
MYSQL_USER=${DB_USER}
MYSQL_PASSWORD=${USER_PASSWORD}

# Application Configuration
APP_PORT=${APP_PORT}
NODE_ENV=${NODE_ENV}

# Database Connection (for application)
DB_HOST=${DB_HOST}
DB_PORT=3306
EOF
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}✅ Arquivo .env criado com sucesso!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${BLUE}📋 Resumo da configuração:${NC}"
    echo -e "   ${YELLOW}Banco de dados:${NC} ${DB_NAME}"
    echo -e "   ${YELLOW}Usuário:${NC} ${DB_USER}"
    echo -e "   ${YELLOW}Host:${NC} ${DB_HOST}"
    echo -e "   ${YELLOW}Porta:${NC} ${APP_PORT}"
    echo -e "   ${YELLOW}Ambiente:${NC} ${NODE_ENV}"
    echo ""
    echo -e "${BLUE}🚀 Próximos passos:${NC}"
    echo -e "   1. Execute: ${GREEN}docker-compose up -d${NC}"
    echo -e "   2. Verifique os logs: ${GREEN}docker-compose logs -f${NC}"
    echo -e "   3. Teste a aplicação: ${GREEN}curl http://localhost:${APP_PORT}${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Importante: Não commite o arquivo .env no Git!${NC}"
}

# Executar script
main
