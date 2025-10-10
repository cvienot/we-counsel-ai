const express = require('express');
const { docClient, TABLES } = require('../config/database');
const { authenticateToken } = require('../middleware/authMiddleware');
const { randomUUID } = require('crypto');

const router = express.Router();

// @route   GET /api/conversations
// @desc    Get all conversations for the user's couple
// @access  Private
router.get('/', authenticateToken, async (req, res) => {
  try {
    if (!req.user.coupleId) {
      return res.status(400).json({
        error: 'No couple',
        message: 'You need to be paired with a partner to access conversations'
      });
    }

    const params = {
      TableName: TABLES.CONVERSATIONS,
      IndexName: 'couple-index',
      KeyConditionExpression: 'coupleId = :coupleId',
      ExpressionAttributeValues: {
        ':coupleId': req.user.coupleId
      },
      ScanIndexForward: false // Sort by creation date descending
    };

    const result = await docClient.query(params).promise();

    res.json({
      success: true,
      conversations: result.Items
    });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get conversations'
    });
  }
});

// @route   GET /api/conversations/main-thread
// @desc    Get or create the main thread for a couple
// @access  Private
router.get('/main-thread', authenticateToken, async (req, res) => {
  try {
    if (!req.user.coupleId) {
      return res.status(400).json({
        error: 'No couple',
        message: 'You need to be paired with a partner to access the main thread'
      });
    }

    // First, try to get existing main thread
    const params = {
      TableName: TABLES.CONVERSATIONS,
      IndexName: 'couple-index',
      KeyConditionExpression: 'coupleId = :coupleId',
      FilterExpression: 'isMainThread = :isMainThread',
      ExpressionAttributeValues: {
        ':coupleId': req.user.coupleId,
        ':isMainThread': true
      }
    };

    const result = await docClient.query(params).promise();

    if (result.Items && result.Items.length > 0) {
      // Main thread exists, return it
      return res.json({
        success: true,
        mainThread: result.Items[0]
      });
    }

    // No main thread exists, create one
    const conversationId = randomUUID();
    const mainThreadData = {
      conversationId,
      coupleId: req.user.coupleId,
      title: 'Main Conversation',
      topic: 'Your ongoing journey together',
      createdBy: req.user.userId,
      createdAt: new Date().toISOString(),
      lastMessageAt: new Date().toISOString(),
      isActive: true,
      isMainThread: true,
      messageCount: 0
    };

    const createParams = {
      TableName: TABLES.CONVERSATIONS,
      Item: mainThreadData
    };

    await docClient.put(createParams).promise();

    res.json({
      success: true,
      mainThread: mainThreadData
    });

  } catch (error) {
    console.error('Get/Create main thread error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get or create main thread'
    });
  }
});

// @route   POST /api/conversations
// @desc    Create a new conversation
// @access  Private
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { title, topic, isMainThread = false } = req.body;

    if (!req.user.coupleId) {
      return res.status(400).json({
        error: 'No couple',
        message: 'You need to be paired with a partner to create conversations'
      });
    }

    // Validation
    if (!title) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Conversation title is required'
      });
    }

    // Check if trying to create another main thread
    if (isMainThread) {
      const mainThreadParams = {
        TableName: TABLES.CONVERSATIONS,
        IndexName: 'couple-index',
        KeyConditionExpression: 'coupleId = :coupleId',
        FilterExpression: 'isMainThread = :isMainThread',
        ExpressionAttributeValues: {
          ':coupleId': req.user.coupleId,
          ':isMainThread': true
        }
      };

      const existingMainThread = await docClient.query(mainThreadParams).promise();
      if (existingMainThread.Items && existingMainThread.Items.length > 0) {
        return res.status(400).json({
          error: 'Main thread exists',
          message: 'A main thread already exists for this couple'
        });
      }
    }

    const conversationId = randomUUID();
    const conversationData = {
      conversationId,
      coupleId: req.user.coupleId,
      title: title.trim(),
      topic: topic?.trim() || '',
      createdBy: req.user.userId,
      createdAt: new Date().toISOString(),
      lastMessageAt: new Date().toISOString(),
      isActive: true,
      isMainThread: isMainThread,
      messageCount: 0
    };

    const params = {
      TableName: TABLES.CONVERSATIONS,
      Item: conversationData
    };

    await docClient.put(params).promise();

    res.status(201).json({
      success: true,
      message: 'Conversation created successfully',
      conversation: conversationData
    });

  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to create conversation'
    });
  }
});

// @route   GET /api/conversations/:conversationId
// @desc    Get a specific conversation
// @access  Private
router.get('/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;

    const params = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const result = await docClient.get(params).promise();

    if (!result.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    const conversation = result.Item;

    // Check if user has access to this conversation
    if (conversation.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    res.json({
      success: true,
      conversation
    });

  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get conversation'
    });
  }
});

// @route   PUT /api/conversations/:conversationId
// @desc    Update a conversation
// @access  Private
router.put('/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { title, topic } = req.body;

    // Validation
    if (!title) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Conversation title is required'
      });
    }

    // First get the conversation to check permissions
    const getParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const getResult = await docClient.get(getParams).promise();

    if (!getResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    // Check if user has access to this conversation
    if (getResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    const updateParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId },
      UpdateExpression: 'SET title = :title, topic = :topic, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':title': title.trim(),
        ':topic': topic?.trim() || '',
        ':updatedAt': new Date().toISOString()
      },
      ReturnValues: 'ALL_NEW'
    };

    const updateResult = await docClient.update(updateParams).promise();

    res.json({
      success: true,
      message: 'Conversation updated successfully',
      conversation: updateResult.Attributes
    });

  } catch (error) {
    console.error('Update conversation error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to update conversation'
    });
  }
});

// @route   DELETE /api/conversations/:conversationId
// @desc    Delete/Archive a conversation
// @access  Private
router.delete('/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;

    // First get the conversation to check permissions
    const getParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const getResult = await docClient.get(getParams).promise();

    if (!getResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    // Check if user has access to this conversation
    if (getResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    // Archive instead of delete
    const updateParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId },
      UpdateExpression: 'SET isActive = :isActive, archivedAt = :archivedAt',
      ExpressionAttributeValues: {
        ':isActive': false,
        ':archivedAt': new Date().toISOString()
      }
    };

    await docClient.update(updateParams).promise();

    res.json({
      success: true,
      message: 'Conversation archived successfully'
    });

  } catch (error) {
    console.error('Archive conversation error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to archive conversation'
    });
  }
});

module.exports = router;
