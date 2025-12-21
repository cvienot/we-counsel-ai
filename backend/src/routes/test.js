const express = require('express');
const router = express.Router();

/**
 * Testing endpoints - only available when ENABLE_TEST_ENDPOINTS=true
 * These endpoints allow E2E tests to verify mock behavior
 */

if (process.env.ENABLE_TEST_ENDPOINTS === 'true') {
  // Get all mock emails sent
  router.get('/emails', (req, res) => {
    res.json({
      success: true,
      emails: global.mockEmailStore || [],
      count: (global.mockEmailStore || []).length
    });
  });

  // Get mock emails filtered by type
  router.get('/emails/:type', (req, res) => {
    const { type } = req.params;
    const filtered = (global.mockEmailStore || []).filter(email => email.type === type);
    
    res.json({
      success: true,
      emails: filtered,
      count: filtered.length
    });
  });

  // Get all mock AI responses
  router.get('/ai-responses', (req, res) => {
    res.json({
      success: true,
      responses: global.mockAIStore || [],
      count: (global.mockAIStore || []).length
    });
  });

  // Reset all mock stores
  router.post('/reset', (req, res) => {
    global.mockEmailStore = [];
    global.mockAIStore = [];
    
    res.json({
      success: true,
      message: 'All mock stores reset'
    });
  });

  // Connect two users as partners (for E2E testing)
  router.post('/connect-partners', async (req, res) => {
    const { user1Id, user2Id } = req.body;
    
    if (!user1Id || !user2Id) {
      return res.status(400).json({
        error: 'Missing user IDs',
        message: 'user1Id and user2Id are required'
      });
    }

    try {
      const { docClient, TABLES, PutCommand, UpdateCommand, GetCommand } = require('../config/database');
      const { randomUUID } = require('crypto');

      // Create couple record
      const coupleId = randomUUID();
      const currentTimestamp = new Date().toISOString();
      const nextResetDate = new Date();
      nextResetDate.setMonth(nextResetDate.getMonth() + 1, 1);
      
      const subscriptionTier = req.body.subscriptionTier || 'premium'; // Default to premium for tests
      
      const coupleData = {
        coupleId,
        user1Id,
        user2Id,
        status: 'active',
        createdAt: currentTimestamp,
        // Initialize subscription for the couple
        subscriptionTier,
        subscriptionStatus: 'active',
        subscriptionStartDate: currentTimestamp,
        aiMessagesUsed: 0,
        aiMessagesResetDate: nextResetDate.toISOString()
      };

      await docClient.send(new PutCommand({
        TableName: TABLES.COUPLES,
        Item: coupleData
      }));

      // Update both users with partnerId and coupleId
      await docClient.send(new UpdateCommand({
        TableName: TABLES.USERS,
        Key: { userId: user1Id },
        UpdateExpression: 'SET partnerId = :partnerId, coupleId = :coupleId',
        ExpressionAttributeValues: {
          ':partnerId': user2Id,
          ':coupleId': coupleId
        }
      }));

      await docClient.send(new UpdateCommand({
        TableName: TABLES.USERS,
        Key: { userId: user2Id },
        UpdateExpression: 'SET partnerId = :partnerId, coupleId = :coupleId',
        ExpressionAttributeValues: {
          ':partnerId': user1Id,
          ':coupleId': coupleId
        }
      }));

      res.json({
        success: true,
        message: 'Partners connected successfully',
        coupleId
      });
    } catch (error) {
      console.error('Error connecting partners:', error);
      res.status(500).json({
        error: 'Failed to connect partners',
        message: error.message
      });
    }
  });

  // Get test environment status
  router.get('/status', (req, res) => {
    res.json({
      success: true,
      environment: {
        mockEmail: process.env.MOCK_EMAIL === 'true',
        mockAI: process.env.MOCK_AI === 'true',
        dynamodbEndpoint: process.env.DYNAMODB_ENDPOINT || 'AWS',
        nodeEnv: process.env.NODE_ENV
      },
      stores: {
        emailCount: (global.mockEmailStore || []).length,
        aiResponseCount: (global.mockAIStore || []).length
      }
    });
  });

  console.log('✅ Test endpoints enabled at /api/test/*');
} else {
  // Return 404 if test endpoints are not enabled
  router.use('*', (req, res) => {
    res.status(404).json({
      error: 'Test endpoints not enabled',
      message: 'Set ENABLE_TEST_ENDPOINTS=true to enable test endpoints'
    });
  });
}

module.exports = router;
