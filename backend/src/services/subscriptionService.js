/**
 * Subscription Service
 * Manages subscription tiers, limits, and usage tracking
 */

const { docClient, TABLES, GetCommand, UpdateCommand, PutCommand, QueryCommand } = require('../config/database');
const { randomUUID } = require('crypto');

// Subscription tier definitions
const SUBSCRIPTION_TIERS = {
  free: {
    name: 'Free',
    price: 0,
    aiMessagesPerMonth: 10,
    features: [
      '10 AI relationship coach messages per month',
      'Unlimited partner messaging',
      'Basic conversation history (30 days)',
      'Email notifications'
    ]
  },
  essential: {
    name: 'Essential',
    price: 999, // $9.99 in cents
    aiMessagesPerMonth: 100,
    features: [
      '100 AI relationship coach messages per month',
      'Unlimited partner messaging',
      'Full conversation history',
      'Conversation summaries',
      'Priority email support'
    ]
  },
  premium: {
    name: 'Premium',
    price: 1999, // $19.99 in cents
    aiMessagesPerMonth: -1, // Unlimited
    features: [
      'Unlimited AI relationship coach messages',
      'Unlimited partner messaging',
      'Full conversation history',
      'Conversation summaries',
      'Guided conversation exercises',
      'Weekly relationship insights',
      'Priority support'
    ]
  }
};

/**
 * Get subscription tier configuration
 */
const getTierConfig = (tier) => {
  return SUBSCRIPTION_TIERS[tier] || SUBSCRIPTION_TIERS.free;
};

/**
 * Check if couple can send AI message
 */
const canSendAIMessage = async (userId) => {
  try {
    // Get user to find their couple
    const userParams = {
      TableName: TABLES.USERS,
      Key: { userId }
    };

    const userResult = await docClient.send(new GetCommand(userParams));
    const user = userResult.Item;

    if (!user) {
      return { allowed: false, reason: 'User not found' };
    }

    // If user doesn't have a couple yet, they're on free tier
    if (!user.coupleId) {
      return {
        allowed: true,
        tier: 'free',
        used: 0,
        limit: getTierConfig('free').aiMessagesPerMonth,
        remaining: getTierConfig('free').aiMessagesPerMonth,
        reason: null,
        isIndividual: true
      };
    }

    // Get couple subscription
    const coupleParams = {
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId }
    };

    const coupleResult = await docClient.send(new GetCommand(coupleParams));
    const couple = coupleResult.Item;

    if (!couple) {
      return { allowed: false, reason: 'Couple not found' };
    }

    const tier = couple.subscriptionTier || 'free';
    const tierConfig = getTierConfig(tier);
    
    // Premium has unlimited messages
    if (tierConfig.aiMessagesPerMonth === -1) {
      return { allowed: true, tier, remaining: 'unlimited', coupleId: couple.coupleId };
    }

    // Check if we need to reset the counter (new month)
    const now = new Date();
    const resetDate = couple.aiMessagesResetDate ? new Date(couple.aiMessagesResetDate) : null;
    const shouldReset = !resetDate || now >= resetDate;

    let messagesUsed = couple.aiMessagesUsed || 0;

    // Reset counter if needed
    if (shouldReset) {
      messagesUsed = 0;
      const nextResetDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);
      
      await docClient.send(new UpdateCommand({
        TableName: TABLES.COUPLES,
        Key: { coupleId: couple.coupleId },
        UpdateExpression: 'SET aiMessagesUsed = :zero, aiMessagesResetDate = :resetDate',
        ExpressionAttributeValues: {
          ':zero': 0,
          ':resetDate': nextResetDate.toISOString()
        }
      }));
    }

    const remaining = tierConfig.aiMessagesPerMonth - messagesUsed;
    const allowed = messagesUsed < tierConfig.aiMessagesPerMonth;

    return {
      allowed,
      tier,
      used: messagesUsed,
      limit: tierConfig.aiMessagesPerMonth,
      remaining,
      coupleId: couple.coupleId,
      reason: allowed ? null : 'Monthly limit reached'
    };

  } catch (error) {
    console.error('Error checking AI message limit:', error);
    throw error;
  }
};

/**
 * Increment AI message usage counter for couple
 */
const incrementAIMessageUsage = async (userId) => {
  try {
    // Get user to find their couple
    const userParams = {
      TableName: TABLES.USERS,
      Key: { userId }
    };

    const userResult = await docClient.send(new GetCommand(userParams));
    const user = userResult.Item;

    if (!user || !user.coupleId) {
      console.log('⚠️ User has no couple, skipping usage increment');
      return null;
    }

    const params = {
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId },
      UpdateExpression: 'SET aiMessagesUsed = if_not_exists(aiMessagesUsed, :zero) + :increment',
      ExpressionAttributeValues: {
        ':zero': 0,
        ':increment': 1
      },
      ReturnValues: 'ALL_NEW'
    };

    const result = await docClient.send(new UpdateCommand(params));
    return result.Attributes;

  } catch (error) {
    console.error('Error incrementing AI message usage:', error);
    throw error;
  }
};

/**
 * Update couple subscription tier
 */
const updateSubscription = async (userId, tier, billingPeriod = 'monthly') => {
  try {
    const tierConfig = getTierConfig(tier);
    
    if (!tierConfig) {
      throw new Error(`Invalid subscription tier: ${tier}`);
    }

    // Get user to find their couple
    const userParams = {
      TableName: TABLES.USERS,
      Key: { userId }
    };

    const userResult = await docClient.send(new GetCommand(userParams));
    const user = userResult.Item;

    if (!user) {
      throw new Error('User not found');
    }

    if (!user.coupleId) {
      throw new Error('User must be in a couple to upgrade subscription');
    }

    const now = new Date();
    const endDate = new Date(now);
    
    if (billingPeriod === 'annual') {
      endDate.setFullYear(endDate.getFullYear() + 1);
    } else {
      endDate.setMonth(endDate.getMonth() + 1);
    }

    const nextResetDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    // Update couple record
    await docClient.send(new UpdateCommand({
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId },
      UpdateExpression: `SET 
        subscriptionTier = :tier,
        subscriptionStatus = :status,
        subscriptionStartDate = :startDate,
        subscriptionEndDate = :endDate,
        aiMessagesUsed = :zero,
        aiMessagesResetDate = :resetDate`,
      ExpressionAttributeValues: {
        ':tier': tier,
        ':status': 'active',
        ':startDate': now.toISOString(),
        ':endDate': endDate.toISOString(),
        ':zero': 0,
        ':resetDate': nextResetDate.toISOString()
      }
    }));

    // Create subscription record
    const subscriptionId = randomUUID();
    const subscriptionRecord = {
      subscriptionId,
      coupleId: user.coupleId,
      tier,
      status: 'active',
      billingPeriod,
      amount: billingPeriod === 'annual' ? tierConfig.price * 10 : tierConfig.price, // 20% discount for annual
      currency: 'USD',
      startDate: now.toISOString(),
      endDate: endDate.toISOString(),
      paymentProvider: 'manual', // Will be 'stripe' when integrated
      createdAt: now.toISOString()
    };

    await docClient.send(new PutCommand({
      TableName: TABLES.SUBSCRIPTIONS,
      Item: subscriptionRecord
    }));

    console.log(`✅ Subscription updated for couple ${user.coupleId}: ${tier} (${billingPeriod})`);

    return {
      success: true,
      subscription: subscriptionRecord,
      tierConfig
    };

  } catch (error) {
    console.error('Error updating subscription:', error);
    throw error;
  }
};

/**
 * Get couple's subscription history
 */
const getSubscriptionHistory = async (userId) => {
  try {
    // Get user to find their couple
    const userParams = {
      TableName: TABLES.USERS,
      Key: { userId }
    };

    const userResult = await docClient.send(new GetCommand(userParams));
    const user = userResult.Item;

    if (!user || !user.coupleId) {
      return [];
    }

    const params = {
      TableName: TABLES.SUBSCRIPTIONS,
      IndexName: 'coupleId-index',
      KeyConditionExpression: 'coupleId = :coupleId',
      ExpressionAttributeValues: {
        ':coupleId': user.coupleId
      },
      ScanIndexForward: false // Most recent first
    };

    const result = await docClient.send(new QueryCommand(params));
    return result.Items || [];

  } catch (error) {
    console.error('Error getting subscription history:', error);
    throw error;
  }
};

/**
 * Cancel couple subscription (remains active until end date)
 */
const cancelSubscription = async (userId) => {
  try {
    // Get user to find their couple
    const userParams = {
      TableName: TABLES.USERS,
      Key: { userId }
    };

    const userResult = await docClient.send(new GetCommand(userParams));
    const user = userResult.Item;

    if (!user || !user.coupleId) {
      throw new Error('User must be in a couple to cancel subscription');
    }

    const now = new Date();

    await docClient.send(new UpdateCommand({
      TableName: TABLES.COUPLES,
      Key: { coupleId: user.coupleId },
      UpdateExpression: 'SET subscriptionStatus = :status',
      ExpressionAttributeValues: {
        ':status': 'canceled'
      }
    }));

    console.log(`✅ Subscription canceled for couple ${user.coupleId}`);

    return { success: true };

  } catch (error) {
    console.error('Error canceling subscription:', error);
    throw error;
  }
};

module.exports = {
  SUBSCRIPTION_TIERS,
  getTierConfig,
  canSendAIMessage,
  incrementAIMessageUsage,
  updateSubscription,
  getSubscriptionHistory,
  cancelSubscription
};
