#!/bin/bash

# Smart Development Script for We Counsel Backend
# Handles DynamoDB Local + Express server with automatic table creation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
log() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if port is in use
check_port() {
    local port=$1
    lsof -i :$port > /dev/null 2>&1
}

# Function to kill process on port
kill_port() {
    local port=$1
    local pids=$(lsof -ti :$port 2>/dev/null || true)
    if [ ! -z "$pids" ]; then
        log $YELLOW "🛑 Stopping process on port $port..."
        echo $pids | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local port=$1
    local service_name=$2
    local max_attempts=30
    local attempt=0
    
    log $BLUE "⏳ Waiting for $service_name to be ready..."
    
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

# Function to start DynamoDB Local with table creation
start_dynamo_with_tables() {
    log $CYAN "🚀 Starting DynamoDB Local..."
    
    # Start DynamoDB Local in background
    npm run dynamodb > /dev/null 2>&1 &
    local dynamo_pid=$!
    
    # Wait for DynamoDB to be ready
    if wait_for_service 8000 "DynamoDB Local"; then
        log $BLUE "🗄️  Creating database tables..."
        if npm run setup:db; then
            log $GREEN "✅ Database tables created successfully"
            echo $dynamo_pid > .dynamo.pid
            return 0
        else
            log $RED "❌ Failed to create database tables"
            kill $dynamo_pid 2>/dev/null || true
            return 1
        fi
    else
        kill $dynamo_pid 2>/dev/null || true
        return 1
    fi
}

# Main development function
run_dev() {
    local should_reset=$1
    
    log $CYAN "🎯 Starting We Counsel development environment..."
    
    # Handle reset if requested
    if [ "$should_reset" = "true" ]; then
        log $YELLOW "🔄 Resetting development environment..."
        kill_port 8000  # DynamoDB Local
        kill_port 3000  # Express server
        rm -f .dynamo.pid .server.pid
        sleep 2
    fi
    
    # Check current state
    local dynamo_running=false
    local server_running=false
    
    if check_port 8000; then
        dynamo_running=true
        log $GREEN "✅ DynamoDB Local already running on port 8000"
    fi
    
    if check_port 3000; then
        server_running=true
        log $GREEN "✅ Express server already running on port 3000"
    fi
    
    # Start DynamoDB if needed
    if [ "$dynamo_running" = "false" ] || [ "$should_reset" = "true" ]; then
        if ! start_dynamo_with_tables; then
            log $RED "❌ Failed to start DynamoDB Local"
            exit 1
        fi
    fi
    
    # Start Express server if needed
    if [ "$server_running" = "false" ] || [ "$should_reset" = "true" ]; then
        log $CYAN "🚀 Starting Express server..."
        npx nodemon src/server.js &
        local server_pid=$!
        echo $server_pid > .server.pid
        
        if wait_for_service 3000 "Express server"; then
            log $GREEN "✅ Express server started successfully"
        else
            log $RED "❌ Failed to start Express server"
            exit 1
        fi
    fi
    
    log $GREEN "🎉 Development environment ready!"
    log $BLUE "📊 DynamoDB Local: http://localhost:8000"
    log $BLUE "🔗 API Server: http://localhost:3000"
    log $BLUE "🏥 Health Check: http://localhost:3000/health"
    log $YELLOW "\nPress Ctrl+C to stop services or run 'npm run dev:stop' to stop cleanly"
    
    # Keep script running to handle Ctrl+C
    trap 'log $YELLOW "\n🛑 Shutting down..."; kill_port 8000; kill_port 3000; rm -f .dynamo.pid .server.pid; exit 0' INT TERM
    
    # Wait for processes to finish (or user to Ctrl+C)
    wait
}

# Parse arguments
if [ "$1" = "reset" ]; then
    run_dev true
else
    run_dev false
fi
