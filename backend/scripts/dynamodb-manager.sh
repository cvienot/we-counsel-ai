#!/bin/bash

# DynamoDB Local Management Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DYNAMODB_DIR="$PROJECT_ROOT/.dynamodb"
PID_FILE="$DYNAMODB_DIR/dynamodb.pid"
LOG_FILE="$DYNAMODB_DIR/dynamodb.log"

log() {
    echo -e "${1}${2}${NC}"
}

# Create DynamoDB directory if it doesn't exist
mkdir -p "$DYNAMODB_DIR"

check_port() {
    lsof -i :8000 > /dev/null 2>&1
}

is_dynamodb_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    else
        return 1
    fi
}

start_dynamodb() {
    if is_dynamodb_running; then
        log $GREEN "✅ DynamoDB Local is already running (PID: $(cat "$PID_FILE"))"
        return 0
    fi

    if check_port; then
        log $YELLOW "⚠️  Port 8000 is in use by another process. Killing it..."
        lsof -ti :8000 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi

    log $CYAN "🚀 Starting DynamoDB Local..."
    
    # Start DynamoDB Local in the background using Node.js script
    cd "$PROJECT_ROOT"
    nohup node scripts/start-dynamodb.js > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    # Wait for DynamoDB to be ready
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port; then
            log $GREEN "✅ DynamoDB Local started successfully (PID: $pid)"
            log $BLUE "📊 DynamoDB Web Shell: http://localhost:8000/shell"
            log $BLUE "📁 Data directory: $DYNAMODB_DIR"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log $RED "❌ DynamoDB Local failed to start"
    return 1
}

stop_dynamodb() {
    if is_dynamodb_running; then
        local pid=$(cat "$PID_FILE")
        log $YELLOW "🛑 Stopping DynamoDB Local (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
        sleep 2
        
        if check_port; then
            log $YELLOW "⚠️  Force killing DynamoDB on port 8000..."
            lsof -ti :8000 | xargs kill -9 2>/dev/null || true
        fi
        
        log $GREEN "✅ DynamoDB Local stopped"
    else
        log $YELLOW "⚠️  DynamoDB Local is not running"
    fi
}

status_dynamodb() {
    if is_dynamodb_running; then
        local pid=$(cat "$PID_FILE")
        log $GREEN "✅ DynamoDB Local is running (PID: $pid)"
        log $BLUE "📊 Web Shell: http://localhost:8000/shell"
        log $BLUE "📁 Data directory: $DYNAMODB_DIR"
        log $BLUE "📝 Log file: $LOG_FILE"
    else
        log $RED "❌ DynamoDB Local is not running"
    fi
}

restart_dynamodb() {
    log $CYAN "🔄 Restarting DynamoDB Local..."
    stop_dynamodb
    sleep 1
    start_dynamodb
}

reset_data() {
    log $YELLOW "🗑️  Resetting DynamoDB data..."
    stop_dynamodb
    rm -rf "$DYNAMODB_DIR"/*.db
    rm -rf "$DYNAMODB_DIR"/shared-local-instance.db
    start_dynamodb
    
    if [ $? -eq 0 ]; then
        log $BLUE "📋 Setting up database tables..."
        cd "$PROJECT_ROOT"
        if npm run setup:db; then
            log $GREEN "✅ Database tables created"
            
            # Wait a moment for tables to be fully ready
            sleep 2
            
            log $BLUE "🌱 Seeding database with test data..."
            if npm run seed:db; then
                log $GREEN "✅ Database seeded with test data"
            else
                log $YELLOW "⚠️  Database seeding failed, but tables are ready"
            fi
        else
            log $RED "❌ Failed to create database tables"
        fi
    fi
}

logs_dynamodb() {
    if [ -f "$LOG_FILE" ]; then
        log $BLUE "📝 DynamoDB Local logs:"
        tail -f "$LOG_FILE"
    else
        log $YELLOW "⚠️  No log file found"
    fi
}

case "${1:-start}" in
    "start")
        start_dynamodb
        ;;
    "stop")
        stop_dynamodb
        ;;
    "restart")
        restart_dynamodb
        ;;
    "status")
        status_dynamodb
        ;;
    "reset")
        reset_data
        ;;
    "logs")
        logs_dynamodb
        ;;
    *)
        log $RED "Usage: $0 {start|stop|restart|status|reset|logs}"
        log $YELLOW "  start   - Start DynamoDB Local in background"
        log $YELLOW "  stop    - Stop DynamoDB Local"
        log $YELLOW "  restart - Restart DynamoDB Local"
        log $YELLOW "  status  - Check DynamoDB Local status"
        log $YELLOW "  reset   - Reset data and recreate tables with seed data"
        log $YELLOW "  logs    - Show DynamoDB Local logs"
        exit 1
        ;;
esac
