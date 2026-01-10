/**
 * Mock Stripe Service for Testing
 * Simulates Stripe operations without real API calls
 */

// In-memory storage for test assertions
global.mockStripeStore = global.mockStripeStore || {
  checkoutSessions: [],
  portalSessions: [],
  subscriptions: {},
  invoices: {}
};

const createCheckoutSession = async ({ userId, tier, billingPeriod, email }) => {
  const sessionId = `cs_test_mock_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  const subscriptionId = `sub_mock_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  
  const session = {
    id: sessionId,
    userId,
    tier,
    billingPeriod,
    email,
    subscriptionId,
    status: 'complete', // Simulate immediate success for tests
    url: `https://checkout.stripe.com/mock/${sessionId}`,
    createdAt: new Date().toISOString()
  };
  
  global.mockStripeStore.checkoutSessions.push(session);
  
  // Simulate subscription creation
  global.mockStripeStore.subscriptions[subscriptionId] = {
    id: subscriptionId,
    customer: `cus_mock_${userId}`,
    status: 'active',
    current_period_start: Math.floor(Date.now() / 1000),
    current_period_end: Math.floor(Date.now() / 1000) + (billingPeriod === 'annual' ? 31536000 : 2592000),
    items: {
      data: [{
        price: {
          id: `price_mock_${tier}_${billingPeriod}`,
          recurring: {
            interval: billingPeriod === 'annual' ? 'year' : 'month'
          }
        }
      }]
    }
  };
  
  console.log('💳 MOCK STRIPE (Checkout Session):', { sessionId, tier, billingPeriod, email });
  
  return {
    id: sessionId,
    url: session.url
  };
};

const createPortalSession = async ({ customerId, returnUrl }) => {
  const sessionId = `ps_test_mock_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  
  const session = {
    id: sessionId,
    customerId,
    returnUrl,
    url: `https://billing.stripe.com/mock/${sessionId}`,
    createdAt: new Date().toISOString()
  };
  
  global.mockStripeStore.portalSessions.push(session);
  
  console.log('💳 MOCK STRIPE (Portal Session):', { sessionId, customerId });
  
  return {
    url: session.url
  };
};

const getSubscription = async (subscriptionId) => {
  const subscription = global.mockStripeStore.subscriptions[subscriptionId];
  
  if (!subscription) {
    throw new Error('Subscription not found');
  }
  
  console.log('💳 MOCK STRIPE (Get Subscription):', { subscriptionId });
  
  return subscription;
};

const getInvoices = async (customerId) => {
  const invoices = global.mockStripeStore.invoices[customerId] || [];
  
  console.log('💳 MOCK STRIPE (Get Invoices):', { customerId, count: invoices.length });
  
  return {
    data: invoices
  };
};

const constructWebhookEvent = (payload, signature, secret) => {
  // Mock webhook event construction
  // In tests, we'll bypass webhook signature verification
  console.log('💳 MOCK STRIPE (Webhook Event):', { signature });
  
  return JSON.parse(payload);
};

const simulateWebhookEvent = (type, data) => {
  // Helper for tests to simulate webhook events
  const event = {
    id: `evt_mock_${Date.now()}`,
    type,
    data: {
      object: data
    },
    created: Math.floor(Date.now() / 1000)
  };
  
  console.log('💳 MOCK STRIPE (Simulate Webhook):', { type, data });
  
  return event;
};

module.exports = {
  createCheckoutSession,
  createPortalSession,
  getSubscription,
  getInvoices,
  constructWebhookEvent,
  simulateWebhookEvent
};
