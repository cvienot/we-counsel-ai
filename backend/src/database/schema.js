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
      { name: 'termsAcceptedVersion', type: 'S', description: 'Version of terms accepted (e.g., "1.0.0")' }
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
      { name: 'createdAt', type: 'S', description: 'ISO timestamp of creation' }
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
      { name: 'isMainThread', type: 'BOOL', description: 'Whether this is the main conversation' },
      { name: 'isActive', type: 'BOOL', description: 'Whether conversation is active' },
      { name: 'lastMessageAt', type: 'S', description: 'ISO timestamp of last message' },
      { name: 'messageCount', type: 'N', description: 'Total number of messages' },
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
  }
};

module.exports = {
  SCHEMA_VERSION,
  tables
};
