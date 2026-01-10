# Stripe Payment Configuration Guide

## Overview
The payment portal uses Stripe for secure payment processing. This guide covers the setup required for both development and production environments.

## Stripe Account Setup

### 1. Create Stripe Account
1. Sign up at https://stripe.com
2. Complete account verification
3. Access the Dashboard

### 2. Get API Keys
From the Stripe Dashboard:
- Development: Use **Test Mode** keys
- Production: Use **Live Mode** keys

Required keys:
- `STRIPE_SECRET_KEY`: Backend server key
- `STRIPE_WEBHOOK_SECRET`: Webhook endpoint verification

### 3. Create Products and Prices

#### Essential Plan
```bash
# Monthly
stripe prices create \
  --unit-amount 999 \
  --currency eur \
  --recurring interval=month \
  --product-data name="Essential Plan"

# Annual (20% discount)
stripe prices create \
  --unit-amount 9590 \
  --currency eur \
  --recurring interval=year \
  --product-data name="Essential Plan (Annual)"
```

#### Premium Plan
```bash
# Monthly
stripe prices create \
  --unit-amount 1999 \
  --currency eur \
  --recurring interval=month \
  --product-data name="Premium Plan"

# Annual (20% discount)
stripe prices create \
  --unit-amount 19190 \
  --currency eur \
  --recurring interval=year \
  --product-data name="Premium Plan (Annual)"
```

Save the price IDs (e.g., `price_xxxxxxxxxxxxx`) for environment configuration.

## Backend Configuration

### Environment Variables

Add to `.env` or AWS Secrets Manager:

```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx  # or sk_live_ for production
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx

# Price IDs
STRIPE_PRICE_ESSENTIAL_MONTHLY=price_xxxxxxxxxxxxx
STRIPE_PRICE_ESSENTIAL_ANNUAL=price_xxxxxxxxxxxxx
STRIPE_PRICE_PREMIUM_MONTHLY=price_xxxxxxxxxxxxx
STRIPE_PRICE_PREMIUM_ANNUAL=price_xxxxxxxxxxxxx

# Frontend URL (for redirects)
FRONTEND_URL=https://your-domain.com
```

### Webhook Setup

1. **Development (using Stripe CLI)**:
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:3001/api/payments/webhook
# This will output a webhook secret (whsec_xxx)
```

2. **Production**:
- Go to Stripe Dashboard → Developers → Webhooks
- Click "Add endpoint"
- URL: `https://your-api-domain.com/api/payments/webhook`
- Select events to listen for:
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_succeeded`
  - `invoice.payment_failed`
- Copy the webhook signing secret

## Frontend Configuration

The Flutter app uses `url_launcher` to redirect to Stripe Checkout and Customer Portal.

### Required Packages

Already included in `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  url_launcher: ^6.2.1
  flutter_secure_storage: ^9.0.0
```

If not present, run:
```bash
cd frontend
flutter pub add url_launcher
flutter pub get
```

## Database Schema Updates

The payment system uses these additional fields in the `couples` table:

```javascript
{
  coupleId: 'uuid',
  subscriptionTier: 'free' | 'essential' | 'premium',
  subscriptionStatus: 'active' | 'canceled' | 'past_due',
  stripeCustomerId: 'cus_xxxxx',
  stripeSubscriptionId: 'sub_xxxxx',
  billingPeriod: 'monthly' | 'annual',
  subscriptionStartDate: 'ISO date',
  subscriptionEndDate: 'ISO date',
  // ... other fields
}
```

These fields are automatically created/updated by the payment webhooks.

## Testing

### Test Cards (Stripe Test Mode)

**Successful payment:**
- Card: `4242 4242 4242 4242`
- CVC: Any 3 digits
- Date: Any future date

**Payment requires authentication:**
- Card: `4000 0025 0000 3155`

**Payment declined:**
- Card: `4000 0000 0000 9995`

Full list: https://stripe.com/docs/testing

### Test Flow

1. Start backend with test keys
2. Navigate to plan selection
3. Select Essential or Premium
4. Complete checkout with test card
5. Verify webhook received
6. Check subscription activated in database
7. Test customer portal access

## Production Deployment

### Checklist

- [ ] Switch to Live Mode keys in Stripe Dashboard
- [ ] Create production products and prices
- [ ] Update environment variables with live keys and price IDs
- [ ] Configure production webhook endpoint
- [ ] Test with real payment (then refund)
- [ ] Enable Stripe Radar for fraud protection
- [ ] Set up email receipts in Stripe Dashboard

### Security

- **Never** commit Stripe keys to git
- Use AWS Secrets Manager or similar for production
- Webhook signature verification is mandatory (already implemented)
- Use HTTPS for all production endpoints
- Regular security audits of payment flow

## Customer Portal Features

Users can manage:
- Update payment method
- View billing history
- Download invoices
- Change subscription plan (upgrade/downgrade)
- Cancel subscription
- Update billing information

## Support

### Common Issues

**"No Stripe price ID configured"**
- Ensure environment variables are set correctly
- Price IDs must match format: `price_xxxxxxxxxxxxx`

**"Webhook signature verification failed"**
- Check `STRIPE_WEBHOOK_SECRET` matches endpoint secret
- In development, use Stripe CLI forwarding

**"Could not open payment page"**
- Check `url_launcher` permissions in iOS/Android
- Verify redirect URLs are whitelisted

### Resources

- Stripe Documentation: https://stripe.com/docs
- Stripe Dashboard: https://dashboard.stripe.com
- Stripe CLI: https://stripe.com/docs/stripe-cli
- Stripe Support: https://support.stripe.com

## API Endpoints

### Create Checkout Session
```
POST /api/payments/create-checkout-session
Authorization: Bearer <token>
Body: { "tier": "essential", "billingPeriod": "monthly" }
```

### Create Portal Session
```
POST /api/payments/create-portal-session
Authorization: Bearer <token>
```

### Get Invoices
```
GET /api/payments/invoices?limit=10
Authorization: Bearer <token>
```

### Webhook (Public)
```
POST /api/payments/webhook
Headers: stripe-signature
```
