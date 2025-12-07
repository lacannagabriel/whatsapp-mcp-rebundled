#!/bin/bash
set -e

echo "Starting WhatsApp MCP Server..."

# Start the WhatsApp bridge in the background
echo "Starting WhatsApp Bridge on port 8080..."
cd /app/whatsapp-bridge
./whatsapp-bridge &
BRIDGE_PID=$!

echo "Waiting for WhatsApp Bridge to be ready..."
# Wait for the bridge to be ready (max 30 seconds)
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "WhatsApp Bridge is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "WhatsApp Bridge failed to start in time"
        exit 1
    fi
    sleep 1
done

# Check if this is the first run (no session)
if [ ! -f "/app/whatsapp-bridge/store/whatsapp.db" ]; then
    echo ""
    echo "===================================================================================="
    echo "FIRST TIME SETUP: You need to scan the QR code to authenticate with WhatsApp"
    echo "===================================================================================="
    echo ""
    echo "Please check the WhatsApp Bridge logs above for the QR code."
    echo "You can also access it via: docker logs -f whatsapp-mcp-server"
    echo ""
    echo "After scanning the QR code, the server will continue starting..."
    echo "===================================================================================="
    echo ""
    
    # Give some time for QR code scanning
    sleep 10
fi

# Start the MCP server in HTTP mode
echo "Starting MCP Server in Streamable HTTP mode on port ${MCP_HTTP_PORT}..."
cd /app/whatsapp-mcp-server

# Set transport mode to HTTP via environment variable
export MCP_TRANSPORT=http

# Run the Python MCP server with Streamable HTTP transport
python main.py --http ${MCP_HTTP_PORT}

# If the MCP server exits, kill the bridge too
kill $BRIDGE_PID 2>/dev/null || true
