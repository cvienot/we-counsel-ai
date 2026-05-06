/**
 * Database Schema Definition
 * Version: 1.0.0
 * 
 * This file defines the complete database schema including tables,
 * indexes, and attributes. It serves as the single source of truth
 * for the database structure and enables portability across environments.
 */

const SCHEMA_VERSION = '1.0.0';

const tables = {
  users: {
    tableName: 'we-counsel-users',
    description: 'User accounts and profiles',
    primaryKey: {
      partitionKey: { name: 'userId', type: 'S' }
    },
    attributes: [
      { name: 'userId', type: 'S', description: 'Unique user identifier (UUID)' },
      { name: 'email', type: 'S', description: 'User email address' },
      { name: 'coupleId', type: 'S', description: 'Reference to couple this user belongs to' },
      { name: 'firstName', type: 'S', description: 'User first name' },
      { name: 'lastName', type: 'S', description: 'User last name' },
      { name: 'language', type: 'S', description: 'User preferred language (en, fr, es)' },
      { name: 'partnerId', type: 'S', description: 'Reference to partner user' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' },
      { name: 'termsAcceptedAt', type: 'S', description: 'ISO timestamp when user accepted terms of service' },
      { name: 'termsAcceptedVersion', type: 'S', description: 'Version of terms accepted (e.g., "1.0.0")' },
      { name: 'firstTouchUtm', type: 'M', description: 'First captured UTM campaign parameters' },
      { name: 'lastTouchUtm', type: 'M', description: 'Most recent captured UTM campaign parameters before signup' },
      { name: 'landingPage', type: 'S', description: 'Landing page URL captured with first-touch campaign attribution' },
      { name: 'referrer', type: 'S', description: 'Optional referring URL captured with campaign attribution' },
      { name: 'campaignCapturedAt', type: 'S', description: 'ISO timestamp when campaign attribution was captured' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'email-index',
        keys: {
          partitionKey: { name: 'email', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query users by email for login/registration'
      },
      {
        indexName: 'couple-index',
        keys: {
          partitionKey: { name: 'coupleId', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query all users in a couple for notifications'
      }
    ]
  },

  couples: {
    tableName: 'we-counsel-couples',
    description: 'Couple relationships',
    primaryKey: {
      partitionKey: { name: 'coupleId', type: 'S' }
    },
    attributes: [
      { name: 'coupleId', type: 'S', description: 'Unique couple identifier (UUID)' },
      { name: 'user1Id', type: 'S', description: 'First user in couple' },
      { name: 'user2Id', type: 'S', description: 'Second user in couple' },
      { name: 'status', type: 'S', description: 'Couple status (active, inactive)' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' },
      
      // Subscription fields (couple-based)
      { name: 'subscriptionTier', type: 'S', description: 'Subscription tier (free, essential, premium)' },
      { name: 'subscriptionStatus', type: 'S', description: 'Subscription status (active, canceled, expired)' },
      { name: 'subscriptionStartDate', type: 'S', description: 'ISO timestamp when subscription started' },
      { name: 'subscriptionEndDate', type: 'S', description: 'ISO timestamp when subscription ends' },
      { name: 'aiMessagesUsed', type: 'N', description: 'AI messages used by couple in current billing period' },
      { name: 'aiMessagesResetDate', type: 'S', description: 'ISO timestamp when usage counter resets' }
    ],
    globalSecondaryIndexes: []
  },

  invitations: {
    tableName: 'we-counsel-invitations',
    description: 'Partner invitation links',
    primaryKey: {
      partitionKey: { name: 'invitationId', type: 'S' }
    },
    attributes: [
      { name: 'invitationId', type: 'S', description: 'Unique invitation identifier (UUID)' },
      { name: 'inviterId', type: 'S', description: 'User who sent the invitation' },
      { name: 'email', type: 'S', description: 'Email address invited (optional)' },
      { name: 'status', type: 'S', description: 'Status (pending, accepted, expired)' },
      { name: 'expiresAt', type: 'S', description: 'ISO timestamp when invitation expires' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'inviter-index',
        keys: {
          partitionKey: { name: 'inviterId', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query invitations by inviter'
      },
      {
        indexName: 'email-index',
        keys: {
          partitionKey: { name: 'email', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query invitations by email address'
      }
    ]
  },

  conversations: {
    tableName: 'we-counsel-conversations',
    description: 'Conversation threads between couples',
    primaryKey: {
      partitionKey: { name: 'conversationId', type: 'S' }
    },
    attributes: [
      { name: 'conversationId', type: 'S', description: 'Unique conversation identifier (UUID)' },
      { name: 'coupleId', type: 'S', description: 'Couple this conversation belongs to' },
      { name: 'title', type: 'S', description: 'Conversation title' },
      { name: 'topic', type: 'S', description: 'Conversation topic/theme' },
      { name: 'conversationType', type: 'S', description: 'Type of conversation (main, exercise)' },
      { name: 'exerciseId', type: 'S', description: 'Reference to exercise if this is an exercise conversation' },
      { name: 'isMainThread', type: 'BOOL', description: 'Whether this is the main conversation' },
      { name: 'isActive', type: 'BOOL', description: 'Whether conversation is active' },
      { name: 'lastMessageAt', type: 'S', description: 'ISO timestamp of last message' },
      { name: 'messageCount', type: 'N', description: 'Total number of messages' },
      { name: 'summary', type: 'S', description: 'AI-generated summary of conversation history for context management' },
      { name: 'lastSummarizedAt', type: 'S', description: 'ISO timestamp when summary was last updated' },
      { name: 'summarizedMessageCount', type: 'N', description: 'Number of messages included in the summary' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'couple-index',
        keys: {
          partitionKey: { name: 'coupleId', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query all conversations for a couple'
      }
    ]
  },

  messages: {
    tableName: 'we-counsel-messages',
    description: 'Messages within conversations',
    primaryKey: {
      partitionKey: { name: 'messageId', type: 'S' }
    },
    attributes: [
      { name: 'messageId', type: 'S', description: 'Unique message identifier (UUID)' },
      { name: 'conversationId', type: 'S', description: 'Conversation this message belongs to' },
      { name: 'senderId', type: 'S', description: 'User or AI who sent the message' },
      { name: 'senderName', type: 'S', description: 'Display name of sender' },
      { name: 'senderType', type: 'S', description: 'Type of sender (user, ai)' },
      { name: 'content', type: 'S', description: 'Message content' },
      { name: 'recipientType', type: 'S', description: 'Who can see this (partner, counsellor, both)' },
      { name: 'timestamp', type: 'N', description: 'Unix timestamp in milliseconds' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'conversationId-timestamp-index',
        keys: {
          partitionKey: { name: 'conversationId', type: 'S' },
          sortKey: { name: 'timestamp', type: 'N' }
        },
        projection: 'ALL',
        description: 'Query messages by conversation in chronological order'
      },
      {
        indexName: 'userId-index',
        keys: {
          partitionKey: { name: 'senderId', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query all messages sent by a user'
      }
    ]
  },

  subscriptions: {
    tableName: 'we-counsel-subscriptions',
    description: 'Subscription history and payment records',
    primaryKey: {
      partitionKey: { name: 'subscriptionId', type: 'S' }
    },
    attributes: [
      { name: 'subscriptionId', type: 'S', description: 'Unique subscription record identifier (UUID)' },
      { name: 'coupleId', type: 'S', description: 'Couple who owns the subscription' },
      { name: 'tier', type: 'S', description: 'Subscription tier (free, essential, premium)' },
      { name: 'status', type: 'S', description: 'Status (active, canceled, expired)' },
      { name: 'billingPeriod', type: 'S', description: 'Billing period (monthly, annual)' },
      { name: 'amount', type: 'N', description: 'Amount paid in cents' },
      { name: 'currency', type: 'S', description: 'Currency code (USD, EUR)' },
      { name: 'startDate', type: 'S', description: 'ISO timestamp when subscription started' },
      { name: 'endDate', type: 'S', description: 'ISO timestamp when subscription ends' },
      { name: 'canceledAt', type: 'S', description: 'ISO timestamp when subscription was canceled' },
      { name: 'paymentProvider', type: 'S', description: 'Payment provider (stripe, paypal)' },
      { name: 'paymentId', type: 'S', description: 'External payment ID from provider' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'coupleId-index',
        keys: {
          partitionKey: { name: 'coupleId', type: 'S' },
          sortKey: { name: 'createdAt', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query subscription history by couple'
      }
    ]
  },

  exercises: {
    tableName: 'we-counsel-exercises',
    description: 'Exercise templates and definitions',
    primaryKey: {
      partitionKey: { name: 'exerciseId', type: 'S' }
    },
    attributes: [
      { name: 'exerciseId', type: 'S', description: 'Unique exercise identifier (UUID)' },
      { name: 'name', type: 'S', description: 'Exercise name' },
      { name: 'description', type: 'S', description: 'Exercise description' },
      { name: 'category', type: 'S', description: 'Exercise category (communication, conflict, appreciation, etc.)' },
      { name: 'duration', type: 'N', description: 'Estimated duration in minutes' },
      { name: 'steps', type: 'S', description: 'JSON array of exercise steps' },
      { name: 'isActive', type: 'BOOL', description: 'Whether exercise is available' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'category-index',
        keys: {
          partitionKey: { name: 'category', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query exercises by category'
      }
    ]
  },

  exerciseSessions: {
    tableName: 'we-counsel-exercise-sessions',
    description: 'Active and completed exercise sessions',
    primaryKey: {
      partitionKey: { name: 'sessionId', type: 'S' }
    },
    attributes: [
      { name: 'sessionId', type: 'S', description: 'Unique session identifier (UUID)' },
      { name: 'coupleId', type: 'S', description: 'Couple performing the exercise' },
      { name: 'conversationId', type: 'S', description: 'Conversation where exercise is happening' },
      { name: 'exerciseId', type: 'S', description: 'Exercise being performed' },
      { name: 'status', type: 'S', description: 'Session status (active, completed, abandoned)' },
      { name: 'currentStep', type: 'N', description: 'Current step number' },
      { name: 'progress', type: 'S', description: 'JSON object tracking progress and responses' },
      { name: 'summary', type: 'S', description: 'AI-generated summary after completion' },
      { name: 'startedAt', type: 'S', description: 'ISO timestamp when started' },
      { name: 'completedAt', type: 'S', description: 'ISO timestamp when completed' },
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
    ],
    globalSecondaryIndexes: [
      {
        indexName: 'coupleId-index',
        keys: {
          partitionKey: { name: 'coupleId', type: 'S' },
          sortKey: { name: 'createdAt', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query exercise sessions by couple'
      },
      {
        indexName: 'conversationId-index',
        keys: {
          partitionKey: { name: 'conversationId', type: 'S' }
        },
        projection: 'ALL',
        description: 'Query sessions by conversation'
      }
    ]
  }
};

module.exports = {
  SCHEMA_VERSION,
  tables
};
