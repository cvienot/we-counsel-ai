/**
 * Stripe Service
 * Handles payment processing and subscription management via Stripe
 */

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// Stripe price IDs (set these in environment variables)
const STRIPE_PRICES = {
  essential_monthly: process.env.STRIPE_PRICE_ESSENTIAL_MONTHLY,
  essential_annual: process.env.STRIPE_PRICE_ESSENTIAL_ANNUAL,
  premium_monthly: process.env.STRIPE_PRICE_PREMIUM_MONTHLY,
  premium_annual: process.env.STRIPE_PRICE_PREMIUM_ANNUAL,
};

/**
 * Create Stripe customer for couple
 */
const createCustomer = async ({ email, coupleId, metadata = {} }) => {
  try {
    const customer = await stripe.customers.create({
      email,
      metadata: {
        coupleId,
        ...metadata
      }
    });

    return {
      success: true,
      customerId: customer.id,
      customer
    };
  } catch (error) {
    console.error('❌ Error creating Stripe customer:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Create checkout session for subscription
 */
const createCheckoutSession = async ({
  customerId,
  priceId,
  coupleId,
  successUrl,
  cancelUrl,
  tier,
  billingPeriod
}) => {
  try {
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        coupleId,
        tier,
        billingPeriod
      },
      subscription_data: {
        metadata: {
          coupleId,
          tier,
          billingPeriod
        }
      }
    });

    return {
      success: true,
      sessionId: session.id,
      url: session.url
    };
  } catch (error) {
    console.error('❌ Error creating checkout session:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Create customer portal session
 */
const createPortalSession = async ({ customerId, returnUrl }) => {
  try {
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: returnUrl,
    });

    return {
      success: true,
      url: session.url
    };
  } catch (error) {
    console.error('❌ Error creating portal session:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Get subscription details
 */
const getSubscription = async (subscriptionId) => {
  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    return {
      success: true,
      subscription
    };
  } catch (error) {
    console.error('❌ Error retrieving subscription:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Cancel subscription
 */
const cancelSubscription = async (subscriptionId) => {
  try {
    const subscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true
    });

    return {
      success: true,
      subscription,
      cancelAt: subscription.cancel_at
    };
  } catch (error) {
    console.error('❌ Error canceling subscription:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Reactivate canceled subscription
 */
const reactivateSubscription = async (subscriptionId) => {
  try {
    const subscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: false
    });

    return {
      success: true,
      subscription
    };
  } catch (error) {
    console.error('❌ Error reactivating subscription:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Update subscription (change plan)
 */
const updateSubscription = async (subscriptionId, newPriceId) => {
  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    
    const updatedSubscription = await stripe.subscriptions.update(subscriptionId, {
      items: [{
        id: subscription.items.data[0].id,
        price: newPriceId,
      }],
      proration_behavior: 'create_prorations',
    });

    return {
      success: true,
      subscription: updatedSubscription
    };
  } catch (error) {
    console.error('❌ Error updating subscription:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Get customer invoices
 */
const getInvoices = async (customerId, limit = 10) => {
  try {
    const invoices = await stripe.invoices.list({
      customer: customerId,
      limit
    });

    return {
      success: true,
      invoices: invoices.data
    };
  } catch (error) {
    console.error('❌ Error retrieving invoices:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Get payment methods
 */
const getPaymentMethods = async (customerId) => {
  try {
    const paymentMethods = await stripe.paymentMethods.list({
      customer: customerId,
      type: 'card',
    });

    return {
      success: true,
      paymentMethods: paymentMethods.data
    };
  } catch (error) {
    console.error('❌ Error retrieving payment methods:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Verify webhook signature
 */
const constructWebhookEvent = (payload, signature) => {
  try {
    const event = stripe.webhooks.constructEvent(
      payload,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );
    return { success: true, event };
  } catch (error) {
    console.error('❌ Webhook signature verification failed:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Get price ID for tier and billing period
 */
const getPriceId = (tier, billingPeriod) => {
  const key = `${tier}_${billingPeriod}`;
  return STRIPE_PRICES[key];
};

module.exports = {
  createCustomer,
  createCheckoutSession,
  createPortalSession,
  getSubscription,
  cancelSubscription,
  reactivateSubscription,
  updateSubscription,
  getInvoices,
  getPaymentMethods,
  constructWebhookEvent,
  getPriceId,
  STRIPE_PRICES
};
