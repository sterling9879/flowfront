#!/bin/bash
# ==============================================================
# Setup script — Flow Criativos Landing Page
# ==============================================================
# Executa em VPS Ubuntu 22.04 com Nginx já instalado.
# PORTAS: HTTP 9090 / HTTPS 9443
# Uso: sudo bash setup.sh
# ==============================================================

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

HTTP_PORT=9090
HTTPS_PORT=9443

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Flow Criativos — Setup Script      ║${NC}"
echo -e "${BOLD}║   HTTP :${HTTP_PORT}  |  HTTPS :${HTTPS_PORT}       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ----------------------------------------------------------
# Passo 1: Verifica se está rodando como root
# ----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERRO]${NC} Execute este script como root: sudo bash setup.sh"
  exit 1
fi

# ----------------------------------------------------------
# Passo 2: Verifica se o Nginx está instalado
# ----------------------------------------------------------
if ! command -v nginx &> /dev/null; then
  echo -e "${YELLOW}[...]${NC} Nginx não encontrado. Instalando..."
  apt update && apt install -y nginx
  echo -e "${GREEN}[✓]${NC} Nginx instalado"
else
  echo -e "${GREEN}[✓]${NC} Nginx encontrado"
fi

# ----------------------------------------------------------
# Passo 3: Cria a pasta do site
# ----------------------------------------------------------
SITE_DIR="/var/www/flowcriativos"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${YELLOW}[...]${NC} Criando diretório ${SITE_DIR}"
mkdir -p "$SITE_DIR"
echo -e "${GREEN}[✓]${NC} Diretório criado"

# ----------------------------------------------------------
# Passo 4: Copia o index.html para a pasta do site
# ----------------------------------------------------------
if [ ! -f "${SCRIPT_DIR}/index.html" ]; then
  echo -e "${RED}[ERRO]${NC} Arquivo index.html não encontrado em ${SCRIPT_DIR}"
  exit 1
fi

echo -e "${YELLOW}[...]${NC} Copiando index.html para ${SITE_DIR}"
cp "${SCRIPT_DIR}/index.html" "${SITE_DIR}/index.html"
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"
echo -e "${GREEN}[✓]${NC} index.html copiado"

# ----------------------------------------------------------
# Passo 5: Copia a config do Nginx
# ----------------------------------------------------------
NGINX_AVAILABLE="/etc/nginx/sites-available/flowcriativos"
NGINX_ENABLED="/etc/nginx/sites-enabled/flowcriativos"

if [ ! -f "${SCRIPT_DIR}/nginx.conf" ]; then
  echo -e "${RED}[ERRO]${NC} Arquivo nginx.conf não encontrado em ${SCRIPT_DIR}"
  exit 1
fi

echo -e "${YELLOW}[...]${NC} Copiando configuração do Nginx"
cp "${SCRIPT_DIR}/nginx.conf" "$NGINX_AVAILABLE"
echo -e "${GREEN}[✓]${NC} Configuração copiada para ${NGINX_AVAILABLE}"

# ----------------------------------------------------------
# Passo 6: Cria symlink em sites-enabled
# ----------------------------------------------------------
if [ -L "$NGINX_ENABLED" ]; then
  echo -e "${YELLOW}[...]${NC} Symlink já existe, recriando..."
  rm "$NGINX_ENABLED"
fi

ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
echo -e "${GREEN}[✓]${NC} Symlink criado em ${NGINX_ENABLED}"

# ----------------------------------------------------------
# Passo 7: Abre as portas no firewall (se UFW estiver ativo)
# ----------------------------------------------------------
if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
  echo -e "${YELLOW}[...]${NC} Abrindo portas ${HTTP_PORT} e ${HTTPS_PORT} no UFW..."
  ufw allow ${HTTP_PORT}/tcp
  ufw allow ${HTTPS_PORT}/tcp
  echo -e "${GREEN}[✓]${NC} Portas abertas no firewall"
else
  echo -e "${YELLOW}[!]${NC} UFW não ativo — verifique manualmente se as portas ${HTTP_PORT} e ${HTTPS_PORT} estão abertas"
fi

# ----------------------------------------------------------
# Passo 8: Testa configuração do Nginx
# ----------------------------------------------------------
echo -e "${YELLOW}[...]${NC} Testando configuração do Nginx..."
if nginx -t 2>&1; then
  echo -e "${GREEN}[✓]${NC} Configuração válida"
else
  echo -e "${RED}[ERRO]${NC} Configuração do Nginx inválida. Verifique o arquivo ${NGINX_AVAILABLE}"
  exit 1
fi

# ----------------------------------------------------------
# Passo 9: Recarrega o Nginx
# ----------------------------------------------------------
echo -e "${YELLOW}[...]${NC} Recarregando Nginx..."
systemctl reload nginx
echo -e "${GREEN}[✓]${NC} Nginx recarregado"

# ----------------------------------------------------------
# Instruções finais
# ----------------------------------------------------------
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Setup concluído com sucesso!${NC}"
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Acesse agora:${NC} http://${IP_ADDR}:${HTTP_PORT}"
echo ""
echo -e "  ${BOLD}Próximos passos:${NC}"
echo ""
echo -e "  1. ${YELLOW}Edite o domínio${NC} no arquivo de configuração:"
echo -e "     nano ${NGINX_AVAILABLE}"
echo -e "     Substitua ${BOLD}SEUDOMINIO.COM${NC} pelo seu domínio real"
echo ""
echo -e "  2. ${YELLOW}Teste e recarregue${NC} o Nginx:"
echo -e "     nginx -t && systemctl reload nginx"
echo ""
echo -e "  3. ${YELLOW}Configure o DNS${NC} do seu domínio apontando para: ${IP_ADDR}"
echo ""
echo -e "  4. ${YELLOW}Adicione SSL${NC} (porta ${HTTPS_PORT}):"
echo -e "     sudo apt install certbot"
echo -e "     sudo certbot certonly --standalone -d SEUDOMINIO.COM -d www.SEUDOMINIO.COM"
echo -e "     Depois descomente o bloco SSL no nginx.conf e recarregue"
echo ""
echo -e "  5. ${YELLOW}Substitua o link de pagamento${NC} no index.html:"
echo -e "     nano ${SITE_DIR}/index.html"
echo -e "     Busque href=\"#\" no botão de compra e coloque seu link real"
echo ""
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
