# WhatsApp MCP Server - Docker Deployment

Este guia mostra como executar o WhatsApp MCP Server em um container Docker com modo HTTP/SSE streamable.

## 🚀 Quick Start

### 1. Build e Start do Container

```bash
# Build e iniciar com docker-compose
docker-compose up --build

# Ou em modo detached (background)
docker-compose up --build -d
```

### 2. Autenticação WhatsApp (Primeira vez)

Na primeira execução, você precisará escanear um QR code para autenticar com o WhatsApp:

```bash
# Ver os logs do container
docker logs -f whatsapp-mcp-server
```

Procure pelo QR code nos logs e escaneie com seu WhatsApp no celular (Configurações > Dispositivos Conectados > Conectar Dispositivo).

### 3. Acessar o MCP Server

O servidor estará disponível em:
- **MCP Streamable HTTP Endpoint**: `http://localhost:8000/mcp/v1/`
- **WhatsApp Bridge API**: `http://localhost:8080`

## 📋 Estrutura do Deployment

```
whatsapp-mcp/
├── Dockerfile              # Multi-stage build (Go + Python)
├── docker-compose.yml      # Configuração do container
├── docker-entrypoint.sh    # Script de inicialização
├── whatsapp-bridge/        # Go bridge para WhatsApp
│   └── store/             # Databases persistidos (volume)
└── whatsapp-mcp-server/   # Python MCP server
```

## 🔧 Configuração

### Variáveis de Ambiente

Você pode customizar através do `docker-compose.yml`:

```yaml
environment:
  - WHATSAPP_BRIDGE_URL=http://localhost:8080
  - MCP_HTTP_PORT=8000
```

### Portas

- `8000`: MCP Server Streamable HTTP
- `8080`: WhatsApp Bridge API (interna)

### Volumes

O volume `./whatsapp-bridge/store` é montado para persistir:
- `whatsapp.db`: Sessão do WhatsApp
- `messages.db`: Banco de dados de mensagens

**Importante**: Não delete esse diretório ou você terá que re-autenticar!

## 🔌 Como Conectar Clientes

### Exemplo com Claude Desktop (Streamable HTTP)

Adicione ao seu `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "whatsapp": {
      "transport": "http",
      "url": "http://localhost:8000/mcp/v1/"
    }
  }
}
```

### Exemplo com Python Client

```python
from mcp.client.http import HttpClient

async with HttpClient("http://localhost:8000/mcp/v1/") as client:
    # Use o cliente MCP
    tools = await client.list_tools()
    print(tools)
```

### Exemplo com cURL (Testar conexão)

```bash
# Listar ferramentas disponíveis
curl -X POST http://localhost:8000/mcp/v1/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Chamar uma ferramenta
curl -X POST http://localhost:8000/mcp/v1/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{"name":"list_chats","arguments":{"limit":5}},
    "id":2
  }'
```

## 🛠️ Comandos Úteis

### Ver logs em tempo real
```bash
docker-compose logs -f
```

### Parar o container
```bash
docker-compose down
```

### Reiniciar o container
```bash
docker-compose restart
```

### Rebuild completo
```bash
docker-compose down
docker-compose up --build
```

### Acessar shell do container
```bash
docker exec -it whatsapp-mcp-server /bin/bash
```

### Ver status do WhatsApp
```bash
# Verificar se está autenticado
docker exec whatsapp-mcp-server sqlite3 /app/whatsapp-bridge/store/whatsapp.db "SELECT * FROM whatsmeow_device;"
```

## 🔍 Troubleshooting

### Container não inicia
```bash
# Ver logs completos
docker-compose logs

# Verificar se as portas estão em uso
netstat -tulpn | grep -E '8000|8080'
```

### QR Code não aparece
```bash
# Remover autenticação antiga e tentar novamente
rm -rf whatsapp-bridge/store/whatsapp.db
docker-compose restart
```

### Erro de conexão com WhatsApp
```bash
# Verificar se o bridge está rodando
curl http://localhost:8080/health

# Ver logs do bridge
docker-compose logs | grep -i whatsapp
```

### Re-autenticar após 20 dias
O WhatsApp desconecta após ~20 dias de inatividade. Para re-autenticar:

```bash
# Remover sessão antiga
rm whatsapp-bridge/store/whatsapp.db

# Reiniciar e escanear novo QR code
docker-compose restart
docker-compose logs -f
```

## 🏗️ Desenvolvimento

### Modo local (sem Docker)

Se você preferir rodar localmente:

```bash
# Terminal 1: WhatsApp Bridge
cd whatsapp-bridge
go run main.go

# Terminal 2: MCP Server em Streamable HTTP mode
cd whatsapp-mcp-server
export MCP_TRANSPORT=http
export MCP_HTTP_PORT=8000
uv pip install uvicorn fastapi
python main.py --http 8000
```

### Modo STDIO (original)

Para usar o modo STDIO tradicional (sem HTTP):

```bash
cd whatsapp-mcp-server
python main.py
```

## � Features

O MCP Server expõe as seguintes ferramentas via Streamable HTTP:

- ✅ `search_contacts`: Buscar contatos por nome/telefone
- ✅ `list_messages`: Listar mensagens com filtros e contexto
- ✅ `list_chats`: Listar conversas
- ✅ `get_chat`: Obter detalhes de uma conversa
- ✅ `send_message`: Enviar mensagens de texto
- ✅ `send_file`: Enviar arquivos (imagens, vídeos, documentos)
- ✅ `send_audio_message`: Enviar mensagens de áudio
- ✅ `download_media`: Baixar mídia de mensagens

**Nota sobre o Transport**: Este servidor usa **Streamable HTTP**, o padrão moderno do MCP que substitui o SSE legado. Streamable HTTP suporta:
- ✅ Comunicação bidirecional eficiente
- ✅ Streaming de respostas quando necessário
- ✅ Single endpoint simplificado
- ✅ Melhor escalabilidade e performance

## 🔒 Segurança

⚠️ **Atenção**: Este servidor expõe acesso às suas mensagens do WhatsApp!

- Não exponha a porta 8000 publicamente na internet
- Use em ambiente confiável apenas
- Considere adicionar autenticação se necessário
- Os dados são armazenados localmente no volume Docker

## 📄 Licença

Veja LICENSE no repositório principal.
