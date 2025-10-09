#!/bin/bash

# Development Server Management Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${1}${2}${NC}"
}

check_port() {
    lsof -i :$1 > /dev/null 2>&1
}

kill_port() {
    local port=$1
    local pids=$(lsof -ti :$port 2>/dev/null || true)
    if [ ! -z "$pids" ]; then
        echo $pids | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

wait_for_service() {
    local port=$1
    local service_name=$2
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            log $GREEN "✅ $service_name is ready on port $port"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log $RED "❌ $service_name failed to start on port $port"
    return 1
}

case "$1" in
    "logs")
        log $CYAN "📋 Showing server logs (if running)..."
        
        if ! check_port 3000; then
            log $RED "❌ Express server is not running!"
            log $YELLOW "💡 Run 'npm run dev:full' to start it"
            exit 1
        fi
        
        log $YELLOW "📋 Connecting to server logs... Press Ctrl+C to exit"
        echo ""
        
        # Find the nodemon process and show its logs
        server_pid=$(lsof -ti :3000 2>/dev/null | head -1)
        if [ ! -z "$server_pid" ]; then
            # This will show ongoing logs, but nodemon logs to stdout
            # For better log viewing, we recommend restarting with npm run dev
            log $YELLOW "💡 For live logs, use 'npm run dev' to restart the server"
            log $BLUE "🔗 API Server: http://localhost:3000"
            log $BLUE "🏥 Health Check: http://localhost:3000/health"
        fi
        ;;
        
    "server")
        log $CYAN "🔄 Restarting Express server only..."
        
        # Check if DynamoDB is running
        if ! check_port 8000; then
            log $RED "❌ DynamoDB Local is not running! Please run 'npm run dev:reset' first."
            exit 1
        fi
        
        # Stop server if running
        if check_port 3000; then
            log $YELLOW "🛑 Stopping Express server..."
            kill_port 3000
        fi
        
        # Start server in foreground to show logs
        log $CYAN "🚀 Starting Express server..."
        log $YELLOW "📋 Server logs will appear below. Press Ctrl+C to stop."
        log $BLUE "🔗 API Server: http://localhost:3000"
        log $BLUE "🏥 Health Check: http://localhost:3000/health"
        echo ""
        
        # Run nodemon in foreground to show logs
        npx nodemon src/server.js
        ;;
        
    "full")
        log $CYAN "🎯 Starting full development environment..."
        
        # Check current state
        dynamo_running=false
        server_running=false
        
        if check_port 8000; then
            dynamo_running=true
            log $GREEN "✅ DynamoDB Local already running"
        fi
        
        if check_port 3000; then
            server_running=true
            log $GREEN "✅ Express server already running"
        fi
        
        # Start DynamoDB if needed
        if [ "$dynamo_running" = "false" ]; then
            log $CYAN "🚀 Starting DynamoDB Local..."
            npm run dynamodb > /dev/null 2>&1 &
            
            if wait_for_service 8000 "DynamoDB Local"; then
                log $BLUE "🗄️  Creating database tables..."
                if npm run setup:db; then
                    log $GREEN "✅ Database tables created"
                else
                    log $RED "❌ Failed to create tables"
                    exit 1
                fi
            else
                log $RED "❌ Failed to start DynamoDB Local"
                exit 1
            fi
        fi
        
        # Start server if needed
        if [ "$server_running" = "false" ]; then
            log $GREEN "🎉 Development environment ready!"
            log $BLUE "📊 DynamoDB Local: http://localhost:8000"
            log $BLUE "🔗 API Server: http://localhost:3000"
            log $BLUE "🏥 Health Check: http://localhost:3000/health"
            log $YELLOW "📋 Server logs will appear below. Press Ctrl+C to stop."
            echo ""
            
            # Run nodemon in foreground to show logs
            npx nodemon src/server.js
        else
            log $GREEN "🎉 Development environment ready!"
            log $BLUE "📊 DynamoDB Local: http://localhost:8000"
            log $BLUE "🔗 API Server: http://localhost:3000 (already running)"
            log $YELLOW "💡 Use 'npm run dev' to restart the server and see logs"
        fi
        ;;
        
    *)
        log $RED "Usage: $0 {server|full|logs}"
        log $YELLOW "  server - Restart only the Express server (shows logs)"
        log $YELLOW "  full   - Start full environment (DynamoDB + Server)"
        log $YELLOW "  logs   - Check if server is running and show connection info"
        exit 1
        ;;
esac
