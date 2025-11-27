#!/usr/bin/env node
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, UpdateCommand, PutCommand, TransactWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { randomUUID } = require('crypto');

const client = new DynamoDBClient({ region: 'eu-west-3' });
const docClient = DynamoDBDocumentClient.from(client);

const TABLES = {
  USERS: 'we-counsel-users',
  COUPLES: 'we-counsel-couples',
  INVITATIONS: 'we-counsel-invitations',
  CONVERSATIONS: 'we-counsel-conversations'
};

async function connectPartners(user1Id, user2Id, invitationId) {
  try {
    console.log('Connecting partners...');
    console.log(`User 1: ${user1Id}`);
    console.log(`User 2: ${user2Id}`);
    console.log(`Invitation: ${invitationId}`);

    // Create couple
    const coupleId = randomUUID();
    const coupleData = {
      coupleId,
      partner1Id: user1Id,
      partner2Id: user2Id,
      createdAt: new Date().toISOString(),
      isActive: true
    };

    // Create main conversation
    const conversationId = randomUUID();
    const conversationData = {
      conversationId,
      coupleId,
      title: 'Main Conversation',
      topic: 'Your ongoing journey together',
      createdAt: new Date().toISOString(),
      isActive: true,
      isMainThread: true
    };

    // Transaction to update everything
    const transactItems = [
      {
        Put: {
          TableName: TABLES.COUPLES,
          Item: coupleData
        }
      },
      {
        Put: {
          TableName: TABLES.CONVERSATIONS,
          Item: conversationData
        }
      },
      {
        Update: {
          TableName: TABLES.USERS,
          Key: { userId: user1Id },
          UpdateExpression: 'SET partnerId = :partnerId, coupleId = :coupleId, updatedAt = :updatedAt',
          ExpressionAttributeValues: {
            ':partnerId': user2Id,
            ':coupleId': coupleId,
            ':updatedAt': new Date().toISOString()
          }
        }
      },
      {
        Update: {
          TableName: TABLES.USERS,
          Key: { userId: user2Id },
          UpdateExpression: 'SET partnerId = :partnerId, coupleId = :coupleId, updatedAt = :updatedAt',
          ExpressionAttributeValues: {
            ':partnerId': user1Id,
            ':coupleId': coupleId,
            ':updatedAt': new Date().toISOString()
          }
        }
      },
      {
        Update: {
          TableName: TABLES.INVITATIONS,
          Key: { invitationId },
          UpdateExpression: 'SET #status = :status, acceptedAt = :acceptedAt',
          ExpressionAttributeNames: {
            '#status': 'status'
          },
          ExpressionAttributeValues: {
            ':status': 'accepted',
            ':acceptedAt': new Date().toISOString()
          }
        }
      }
    ];

    await docClient.send(new TransactWriteCommand({
      TransactItems: transactItems
    }));

    console.log('✅ Partners connected successfully!');
    console.log(`Couple ID: ${coupleId}`);
    console.log(`Main Conversation ID: ${conversationId}`);
    
  } catch (error) {
    console.error('❌ Error connecting partners:', error);
    throw error;
  }
}

// Get parameters from command line
const user1Id = process.argv[2];
const user2Id = process.argv[3];
const invitationId = process.argv[4];

if (!user1Id || !user2Id || !invitationId) {
  console.error('Usage: node connect-partners.js <user1Id> <user2Id> <invitationId>');
  process.exit(1);
}

connectPartners(user1Id, user2Id, invitationId)
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
