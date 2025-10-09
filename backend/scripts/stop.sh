#!/bin/bash

# Stop Development Services Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${1}${2}${NC}"
}

log $YELLOW "🛑 Stopping We Counsel development services..."

# Kill DynamoDB Local (port 8000)
dynamo_pids=$(lsof -ti :8000 2>/dev/null || true)
if [ ! -z "$dynamo_pids" ]; then
    log $YELLOW "🛑 Stopping DynamoDB Local..."
    echo $dynamo_pids | xargs kill -9 2>/dev/null || true
    log $GREEN "✅ DynamoDB Local stopped"
else
    log $GREEN "✅ DynamoDB Local was not running"
fi

# Kill Express server (port 3000)
server_pids=$(lsof -ti :3000 2>/dev/null || true)
if [ ! -z "$server_pids" ]; then
    log $YELLOW "🛑 Stopping Express server..."
    echo $server_pids | xargs kill -9 2>/dev/null || true
    log $GREEN "✅ Express server stopped"
else
    log $GREEN "✅ Express server was not running"
fi

# Clean up PID files
rm -f .dynamo.pid .server.pid

log $GREEN "🎉 All development services stopped!"
