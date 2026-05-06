# E2E Testing Guide

## Overview

This E2E testing system provisions an ephemeral environment (DynamoDB + API + Flutter) with mocked external services (email, OpenAI) to run complete user flow tests.

## Quick Start

```bash
# From backend directory
npm run test:e2e
```

This single command will:
1. Start DynamoDB Local on port 8000
2. Create database tables
3. Start API on port 3001 with mocks enabled
4. Run the Flutter macOS integration test app
5. Run integration tests
6. Clean up everything

## Window Visibility

The UI test currently runs with `flutter test ... -d macos`, so Flutter launches a real macOS app window. Keep that window visible while the suite runs. Minimizing it or forcing it off-screen can stall the Flutter integration driver because the app may stop producing frames for `WidgetTester`.

For less disruption during local runs, use a separate macOS Space or monitor. A headless Chrome/web runner would need to be implemented and verified separately from the current macOS test path.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              E2E Test Environment                │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────┐    ┌──────────────┐           │
│  │   Flutter    │───▶│   Backend    │           │
│  │ macOS app    │    │   localhost  │           │
│  │              │    │    :3001     │           │
│  └──────────────┘    └───────┬──────┘           │
│                              │                   │
│                    ┌─────────┴─────────┐         │
│                    │                   │         │
│            ┌───────▼──────┐    ┌──────▼──────┐  │
│            │  DynamoDB     │    │   Mocks     │  │
│            │   Local       │    │ Email + AI  │  │
│            │  :8000        │    │             │  │
│            └───────────────┘    └─────────────┘  │
│                                                  │
└─────────────────────────────────────────────────┘
```

## Mock Services

### Email Service Mock

All emails are captured in memory and can be verified in tests:

```dart
// Get all sent emails
final emails = await testHelper.getMockEmails();

// Wait for specific email
final email = await testHelper.waitForEmail(
  to: 'user@example.com',
  type: 'invitation'
);

// Assertions
expect(email['to'], 'user@example.com');
expect(email['inviterName'], 'John');
```

### AI Service Mock

AI responses are deterministic and based on message content:

```dart
// Get all AI responses
final responses = await testHelper.getMockAIResponses();

// Wait for AI response
final response = await testHelper.waitForAIResponse();

// Assertions
expect(response['response'], contains('Thank you'));
```

## Writing Integration Tests

### Test File Location

```
frontend/
  integration_test/
    e2e_test_helper.dart    # Shared helper utilities
    app_test.dart           # Your tests here
```

### Example Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'e2e_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  const apiUrl = String.fromEnvironment('API_URL', 
      defaultValue: 'http://localhost:3001');
  late E2ETestHelper testHelper;
  
  setUpAll(() {
    testHelper = E2ETestHelper(apiUrl);
  });
  
  setUp(() async {
    await testHelper.resetMocks();
  });

  testWidgets('User registration sends welcome email', 
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    
    // Navigate to registration
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    
    // Fill registration form
    await tester.enterText(
      find.byKey(const Key('email_field')), 
      'test@example.com'
    );
    await tester.enterText(
      find.byKey(const Key('password_field')), 
      'Test123!'
    );
    await tester.enterText(
      find.byKey(const Key('firstName_field')), 
      'John'
    );
    
    // Submit
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    
    // Verify email was sent
    final email = await testHelper.waitForEmail(
      to: 'test@example.com',
      type: 'welcome'
    );
    
    expect(email['firstName'], 'John');
    expect(email['type'], 'welcome');
  });
}
```

## Test Helper API

### E2ETestHelper Methods

#### `resetMocks()`
Reset all mock stores (call in `setUp()`).

#### `getMockEmails()`
Get all emails sent since last reset.

#### `getMockEmailsByType(String type)`
Get emails filtered by type: `invitation`, `welcome`, `messageNotification`.

#### `getMockAIResponses()`
Get all AI responses generated.

#### `getTestStatus()`
Get current test environment configuration.

#### `findEmailByRecipient(String email)`
Find first email sent to specific recipient.

#### `waitForEmail({required String to, String? type, Duration timeout})`
Wait for email to be sent (with timeout). Useful for async operations.

#### `waitForAIResponse({Duration timeout})`
Wait for AI response to be generated.

## Test Endpoints

When `ENABLE_TEST_ENDPOINTS=true`, the API exposes:

- `GET /api/test/emails` - All mock emails
- `GET /api/test/emails/:type` - Emails by type
- `GET /api/test/ai-responses` - All AI responses  
- `POST /api/test/reset` - Reset all mocks
- `GET /api/test/status` - Environment status

## Environment Variables

The E2E runner sets these automatically:

```bash
# DynamoDB
DYNAMODB_ENDPOINT=http://localhost:8000
DYNAMODB_REGION=eu-west-3

# API Configuration
PORT=3001
MOCK_EMAIL=true
MOCK_AI=true
ENABLE_TEST_ENDPOINTS=true
NODE_ENV=test
JWT_SECRET=test-secret-{timestamp}
FRONTEND_URL=http://localhost:8080

# Flutter dart-defines
API_BASE_URL=http://localhost:3001/api
API_URL=http://localhost:3001
```

## Manual Testing

You can also run components individually for debugging:

```bash
# 1. Start DynamoDB
cd backend
npm run db:start

# 2. Create tables
DYNAMODB_ENDPOINT=http://localhost:8000 npm run db:create

# 3. Start API with mocks
DYNAMODB_ENDPOINT=http://localhost:8000 \
  MOCK_EMAIL=true \
  MOCK_AI=true \
  ENABLE_TEST_ENDPOINTS=true \
  PORT=3001 \
  npm start

# 4. In another terminal, run the Flutter macOS integration test app
cd frontend
flutter test integration_test/complete_journey_test.dart \
  -d macos \
  --dart-define=API_BASE_URL=http://localhost:3001/api \
  --dart-define=API_URL=http://localhost:3001
```

## Debugging

### Check Test Endpoint Status

```bash
curl http://localhost:3001/api/test/status | jq
```

### View Mock Emails

```bash
curl http://localhost:3001/api/test/emails | jq
```

### View AI Responses

```bash
curl http://localhost:3001/api/test/ai-responses | jq
```

### Logs

E2E runner creates log files:

- `backend/.api-e2e.log` - API server logs
- `frontend/.flutter-build-e2e.log` - Flutter build output
- `frontend/.flutter-e2e.log` - Flutter web server logs

### Process Management

PIDs are stored in `backend/.pids/`:
- `dynamodb-e2e.pid`
- `api-e2e.pid`
- `flutter-e2e.pid`

## CI/CD Integration

Add to `.github/workflows/e2e.yml`:

```yaml
name: E2E Tests

on: [pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '22'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install backend dependencies
        working-directory: backend
        run: npm install
      
      - name: Install frontend dependencies
        working-directory: frontend
        run: flutter pub get
      
      - name: Run E2E tests
        working-directory: backend
        run: npm run test:e2e
      
      - name: Upload logs on failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-logs
          path: |
            backend/.api-e2e.log
            frontend/.flutter-build-e2e.log
```

## Best Practices

1. **Reset mocks in `setUp()`** - Ensures test isolation
2. **Use `waitFor*` methods** - Handle async operations properly
3. **Test complete flows** - Registration → Invitation → Messaging
4. **Verify mocks** - Check emails sent, AI responses generated
5. **Keep tests fast** - Mock responses are instant
6. **One assertion per email/AI check** - Easier debugging

## Troubleshooting

### "Test endpoints not available"

Ensure `ENABLE_TEST_ENDPOINTS=true` is set when starting API.

### "Email not found"

Check if the action that should send the email is actually executing. View logs at `backend/.api-e2e.log`.

### "DynamoDB failed to start"

Port 8000 might be in use. Check: `lsof -i :8000`

### "API failed to start"

Check API logs: `tail -f backend/.api-e2e.log`

### Tests hang

Make sure cleanup runs. Check for zombie processes:
```bash
ps aux | grep -E 'dynamodb|node|python'
```

## Examples

See `frontend/integration_test/e2e_test_helper.dart` for working examples of:
- Environment verification
- Mock email testing
- Mock AI testing
- Helper method usage
