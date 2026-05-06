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
FOCUS_RESTORER_PID=""

stop_focus_restorer() {
    if [ -n "$FOCUS_RESTORER_PID" ] && ps -p "$FOCUS_RESTORER_PID" > /dev/null 2>&1; then
        echo "  Stopping focus restorer (PID: $FOCUS_RESTORER_PID)"
        kill "$FOCUS_RESTORER_PID" 2>/dev/null || true
        wait "$FOCUS_RESTORER_PID" 2>/dev/null || true
    fi
}

start_focus_restorer() {
    if [ "${E2E_KEEP_FOCUS:-0}" != "1" ]; then
        return
    fi

    if [ "$(uname -s)" != "Darwin" ]; then
        echo -e "  ${YELLOW}⚠️  E2E_KEEP_FOCUS is only supported on macOS${NC}"
        return
    fi

    local restore_app
    restore_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)

    if [ -z "$restore_app" ]; then
        echo -e "  ${YELLOW}⚠️  Could not detect current frontmost app; focus restorer disabled${NC}"
        return
    fi

    local test_app_pattern="${E2E_FOCUS_TEST_APP_PATTERN:-^(we_counsel|Runner)$}"
    local interval="${E2E_KEEP_FOCUS_INTERVAL:-0.7}"

    (
        last_non_test_app="$restore_app"
        while true; do
            front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)

            if [[ "$front_app" =~ $test_app_pattern ]]; then
                if [ -n "$last_non_test_app" ]; then
                    osascript -e "tell application \"$last_non_test_app\" to activate" >/dev/null 2>&1 || true
                fi
            elif [ -n "$front_app" ]; then
                last_non_test_app="$front_app"
            fi

            sleep "$interval"
        done
    ) &

    FOCUS_RESTORER_PID=$!
    echo -e "  ${GREEN}✅ Focus restorer enabled; returning focus to '$restore_app' when the Flutter test app activates${NC}"
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    
    # Stop optional macOS focus restorer
    stop_focus_restorer

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

#############################################
# 0. Pre-flight Check: Detect existing processes
#############################################
echo -e "${YELLOW}🔍 Pre-flight check: Detecting existing processes...${NC}\n"

# Check for existing server.js processes
EXISTING_SERVER=$(ps aux | grep "node.*src/server.js" | grep -v grep | awk '{print $2}')
if [ ! -z "$EXISTING_SERVER" ]; then
    echo -e "${RED}❌ ERROR: Existing API server process(es) detected!${NC}"
    echo -e "${RED}   PID(s): $EXISTING_SERVER${NC}"
    echo -e "${YELLOW}   These processes may interfere with E2E tests.${NC}"
    echo -e "${YELLOW}   Please stop them manually or run: kill $EXISTING_SERVER${NC}\n"
    exit 1
fi

# Check if ports are in use
if lsof -Pi :$API_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    PORT_PID=$(lsof -Pi :$API_PORT -sTCP:LISTEN -t)
    echo -e "${RED}❌ ERROR: Port $API_PORT is already in use!${NC}"
    echo -e "${RED}   Process PID: $PORT_PID${NC}"
    echo -e "${YELLOW}   Please stop the process or run: kill $PORT_PID${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ Pre-flight check passed - no conflicting processes${NC}\n"

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
export MOCK_STRIPE=true
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

# Run API tests first (fast)
echo -e "${YELLOW}Running API tests...${NC}\n"

echo -e "${BLUE}Test 1: Subscription Quotas${NC}"
node "$BACKEND_DIR/test-quota.js"
QUOTA_EXIT_CODE=$?

if [ $QUOTA_EXIT_CODE -ne 0 ]; then
    echo -e "\n${RED}❌ Quota tests failed${NC}"
    exit 1
fi

# Run UI integration test
# caffeinate -i prevents App Nap from throttling the test app when unfocused
echo -e "\n${YELLOW}Running UI integration test...${NC}"
cd "$FRONTEND_DIR"
start_focus_restorer
caffeinate -i flutter test integration_test/complete_journey_test.dart \
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
