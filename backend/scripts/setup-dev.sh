#!/bin/bash

# Improved Development Setup Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${1}${2}${NC}"
}

print_banner() {
    log $PURPLE "╔══════════════════════════════════════════════════════════════╗"
    log $PURPLE "║                    WE COACH DEV SETUP                        ║"
    log $PURPLE "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

check_dependencies() {
    log $CYAN "🔍 Checking dependencies..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log $RED "❌ Node.js is not installed"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log $RED "❌ npm is not installed"
        exit 1
    fi
    
    log $GREEN "✅ Dependencies check passed"
}

setup_environment() {
    log $CYAN "⚙️  Setting up development environment..."
    
    # Start DynamoDB Local
    log $BLUE "🗄️  Starting DynamoDB Local..."
    ./scripts/dynamodb-manager.sh start
    
    if [ $? -ne 0 ]; then
        log $RED "❌ Failed to start DynamoDB Local"
        exit 1
    fi
    
    # Setup database tables and seed data
    log $BLUE "📋 Setting up database tables..."
    if npm run setup:db; then
        log $GREEN "✅ Database tables created"
        
        log $BLUE "🌱 Seeding database with test data..."
        if npm run seed:db; then
            log $GREEN "✅ Database seeded successfully"
        else
            log $YELLOW "⚠️  Database seeding failed, but you can continue development"
        fi
    else
        log $RED "❌ Failed to create database tables"
        exit 1
    fi
}

print_info() {
    echo ""
    log $GREEN "🎉 Development environment is ready!"
    echo ""
    log $BLUE "📊 Services:"
    log $BLUE "   • DynamoDB Local: http://localhost:8000"
    log $BLUE "   • DynamoDB Web Shell: http://localhost:8000/shell"
    log $BLUE "   • API Server: http://localhost:3000 (will start with npm run dev)"
    log $BLUE "   • Health Check: http://localhost:3000/health"
    echo ""
    log $YELLOW "👥 Test Users Created:"
    log $YELLOW "   • john@example.com / password123"
    log $YELLOW "   • jane@example.com / password123"
    echo ""
    log $CYAN "🛠️  Development Commands:"
    log $CYAN "   • npm run dev          - Start API server with hot reload"
    log $CYAN "   • npm run db:status    - Check DynamoDB status"
    log $CYAN "   • npm run db:reset     - Reset database with fresh seed data"
    log $CYAN "   • npm run db:stop      - Stop DynamoDB Local"
    log $CYAN "   • npm run db:logs      - View DynamoDB logs"
    echo ""
    log $GREEN "Ready to start coding! Run 'npm run dev' to start the API server."
    echo ""
}

main() {
    print_banner
    check_dependencies
    setup_environment
    print_info
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
