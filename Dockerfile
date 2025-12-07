# Multi-stage build for WhatsApp MCP Server
FROM golang:1.21-alpine AS go-builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev sqlite-dev

# Build WhatsApp bridge
WORKDIR /app/whatsapp-bridge
COPY whatsapp-bridge/go.mod whatsapp-bridge/go.sum ./
RUN go mod download
COPY whatsapp-bridge/ ./
RUN CGO_ENABLED=1 go build -o whatsapp-bridge main.go

# Python stage
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sqlite3 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv

# Create app directory
WORKDIR /app

# Copy Go bridge binary
COPY --from=go-builder /app/whatsapp-bridge/whatsapp-bridge /app/whatsapp-bridge/whatsapp-bridge

# Copy Python MCP server
COPY whatsapp-mcp-server/ /app/whatsapp-mcp-server/

# Install Python dependencies
WORKDIR /app/whatsapp-mcp-server
RUN uv pip install --system -r pyproject.toml

# Create store directory for databases
RUN mkdir -p /app/whatsapp-bridge/store

# Copy startup script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Expose port for MCP HTTP server
EXPOSE 8000

# Set environment variables
ENV WHATSAPP_BRIDGE_URL=http://localhost:8080
ENV MCP_HTTP_PORT=8000

WORKDIR /app

ENTRYPOINT ["/app/docker-entrypoint.sh"]
