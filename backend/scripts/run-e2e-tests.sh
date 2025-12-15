#!/bin/bash

#############################################
# E2E Test Runner
# Provisions ephemeral environment, runs tests, tears down
#############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DYNAMODB_PORT=8000
API_PORT=3001
FLUTTER_PORT=8080
TEST_PREFIX="e2e-test-$(date +%s)"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"

# PID file locations
PID_DIR="$BACKEND_DIR/.pids"
mkdir -p "$PID_DIR"

DYNAMODB_PID_FILE="$PID_DIR/dynamodb-e2e.pid"
API_PID_FILE="$PID_DIR/api-e2e.pid"
FLUTTER_PID_FILE="$PID_DIR/flutter-e2e.pid"

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    
    # No Flutter server to stop (integration tests launch app directly)
    
    # Stop API
    if [ -f "$API_PID_FILE" ]; then
        API_PID=$(cat "$API_PID_FILE")
        if ps -p "$API_PID" > /dev/null 2>&1; then
            echo "  Stopping API (PID: $API_PID)"
            kill "$API_PID" 2>/dev/null || true
            sleep 1
        fi
        rm -f "$API_PID_FILE"
    fi
    
    # Stop DynamoDB
    if [ -f "$DYNAMODB_PID_FILE" ]; then
        DYNAMO_PID=$(cat "$DYNAMODB_PID_FILE")
        if ps -p "$DYNAMO_PID" > /dev/null 2>&1; then
            echo "  Stopping DynamoDB (PID: $DYNAMO_PID)"
            kill "$DYNAMO_PID" 2>/dev/null || true
            sleep 1
        fi
        rm -f "$DYNAMODB_PID_FILE"
    fi
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Trap signals for cleanup
trap cleanup EXIT INT TERM

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       E2E Test Environment Setup     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}\n"

#############################################
# 1. Start DynamoDB
#############################################
echo -e "${YELLOW}📦 Step 1: Starting DynamoDB on port $DYNAMODB_PORT${NC}"

cd "$BACKEND_DIR"

# Use existing dynamodb-manager.sh
./scripts/dynamodb-manager.sh start

# Save PID
if [ -f "$BACKEND_DIR/.dynamodb.pid" ]; then
    cp "$BACKEND_DIR/.dynamodb.pid" "$DYNAMODB_PID_FILE"
fi

# Wait for DynamoDB to be ready
echo "  Waiting for DynamoDB to be ready..."
for i in {1..30}; do
    if curl -s "http://localhost:$DYNAMODB_PORT" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ DynamoDB is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "  ${RED}❌ DynamoDB failed to start${NC}"
        exit 1
    fi
    sleep 1
done

#############################################
# 2. Provision Database
#############################################
echo -e "\n${YELLOW}🗄️  Step 2: Provisioning database schema${NC}"

export DYNAMODB_ENDPOINT="http://localhost:$DYNAMODB_PORT"
export DYNAMODB_REGION="eu-west-3"

npm run db:create

echo -e "  ${GREEN}✅ Database schema created${NC}"

#############################################
# 3. Start API with mocks
#############################################
echo -e "\n${YELLOW}🚀 Step 3: Starting API on port $API_PORT with mocks enabled${NC}"

export PORT=$API_PORT
export MOCK_EMAIL=true
export MOCK_AI=true
export ENABLE_TEST_ENDPOINTS=true
export NODE_ENV=test
export JWT_SECRET="test-secret-$(date +%s)"
export FRONTEND_URL="http://localhost:$FLUTTER_PORT"

# Start API in background
node src/server.js > "$BACKEND_DIR/.api-e2e.log" 2>&1 &
API_PID=$!
echo $API_PID > "$API_PID_FILE"

echo "  API started with PID: $API_PID"
echo "  Logs: $BACKEND_DIR/.api-e2e.log"

# Wait for API to be ready
echo "  Waiting for API to be ready..."
for i in {1..30}; do
    if curl -s "http://localhost:$API_PORT/health" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ API is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "  ${RED}❌ API failed to start${NC}"
        echo "  Last 20 lines of log:"
        tail -20 "$BACKEND_DIR/.api-e2e.log"
        exit 1
    fi
    sleep 1
done

# Verify test endpoints
if curl -s "http://localhost:$API_PORT/api/test/status" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Test endpoints enabled${NC}"
else
    echo -e "  ${RED}❌ Test endpoints not available${NC}"
    exit 1
fi

#############################################
# 4. Prepare Flutter App
#############################################
echo -e "\n${YELLOW}🎨 Step 4: Preparing Flutter app for testing${NC}"

cd "$FRONTEND_DIR"

# No need to build or start server - integration tests will launch the app directly
echo -e "  ${GREEN}✅ Flutter ready for integration testing on macOS${NC}"

#############################################
# 5. Run E2E Tests
#############################################
echo -e "\n${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Running E2E Tests           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}\n"

cd "$FRONTEND_DIR"

# Run integration tests on macOS desktop (officially supported by integration_test)
flutter test integration_test/complete_journey_test.dart \
    -d macos \
    --dart-define=API_BASE_URL=http://localhost:$API_PORT/api

TEST_EXIT_CODE=$?

#############################################
# 6. Report Results
#############################################
echo -e "\n${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Test Results              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}\n"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All E2E tests passed!${NC}\n"
else
    echo -e "${RED}❌ E2E tests failed${NC}\n"
    
    echo -e "${YELLOW}📊 Environment Status:${NC}"
    echo "  DynamoDB: http://localhost:$DYNAMODB_PORT"
    echo "  API: http://localhost:$API_PORT"
    echo ""
    echo -e "${YELLOW}📝 Logs:${NC}"
    echo "  API: $BACKEND_DIR/.api-e2e.log"
fi

# Cleanup will run automatically via trap

exit $TEST_EXIT_CODE
