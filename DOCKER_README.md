# 🐳 Docker Deployment - Changelog

## ✅ O que foi corrigido

### 1. **Problema do binário Go**
- ❌ **Antes**: Multi-stage build compilava no Alpine, copiava binário para Debian → incompatível
- ✅ **Agora**: Single-stage com Go + Python, roda `go run main.go` diretamente

### 2. **Transport Protocol atualizado**
- ❌ **Antes**: SSE (Server-Sent Events) - protocolo legado
- ✅ **Agora**: **Streamable HTTP** - padrão moderno do MCP
  - Bidirecional
  - Single endpoint (`/mcp/v1/`)
  - Melhor performance e escalabilidade

### 3. **Dependências adicionadas**
- ✅ `uvicorn` - ASGI server
- ✅ `fastapi` - Framework web (usado pelo FastMCP)

### 4. **Script helper criado**
- ✅ `mcp.sh` - Comandos úteis para gerenciar o container
- Ver QR code, testar endpoints, reset auth, etc.

## 🚀 Como usar agora

### Quick Start

```bash
# Método 1: Com script helper (recomendado)
chmod +x mcp.sh
./mcp.sh start

# Método 2: Docker Compose direto
docker-compose up --build
```

### Primeira vez - Autenticação

O QR code aparecerá automaticamente no terminal. Escaneie com:
1. WhatsApp > Configurações > Dispositivos Conectados > Conectar Dispositivo
2. Aguarde sincronização do histórico

### Após autenticar

O servidor ficará disponível em:
- **MCP Streamable HTTP**: `http://localhost:8000/mcp/v1/`
- **WhatsApp Bridge API**: `http://localhost:8080` (interno)

### Testar funcionamento

```bash
# Com script helper
./mcp.sh test        # Lista ferramentas disponíveis
./mcp.sh test-chats  # Lista últimos 5 chats

# Manualmente com cURL
curl -X POST http://localhost:8000/mcp/v1/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' \
  | jq .
```

## 📚 Documentação

Consulte `DOCKER_DEPLOYMENT.md` para documentação completa incluindo:
- Arquitetura e fluxo de dados
- Configuração de clientes (Claude Desktop, Python, etc)
- Troubleshooting
- Comandos úteis

## 🔄 Fluxo de Dados

```
WhatsApp Web
    ↓
Go Bridge (main.go) - roda continuamente
    ↓
SQLite Local (store/messages.db)
    ↓
Python MCP Server (Streamable HTTP)
    ↓
Clientes (Claude, Cursor, etc) via HTTP
```

## 🛠️ Comandos Rápidos

```bash
./mcp.sh start       # Iniciar e ver QR code
./mcp.sh logs        # Ver logs
./mcp.sh test        # Testar endpoint
./mcp.sh status      # Ver status
./mcp.sh stop        # Parar
./mcp.sh reset-auth  # Re-autenticar
./mcp.sh             # Ver todos os comandos
```

## 📦 Arquivos Criados/Modificados

### Novos arquivos
- ✅ `Dockerfile` - Build único com Go + Python
- ✅ `docker-compose.yml` - Configuração do serviço
- ✅ `docker-entrypoint.sh` - Script de inicialização
- ✅ `DOCKER_DEPLOYMENT.md` - Documentação completa
- ✅ `mcp.sh` - Script helper com comandos úteis
- ✅ `.dockerignore` - Otimização do build

### Arquivos modificados
- ✅ `whatsapp-mcp-server/main.py` - Suporte a Streamable HTTP
- ✅ `whatsapp-mcp-server/pyproject.toml` - Dependências adicionadas

## 🔒 Segurança

⚠️ **Importante**: 
- Não exponha a porta 8000 publicamente
- Use em ambiente confiável
- Os dados são locais (volume Docker)
- A autenticação WhatsApp é persistida em `whatsapp-bridge/store/`

## 💡 Diferenças entre Transports

| Transport | Uso | Latência | Remoto | Escalável |
|-----------|-----|----------|--------|-----------|
| **stdio** | CLI local | <1ms | Não | Não |
| **Streamable HTTP** | Web/API | ~10-50ms | Sim | Sim |
| SSE (legado) | Antigo | Alta | Sim | Limitado |

Este projeto usa **Streamable HTTP** - o padrão moderno e recomendado!

## 🐛 Troubleshooting

### Container não inicia
```bash
./mcp.sh logs  # Ver erros
```

### QR code não aparece
```bash
./mcp.sh reset-auth  # Remover auth antiga
./mcp.sh start       # Iniciar novamente
```

### Testar se está funcionando
```bash
./mcp.sh test        # Testa endpoint MCP
./mcp.sh test-chats  # Testa query real
```

### Re-autenticar (após 20 dias)
```bash
./mcp.sh reset-auth
./mcp.sh start
# Escanear novo QR code
```

## 📄 Licença

Veja LICENSE no repositório.
