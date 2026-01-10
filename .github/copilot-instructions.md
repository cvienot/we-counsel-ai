<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# We Counsel - Couples Coaching App

## Project Overview
Full-stack coaching application for couples with AI relationship coach, partner messaging, and subscription management.

## Technology Stack

### Backend
- **Runtime**: Node.js with Express.js
- **Database**: AWS DynamoDB (local for dev: localhost:8000)
- **Authentication**: JWT with bcryptjs
- **AI Integration**: OpenAI GPT-5.2 with streaming responses
- **Email**: AWS SES (mock in dev mode)
- **Payments**: Stripe (Checkout, Customer Portal, Webhooks)
- **API Port**: 3001

### Frontend
- **Framework**: Flutter web (Dart)
- **State Management**: Riverpod
- **Routing**: go_router
- **Dev Port**: 8080
- **Localization**: English & French (l10n)

## Key Features Implemented

### Authentication & Users
- Registration with email/password
- JWT-based authentication
- Partner invitation system via email
- User profiles with couple linking

### Conversations & Messaging
- Unlimited partner-to-partner messaging
- AI coach conversations (quota-limited)
- Real-time message streaming
- Conversation summaries (after 20+ messages)
- Message history with context

### Subscription System
- **Free Tier**: 10 AI messages/month
- **Essential**: 100 AI messages/month (€9.99/mo or €95.90/year)
- **Premium**: Unlimited AI messages (€19.99/mo or €191.90/year)
- Quota enforcement middleware
- Monthly usage tracking
- Subscription status management

### Payment Portal (NEW)
- Stripe Checkout integration
- Customer Portal access
- Billing history with invoices
- Plan selection with monthly/annual billing
- Webhook automation for subscription lifecycle
- Usage counter resets
- Payment success/failure handling

## Project Structure

### Backend (`/backend`)
```
src/
├── server.js              # Express server setup
├── config/
│   ├── database.js        # DynamoDB client & tables
│   └── secrets.js         # AWS Secrets Manager
├── middleware/
│   ├── authMiddleware.js  # JWT verification
│   └── subscriptionMiddleware.js  # Quota checks
├── routes/
│   ├── auth.js           # Login, register, logout
│   ├── users.js          # User management
│   ├── conversations.js  # Conversation CRUD
│   ├── messages.js       # Messages & AI coach
│   ├── subscriptions.js  # Subscription management
│   └── payments.js       # Stripe integration (NEW)
├── services/
│   ├── aiService.js      # OpenAI integration
│   ├── emailService.js   # AWS SES emails
│   ├── subscriptionService.js  # Subscription logic
│   ├── streamingService.js     # Real-time updates
│   └── stripeService.js  # Stripe operations (NEW)
└── models/               # Data models

scripts/
├── run-e2e-tests.sh     # E2E test orchestration
├── setup-database.js    # DynamoDB table creation
└── ...                  # Dev environment scripts

test/
├── test-quota.js        # Subscription quota tests
└── test-summarization.js # AI summarization tests
```

### Frontend (`/frontend`)
```
lib/
├── main.dart            # App entry point with routing
├── config/
│   ├── app_config.dart  # API configuration
│   └── environment.dart # Environment detection
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   └── language_provider.dart  # Localization
├── screens/
│   ├── auth/            # Login, register, invitation
│   ├── home/            # Home dashboard
│   ├── conversations/   # Conversation list & view
│   ├── main_thread/     # Main coaching thread
│   ├── profile/         # User profile
│   ├── invite/          # Partner invitation
│   ├── settings/
│   │   ├── payment_portal_screen.dart     # Payment management (NEW)
│   │   ├── billing_history_screen.dart    # Invoice history (NEW)
│   │   └── payment_success_screen.dart    # Checkout success (NEW)
│   └── plan_selection_screen.dart  # Subscription tiers (UPDATED)
├── services/
│   ├── api_service.dart         # HTTP client wrapper
│   ├── auth_service.dart        # Authentication API
│   ├── user_service.dart        # User management API
│   ├── conversation_service.dart # Conversation API
│   ├── message_service.dart     # Message API
│   ├── subscription_service.dart # Subscription API
│   └── payment_service.dart     # Stripe API (NEW)
├── models/              # Data models
├── widgets/             # Reusable components
└── l10n/               # Localization files
```

## Environment Variables

### Backend (.env)
```bash
# Server
PORT=3001
NODE_ENV=development
FRONTEND_URL=http://localhost:8080

# JWT
JWT_SECRET=your-secret-key

# DynamoDB
DYNAMODB_ENDPOINT=http://localhost:8000  # Local
DYNAMODB_REGION=eu-west-3

# OpenAI
OPENAI_API_KEY=your-api-key

# AWS SES
SES_SENDER_EMAIL=noreply@domain.com
SES_REGION=eu-west-3

# Stripe (NEW)
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PRICE_ESSENTIAL_MONTHLY=price_xxx
STRIPE_PRICE_ESSENTIAL_ANNUAL=price_xxx
STRIPE_PRICE_PREMIUM_MONTHLY=price_xxx
STRIPE_PRICE_PREMIUM_ANNUAL=price_xxx

# Test Mode
ENABLE_TEST_ENDPOINTS=true
USE_MOCK_EMAIL=true
USE_MOCK_AI=true
```

## Development Workflow

### Backend
```bash
cd backend
npm install
npm run dev:full      # Start DynamoDB + API
npm run test:e2e      # Run E2E tests (quota + UI + summarization)
npm run db:reset      # Reset database
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 8080
```

### Stripe Testing
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Forward webhooks to local
stripe listen --forward-to localhost:3001/api/payments/webhook

# Test cards
# Success: 4242 4242 4242 4242
# Declined: 4000 0000 0000 9995
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Get JWT token
- `POST /api/auth/logout` - Invalidate token

### Users
- `GET /api/users/me` - Current user info
- `PUT /api/users/me` - Update profile
- `GET /api/users/:id` - Get user by ID
- `POST /api/users/invite-partner` - Send invitation

### Conversations
- `GET /api/conversations` - List conversations
- `POST /api/conversations` - Create conversation
- `GET /api/conversations/:id` - Get conversation
- `GET /api/conversations/:id/messages` - Get messages

### Messages
- `POST /api/messages` - Send message
- `POST /api/messages/:id/ai-stream` - Get AI response (streaming)

### Subscriptions
- `GET /api/subscriptions/current` - Current subscription
- `PUT /api/subscriptions/update` - Change plan
- `POST /api/subscriptions/cancel` - Cancel subscription
- `GET /api/subscriptions/history` - Subscription history

### Payments (NEW)
- `POST /api/payments/create-checkout-session` - Start Stripe checkout
- `POST /api/payments/create-portal-session` - Access customer portal
- `GET /api/payments/invoices` - Get billing history
- `POST /api/payments/webhook` - Stripe webhook handler

## Testing

### E2E Tests
```bash
cd backend
npm run test:e2e
```

Tests include:
1. **Quota Test** (`test-quota.js`): Validates subscription limits
2. **UI Test** (`integration_test/complete_journey_test.dart`): Full user journey
3. **Summarization Test** (`test-summarization.js`): AI conversation summaries

### Manual Testing
1. Register two users
2. Send partner invitation
3. Accept invitation
4. Create conversation
5. Test AI messaging (quota enforcement)
6. Test subscription upgrade
7. Test payment flow
8. Test customer portal

## Database Schema

### Tables
- **users**: User accounts with auth credentials
- **couples**: Partner relationships with subscription
- **conversations**: Conversation metadata
- **messages**: Message history
- **subscriptions**: Subscription history

### Key Fields (couples table)
- `subscriptionTier`: free | essential | premium
- `subscriptionStatus`: active | canceled | past_due
- `aiMessagesUsed`: Current month usage
- `aiMessagesResetDate`: Next reset date
- `stripeCustomerId`: Stripe customer ID (NEW)
- `stripeSubscriptionId`: Active subscription (NEW)
- `billingPeriod`: monthly | annual (NEW)

## Documentation

- `README.md` - Project overview
- `DEVELOPMENT.md` - Development setup
- `DEPLOYMENT-GUIDE.md` - Production deployment
- `PAYMENT_SETUP.md` - Stripe configuration (NEW)
- `PAYMENT_IMPLEMENTATION.md` - Payment system details (NEW)
- `E2E_TESTING.md` - Testing guide
- `LEGAL_COMPLIANCE.md` - Privacy & compliance

## Recent Changes

### Payment Portal Implementation (Latest)
✅ Installed Stripe SDK
✅ Created Stripe service with all payment operations
✅ Added payment routes with webhook handling
✅ Created payment portal screen in Flutter
✅ Created billing history screen
✅ Updated plan selection with checkout integration
✅ Added payment links to profile screen
✅ Configured webhook automation
✅ Added usage counter reset logic
✅ Created comprehensive documentation

### Previous Updates
✅ Subscription quota enforcement with E2E tests
✅ AI conversation summarization
✅ Real-time message streaming
✅ Multi-language support (EN/FR)
✅ Terms of service implementation
✅ Email invitation system

## Common Tasks

### Add New Route
1. Create route file in `backend/src/routes/`
2. Register in `server.js`
3. Add middleware as needed
4. Create corresponding service in `frontend/lib/services/`
5. Create screen in `frontend/lib/screens/`
6. Add route to `main.dart`

### Modify Subscription Logic
1. Update `backend/src/services/subscriptionService.js`
2. Update `backend/src/middleware/subscriptionMiddleware.js`
3. Update frontend subscription service
4. Update E2E tests in `test-quota.js`

### Add Stripe Payment Feature
1. Implement in `backend/src/services/stripeService.js`
2. Add route in `backend/src/routes/payments.js`
3. Add webhook handler
4. Create Flutter UI screen
5. Update payment service
6. Test with Stripe test cards

## Troubleshooting

### Common Issues
- **DynamoDB errors**: Check if local DynamoDB is running on port 8000
- **JWT errors**: Verify JWT_SECRET is set and tokens are valid
- **Quota not enforcing**: Check race condition - 1sec delay between messages
- **Stripe errors**: Verify STRIPE_SECRET_KEY and price IDs are set
- **Webhook fails**: Check STRIPE_WEBHOOK_SECRET matches endpoint
- **CORS issues**: Ensure FRONTEND_URL includes port 8080

### Debug Tips
- Backend logs in console: `npm run dev`
- Check `.api-e2e.log` for E2E test logs
- Use Stripe CLI: `stripe listen --print-json` for webhook debugging
- Flutter DevTools for frontend debugging
- Check DynamoDB tables: AWS Console or NoSQL Workbench

## Next Steps / TODOs
- [ ] Add promo code support
- [ ] Implement usage alert notifications
- [ ] Add payment analytics dashboard
- [ ] Multi-currency support
- [ ] Apple Pay / Google Pay integration
- [ ] Enhanced conversation exercises
- [ ] Weekly relationship insights
- [ ] Admin dashboard

---

## Development Notes for Copilot

When working on this project:
- Follow existing patterns (e.g., test-quota.js style for backend tests)
- Use proper error handling with try-catch blocks
- Include authentication middleware for protected routes
- Add comprehensive logging for debugging
- Update E2E tests when changing subscription logic
- Maintain consistency between backend and frontend models
- Document new environment variables
- Test payment flows in Stripe test mode before production
- Always verify webhook signatures for security
