/**
 * Payment Routes
 * Handles Stripe checkout, portal, and webhook endpoints
 */

const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/authMiddleware');
const stripeService = require('../services/stripeService');
const subscriptionService = require('../services/subscriptionService');
const { docClient, TABLES, GetCommand, UpdateCommand } = require('../config/database');

// @route   POST /api/payments/create-checkout-session
// @desc    Create Stripe checkout session for subscription
// @access  Private
router.post('/create-checkout-session', authenticateToken, async (req, res) => {
  try {
    const { tier, billingPeriod = 'monthly' } = req.body;
    const userId = req.user.userId;

    // Validate tier
    if (!['essential', 'premium'].includes(tier)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid subscription tier',
        message: 'Tier must be essential or premium'
      });
    }

    // Validate billing period
    if (!['monthly', 'annual'].includes(billingPeriod)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid billing period',
        message: 'Billing period must be monthly or annual'
      });
    }

    // Get user
    const userResult = await docClient.send(new GetCommand({
      TableName: TABLES.USERS,
      Key: { userId }
    }));

    const user = userResult.Item;
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    if (!user.coupleId) {
      return res.status(400).json({
        success: false,
        error: 'No couple found',
        message: 'You must be part of a couple to subscribe'
      });
    }

    // Get couple
    const coupleResult = await docClient.send(new GetCommand({
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId }
    }));

    const couple = coupleResult.Item;
    if (!couple) {
      return res.status(404).json({
        success: false,
        error: 'Couple not found'
      });
    }

    // Create or get Stripe customer
    let customerId = couple.stripeCustomerId;
    
    if (!customerId) {
      const customerResult = await stripeService.createCustomer({
        email: user.email,
        coupleId: user.coupleId,
        metadata: {
          userId,
          userName: user.name
        }
      });

      if (!customerResult.success) {
        return res.status(500).json({
          success: false,
          error: 'Failed to create customer',
          message: customerResult.error
        });
      }

      customerId = customerResult.customerId;

      // Save customer ID to couple
      await docClient.send(new UpdateCommand({
        TableName: TABLES.COUPLES,
        Key: { coupleId: user.coupleId },
        UpdateExpression: 'SET stripeCustomerId = :customerId, updatedAt = :updatedAt',
        ExpressionAttributeValues: {
          ':customerId': customerId,
          ':updatedAt': new Date().toISOString()
        }
      }));
    }

    // Get price ID
    const priceId = stripeService.getPriceId(tier, billingPeriod);
    
    if (!priceId) {
      return res.status(500).json({
        success: false,
        error: 'Price not configured',
        message: `Stripe price ID not configured for ${tier} ${billingPeriod}`
      });
    }

    // Create checkout session
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:8080';
    const session = await stripeService.createCheckoutSession({
      customerId,
      priceId,
      coupleId: user.coupleId,
      successUrl: `${baseUrl}/payment/success?session_id={CHECKOUT_SESSION_ID}`,
      cancelUrl: `${baseUrl}/settings/subscription`,
      tier,
      billingPeriod
    });

    if (!session.success) {
      return res.status(500).json({
        success: false,
        error: 'Failed to create checkout session',
        message: session.error
      });
    }

    res.json({
      success: true,
      sessionId: session.sessionId,
      url: session.url
    });

  } catch (error) {
    console.error('❌ Error creating checkout session:', error);
    res.status(500).json({
      success: false,
      error: 'Server error',
      message: error.message
    });
  }
});

// @route   POST /api/payments/create-portal-session
// @desc    Create Stripe customer portal session
// @access  Private
router.post('/create-portal-session', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user and couple
    const userResult = await docClient.send(new GetCommand({
      TableName: TABLES.USERS,
      Key: { userId }
    }));

    const user = userResult.Item;
    if (!user || !user.coupleId) {
      return res.status(404).json({
        success: false,
        error: 'User or couple not found'
      });
    }

    const coupleResult = await docClient.send(new GetCommand({
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId }
    }));

    const couple = coupleResult.Item;
    if (!couple || !couple.stripeCustomerId) {
      return res.status(404).json({
        success: false,
        error: 'No payment profile found',
        message: 'You need to subscribe first'
      });
    }

    // Create portal session
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:8080';
    const session = await stripeService.createPortalSession({
      customerId: couple.stripeCustomerId,
      returnUrl: `${baseUrl}/settings/subscription`
    });

    if (!session.success) {
      return res.status(500).json({
        success: false,
        error: 'Failed to create portal session',
        message: session.error
      });
    }

    res.json({
      success: true,
      url: session.url
    });

  } catch (error) {
    console.error('❌ Error creating portal session:', error);
    res.status(500).json({
      success: false,
      error: 'Server error',
      message: error.message
    });
  }
});

// @route   GET /api/payments/invoices
// @desc    Get billing history (invoices)
// @access  Private
router.get('/invoices', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const limit = parseInt(req.query.limit) || 10;

    // Get user and couple
    const userResult = await docClient.send(new GetCommand({
      TableName: TABLES.USERS,
      Key: { userId }
    }));

    const user = userResult.Item;
    if (!user || !user.coupleId) {
      return res.status(404).json({
        success: false,
        error: 'User or couple not found'
      });
    }

    const coupleResult = await docClient.send(new GetCommand({
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId }
    }));

    const couple = coupleResult.Item;
    if (!couple || !couple.stripeCustomerId) {
      return res.json({
        success: true,
        invoices: []
      });
    }

    // Get invoices
    const result = await stripeService.getInvoices(couple.stripeCustomerId, limit);

    if (!result.success) {
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve invoices',
        message: result.error
      });
    }

    // Format invoices for frontend
    const invoices = result.invoices.map(invoice => ({
      id: invoice.id,
      amount: invoice.amount_paid,
      currency: invoice.currency.toUpperCase(),
      status: invoice.status,
      date: new Date(invoice.created * 1000).toISOString(),
      pdfUrl: invoice.invoice_pdf,
      hostedUrl: invoice.hosted_invoice_url,
      description: invoice.lines.data[0]?.description || 'Subscription',
    }));

    res.json({
      success: true,
      invoices
    });

  } catch (error) {
    console.error('❌ Error retrieving invoices:', error);
    res.status(500).json({
      success: false,
      error: 'Server error',
      message: error.message
    });
  }
});

// @route   POST /api/payments/webhook
// @desc    Handle Stripe webhook events
// @access  Public (but verified via Stripe signature)
router.post('/webhook', async (req, res) => {
  const signature = req.headers['stripe-signature'];

  try {
    // Verify webhook signature
    const { success, event, error } = stripeService.constructWebhookEvent(
      req.body,
      signature
    );

    if (!success) {
      console.error('❌ Webhook signature verification failed:', error);
      return res.status(400).send(`Webhook Error: ${error}`);
    }

    console.log(`📨 Webhook received: ${event.type}`);

    // Handle different event types
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        const { coupleId, tier, billingPeriod } = session.metadata;

        console.log(`✅ Checkout completed for couple ${coupleId}: ${tier} (${billingPeriod})`);

        // Update subscription in database
        const subscriptionResult = await stripeService.getSubscription(session.subscription);
        
        if (subscriptionResult.success && subscriptionResult.subscription) {
          const sub = subscriptionResult.subscription;
          
          await docClient.send(new UpdateCommand({
            TableName: TABLES.COUPLES,
            Key: { coupleId },
            UpdateExpression: 'SET subscriptionTier = :tier, subscriptionStatus = :status, stripeSubscriptionId = :subId, billingPeriod = :period, subscriptionStartDate = :startDate, subscriptionEndDate = :endDate, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
              ':tier': tier,
              ':status': 'active',
              ':subId': session.subscription,
              ':period': billingPeriod,
              ':startDate': sub.current_period_start ? new Date(sub.current_period_start * 1000).toISOString() : new Date().toISOString(),
              ':endDate': sub.current_period_end ? new Date(sub.current_period_end * 1000).toISOString() : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
              ':updatedAt': new Date().toISOString()
            }
          }));

          // Reset usage counters
          await subscriptionService.resetUsageCounters(coupleId);
          
          console.log(`✅ Subscription updated in database for couple ${coupleId}`);
        } else {
          console.error(`❌ Failed to get subscription details: ${subscriptionResult.error}`);
        }
        break;
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const { coupleId } = subscription.metadata;

        console.log(`🔄 Subscription updated for couple ${coupleId}`);

        // Determine tier from price ID
        let tier = 'free';
        const priceId = subscription.items.data[0].price.id;
        
        if (priceId === stripeService.STRIPE_PRICES.essential_monthly || 
            priceId === stripeService.STRIPE_PRICES.essential_annual) {
          tier = 'essential';
        } else if (priceId === stripeService.STRIPE_PRICES.premium_monthly || 
                   priceId === stripeService.STRIPE_PRICES.premium_annual) {
          tier = 'premium';
        }

        const billingPeriod = subscription.items.data[0].price.recurring.interval === 'year' ? 'annual' : 'monthly';

        await docClient.send(new UpdateCommand({
          TableName: TABLES.COUPLES,
          Key: { coupleId },
          UpdateExpression: 'SET subscriptionTier = :tier, subscriptionStatus = :status, billingPeriod = :period, subscriptionEndDate = :endDate, updatedAt = :updatedAt',
          ExpressionAttributeValues: {
            ':tier': tier,
            ':status': subscription.status,
            ':period': billingPeriod,
            ':endDate': new Date(subscription.current_period_end * 1000).toISOString(),
            ':updatedAt': new Date().toISOString()
          }
        }));
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        const { coupleId } = subscription.metadata;

        console.log(`❌ Subscription canceled for couple ${coupleId}`);

        await docClient.send(new UpdateCommand({
          TableName: TABLES.COUPLES,
          Key: { coupleId },
          UpdateExpression: 'SET subscriptionTier = :tier, subscriptionStatus = :status, subscriptionEndDate = :endDate, updatedAt = :updatedAt',
          ExpressionAttributeValues: {
            ':tier': 'free',
            ':status': 'canceled',
            ':endDate': new Date().toISOString(),
            ':updatedAt': new Date().toISOString()
          }
        }));
        break;
      }

      case 'invoice.payment_succeeded': {
        const invoice = event.data.object;
        console.log(`✅ Payment succeeded: ${invoice.id}`);
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object;
        console.log(`❌ Payment failed: ${invoice.id}`);
        // Could send notification email here
        break;
      }

      default:
        console.log(`ℹ️ Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });

  } catch (error) {
    console.error('❌ Webhook error:', error);
    res.status(500).send(`Webhook Error: ${error.message}`);
  }
});

module.exports = router;
