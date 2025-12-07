#!/bin/bash
# Comandos úteis para gerenciar o WhatsApp MCP Server

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}WhatsApp MCP Server - Comandos Úteis${NC}\n"

case "$1" in
  start)
    echo -e "${GREEN}Iniciando servidor...${NC}"
    docker-compose up --build
    ;;
    
  start-bg)
    echo -e "${GREEN}Iniciando servidor em background...${NC}"
    docker-compose up --build -d
    echo -e "${YELLOW}Use 'make logs' para ver o QR code${NC}"
    ;;
    
  stop)
    echo -e "${GREEN}Parando servidor...${NC}"
    docker-compose down
    ;;
    
  restart)
    echo -e "${GREEN}Reiniciando servidor...${NC}"
    docker-compose restart
    ;;
    
  logs)
    echo -e "${GREEN}Mostrando logs (Ctrl+C para sair)...${NC}"
    docker logs -f whatsapp-mcp-server
    ;;
    
  shell)
    echo -e "${GREEN}Acessando shell do container...${NC}"
    docker exec -it whatsapp-mcp-server /bin/bash
    ;;
    
  status)
    echo -e "${GREEN}Status do container:${NC}"
    docker ps -a | grep whatsapp-mcp
    echo -e "\n${GREEN}Databases:${NC}"
    ls -lh whatsapp-bridge/store/
    ;;
    
  reset-auth)
    echo -e "${YELLOW}⚠️  Isso vai remover a autenticação do WhatsApp!${NC}"
    read -p "Tem certeza? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Removendo autenticação...${NC}"
      docker-compose down
      rm -f whatsapp-bridge/store/whatsapp.db
      echo -e "${GREEN}Pronto! Inicie novamente e escaneie o QR code.${NC}"
    fi
    ;;
    
  test)
    echo -e "${GREEN}Testando endpoint MCP...${NC}"
    curl -X POST http://localhost:8000/mcp/v1/ \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' \
      | jq .
    ;;
    
  test-chats)
    echo -e "${GREEN}Listando últimos 5 chats...${NC}"
    curl -X POST http://localhost:8000/mcp/v1/ \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"list_chats","arguments":{"limit":5}},"id":2}' \
      | jq .
    ;;
    
  rebuild)
    echo -e "${GREEN}Rebuild completo (limpa cache)...${NC}"
    docker-compose down
    docker-compose build --no-cache
    docker-compose up
    ;;
    
  clean)
    echo -e "${YELLOW}⚠️  Isso vai remover TUDO (container, imagem e dados)!${NC}"
    read -p "Tem certeza? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker-compose down
      docker rmi whatsapp-mcp-whatsapp-mcp 2>/dev/null || true
      rm -rf whatsapp-bridge/store/*.db*
      echo -e "${GREEN}Tudo limpo!${NC}"
    fi
    ;;
    
  *)
    echo "Uso: $0 {comando}"
    echo ""
    echo "Comandos disponíveis:"
    echo "  start        - Iniciar servidor (mostra logs e QR code)"
    echo "  start-bg     - Iniciar em background"
    echo "  stop         - Parar servidor"
    echo "  restart      - Reiniciar servidor"
    echo "  logs         - Ver logs em tempo real"
    echo "  shell        - Acessar shell do container"
    echo "  status       - Ver status e arquivos"
    echo "  reset-auth   - Remover autenticação (para re-autenticar)"
    echo "  test         - Testar endpoint MCP"
    echo "  test-chats   - Testar listagem de chats"
    echo "  rebuild      - Rebuild completo"
    echo "  clean        - Limpar TUDO (container + dados)"
    echo ""
    echo "Exemplos:"
    echo "  $0 start       # Primeira vez - para ver QR code"
    echo "  $0 logs        # Ver QR code se iniciou com -d"
    echo "  $0 test        # Testar se está funcionando"
    ;;
esac
