# Single stage build with Go + Python
FROM python:3.11-slim

# Install system dependencies including Go
RUN apt-get update && apt-get install -y \
    sqlite3 \
    ffmpeg \
    wget \
    curl \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz && \
    rm go1.21.5.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin

# Install uv
RUN pip install uv

# Create app directory
WORKDIR /app

# Copy and setup Go bridge
COPY whatsapp-bridge/ /app/whatsapp-bridge/
WORKDIR /app/whatsapp-bridge
RUN go mod download

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
