/**
 * Subscription Middleware
 * Check subscription limits before allowing actions
 */

const subscriptionService = require('../services/subscriptionService');

/**
 * Middleware to check if user can send AI messages
 */
const checkAIMessageLimit = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const check = await subscriptionService.canSendAIMessage(userId);

    if (!check.allowed) {
      return res.status(403).json({
        success: false,
        error: 'AI message limit reached',
        message: check.reason,
        usage: {
          tier: check.tier,
          used: check.used,
          limit: check.limit,
          remaining: check.remaining
        },
        upgradePrompt: 'Upgrade your subscription to send more AI messages'
      });
    }

    // Attach usage info to request for logging
    req.subscriptionCheck = check;
    next();

  } catch (error) {
    console.error('Subscription check error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to check subscription limits',
      message: error.message
    });
  }
};

module.exports = {
  checkAIMessageLimit
};
