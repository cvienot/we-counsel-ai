const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const streamingService = require('../services/streamingService');
const { docClient, TABLES } = require('../config/database');

const router = express.Router();

// @route   GET /api/streaming/events
// @desc    Establish SSE connection for real-time updates
// @access  Private
router.get('/events', authenticateToken, (req, res) => {
  // Add this connection to the streaming service
  streamingService.addConnection(req.user.userId, res);
});

// @route   POST /api/streaming/typing
// @desc    Update typing status
// @access  Private
router.post('/typing', authenticateToken, async (req, res) => {
  try {
    const { conversationId, isTyping } = req.body;

    if (!conversationId || typeof isTyping !== 'boolean') {
      return res.status(400).json({
        error: 'Bad request',
        message: 'conversationId and isTyping (boolean) are required'
      });
    }

    // Verify user has access to this conversation
    const params = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const result = await docClient.get(params).promise();
    const conversation = result.Item;

    if (!conversation) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    if (conversation.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    // Update typing status
    streamingService.setTyping(conversationId, req.user.userId, isTyping);

    res.json({
      success: true,
      message: 'Typing status updated'
    });

  } catch (error) {
    console.error('Update typing status error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to update typing status'
    });
  }
});

// @route   GET /api/streaming/conversation/:conversationId/status
// @desc    Get current conversation status (who's typing, etc.)
// @access  Private
router.get('/conversation/:conversationId/status', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;

    // Verify user has access to this conversation
    const params = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const result = await docClient.get(params).promise();
    const conversation = result.Item;

    if (!conversation) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    if (conversation.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    // Get typing users for this conversation
    const typingUsers = streamingService.typingUsers.get(conversationId) || new Set();
    const otherUsersTyping = Array.from(typingUsers).filter(userId => userId !== req.user.userId);

    res.json({
      success: true,
      status: {
        conversationId,
        typingUsers: otherUsersTyping,
        timestamp: Date.now()
      }
    });

  } catch (error) {
    console.error('Get conversation status error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get conversation status'
    });
  }
});

module.exports = router;
