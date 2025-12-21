/**
 * Subscription Routes
 * Manage user subscriptions and plans
 */

const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const subscriptionService = require('../services/subscriptionService');

const router = express.Router();

// @route   GET /api/subscriptions/tiers
// @desc    Get available subscription tiers
// @access  Public
router.get('/tiers', (req, res) => {
  try {
    res.json({
      success: true,
      tiers: subscriptionService.SUBSCRIPTION_TIERS
    });
  } catch (error) {
    console.error('Error getting subscription tiers:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get subscription tiers',
      message: error.message
    });
  }
});

// @route   GET /api/subscriptions/usage
// @desc    Get current couple subscription usage
// @access  Private
router.get('/usage', authenticateToken, async (req, res) => {
  try {
    const check = await subscriptionService.canSendAIMessage(req.user.userId);
    
    res.json({
      success: true,
      usage: {
        tier: check.tier,
        used: check.used,
        limit: check.limit === -1 ? 'unlimited' : check.limit,
        remaining: check.remaining,
        canSendMessage: check.allowed,
        coupleId: check.coupleId,
        isIndividual: check.isIndividual || false
      }
    });
  } catch (error) {
    console.error('Error getting subscription usage:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get subscription usage',
      message: error.message
    });
  }
});

// @route   POST /api/subscriptions/update
// @desc    Update couple subscription (for now, just change tier - payment later)
// @access  Private
router.post('/update', authenticateToken, async (req, res) => {
  try {
    const { tier, billingPeriod = 'monthly' } = req.body;

    // Validate tier
    const validTiers = ['free', 'essential', 'premium'];
    if (!validTiers.includes(tier)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid tier',
        message: `Tier must be one of: ${validTiers.join(', ')}`
      });
    }

    // Validate billing period
    const validPeriods = ['monthly', 'annual'];
    if (!validPeriods.includes(billingPeriod)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid billing period',
        message: `Billing period must be one of: ${validPeriods.join(', ')}`
      });
    }

    const result = await subscriptionService.updateSubscription(
      req.user.userId,
      tier,
      billingPeriod
    );

    res.json({
      success: true,
      message: `Couple subscription updated to ${tier}`,
      subscription: result.subscription,
      tier: result.tierConfig
    });

  } catch (error) {
    console.error('Error updating subscription:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update subscription',
      message: error.message
    });
  }
});

// @route   GET /api/subscriptions/history
// @desc    Get subscription history
// @access  Private
router.get('/history', authenticateToken, async (req, res) => {
  try {
    const history = await subscriptionService.getSubscriptionHistory(req.user.userId);
    
    res.json({
      success: true,
      history
    });

  } catch (error) {
    console.error('Error getting subscription history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get subscription history',
      message: error.message
    });
  }
});

// @route   POST /api/subscriptions/cancel
// @desc    Cancel subscription (remains active until end date)
// @access  Private
router.post('/cancel', authenticateToken, async (req, res) => {
  try {
    await subscriptionService.cancelSubscription(req.user.userId);
    
    res.json({
      success: true,
      message: 'Subscription canceled. You can continue using it until the end of your billing period.'
    });

  } catch (error) {
    console.error('Error canceling subscription:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cancel subscription',
      message: error.message
    });
  }
});

module.exports = router;
