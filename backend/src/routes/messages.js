const express = require('express');
const { docClient, TABLES } = require('../config/database');
const { authenticateToken } = require('../middleware/authMiddleware');
const { generateCounsellorResponse } = require('../services/aiService');
const { randomUUID } = require('crypto');

const router = express.Router();

// @route   GET /api/messages/:conversationId
// @desc    Get all messages for a conversation
// @access  Private
router.get('/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { limit = 50, lastMessageId } = req.query;

    // First verify user has access to this conversation
    const conversationParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const conversationResult = await docClient.get(conversationParams).promise();

    if (!conversationResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    if (conversationResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    // Get messages
    let messagesParams = {
      TableName: TABLES.MESSAGES,
      IndexName: 'conversation-timestamp-index',
      KeyConditionExpression: 'conversationId = :conversationId',
      ExpressionAttributeValues: {
        ':conversationId': conversationId
      },
      ScanIndexForward: false, // Get newest first
      Limit: parseInt(limit)
    };

    // Pagination
    if (lastMessageId) {
      // Would need to implement proper pagination with LastEvaluatedKey
      // This is a simplified version
    }

    const messagesResult = await docClient.query(messagesParams).promise();

    // Reverse to show oldest first
    const messages = messagesResult.Items.reverse();

    res.json({
      success: true,
      messages,
      conversationTitle: conversationResult.Item.title
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get messages'
    });
  }
});

// @route   POST /api/messages/:conversationId
// @desc    Send a message in a conversation
// @access  Private
router.post('/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { content, recipientType = 'both' } = req.body; // recipientType: 'both', 'partner', 'counsellor'

    // Validation
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Message content is required'
      });
    }

    // Verify user has access to this conversation
    const conversationParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const conversationResult = await docClient.get(conversationParams).promise();

    if (!conversationResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Conversation not found'
      });
    }

    if (conversationResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this conversation'
      });
    }

    const conversation = conversationResult.Item;
    const messageId = randomUUID();
    const timestamp = Date.now();

    // Create user message
    const messageData = {
      messageId,
      conversationId,
      senderId: req.user.userId,
      senderName: `${req.user.firstName} ${req.user.lastName}`,
      senderType: 'user',
      content: content.trim(),
      recipientType,
      timestamp,
      createdAt: new Date().toISOString()
    };

    // Save user message
    const messageParams = {
      TableName: TABLES.MESSAGES,
      Item: messageData
    };

    await docClient.put(messageParams).promise();

    // Update conversation last message time and count
    const updateConversationParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId },
      UpdateExpression: 'SET lastMessageAt = :lastMessageAt, messageCount = messageCount + :increment',
      ExpressionAttributeValues: {
        ':lastMessageAt': new Date().toISOString(),
        ':increment': 1
      }
    };

    await docClient.update(updateConversationParams).promise();

    // Generate AI counsellor response if appropriate
    let aiResponse = null;
    if (recipientType === 'both' || recipientType === 'counsellor') {
      try {
        // Get recent messages for context
        const recentMessagesParams = {
          TableName: TABLES.MESSAGES,
          IndexName: 'conversation-timestamp-index',
          KeyConditionExpression: 'conversationId = :conversationId',
          ExpressionAttributeValues: {
            ':conversationId': conversationId
          },
          ScanIndexForward: false,
          Limit: 10
        };

        const recentMessagesResult = await docClient.query(recentMessagesParams).promise();
        const recentMessages = recentMessagesResult.Items.reverse();

        const aiResponseContent = await generateCounsellorResponse({
          messages: [...recentMessages, messageData],
          context: `Conversation: ${conversation.title}${conversation.topic ? `, Topic: ${conversation.topic}` : ''}`
        });

        const aiMessageId = randomUUID();
        const aiTimestamp = Date.now() + 1; // Ensure AI message comes after user message

        aiResponse = {
          messageId: aiMessageId,
          conversationId,
          senderId: 'ai-counsellor',
          senderName: 'Dr. Sarah (AI Counsellor)',
          senderType: 'ai',
          content: aiResponseContent,
          recipientType: 'both',
          timestamp: aiTimestamp,
          createdAt: new Date().toISOString()
        };

        // Save AI response
        const aiMessageParams = {
          TableName: TABLES.MESSAGES,
          Item: aiResponse
        };

        await docClient.put(aiMessageParams).promise();

        // Update conversation count again
        await docClient.update({
          ...updateConversationParams,
          UpdateExpression: 'SET lastMessageAt = :lastMessageAt, messageCount = messageCount + :increment',
          ExpressionAttributeValues: {
            ':lastMessageAt': new Date().toISOString(),
            ':increment': 1
          }
        }).promise();

      } catch (aiError) {
        console.error('AI response generation failed:', aiError);
        // Continue without AI response
      }
    }

    const response = {
      success: true,
      message: 'Message sent successfully',
      userMessage: messageData
    };

    if (aiResponse) {
      response.aiResponse = aiResponse;
    }

    res.status(201).json(response);

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to send message'
    });
  }
});

// @route   PUT /api/messages/:messageId
// @desc    Edit a message (only for user messages, within time limit)
// @access  Private
router.put('/:messageId', authenticateToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { content } = req.body;

    // Validation
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Message content is required'
      });
    }

    // Get the message
    const messageParams = {
      TableName: TABLES.MESSAGES,
      Key: { messageId }
    };

    const messageResult = await docClient.get(messageParams).promise();

    if (!messageResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Message not found'
      });
    }

    const message = messageResult.Item;

    // Check if user owns this message
    if (message.senderId !== req.user.userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only edit your own messages'
      });
    }

    // Check if message is editable (AI messages cannot be edited)
    if (message.senderType !== 'user') {
      return res.status(400).json({
        error: 'Cannot edit',
        message: 'Only user messages can be edited'
      });
    }

    // Check time limit (e.g., 15 minutes)
    const messageTime = new Date(message.createdAt);
    const now = new Date();
    const timeDiff = (now - messageTime) / (1000 * 60); // minutes

    if (timeDiff > 15) {
      return res.status(400).json({
        error: 'Time limit exceeded',
        message: 'Messages can only be edited within 15 minutes of sending'
      });
    }

    // Update the message
    const updateParams = {
      TableName: TABLES.MESSAGES,
      Key: { messageId },
      UpdateExpression: 'SET content = :content, editedAt = :editedAt, isEdited = :isEdited',
      ExpressionAttributeValues: {
        ':content': content.trim(),
        ':editedAt': new Date().toISOString(),
        ':isEdited': true
      },
      ReturnValues: 'ALL_NEW'
    };

    const result = await docClient.update(updateParams).promise();

    res.json({
      success: true,
      message: 'Message updated successfully',
      updatedMessage: result.Attributes
    });

  } catch (error) {
    console.error('Edit message error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to edit message'
    });
  }
});

// @route   DELETE /api/messages/:messageId
// @desc    Delete a message (only for user messages)
// @access  Private
router.delete('/:messageId', authenticateToken, async (req, res) => {
  try {
    const { messageId } = req.params;

    // Get the message
    const messageParams = {
      TableName: TABLES.MESSAGES,
      Key: { messageId }
    };

    const messageResult = await docClient.get(messageParams).promise();

    if (!messageResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Message not found'
      });
    }

    const message = messageResult.Item;

    // Check if user owns this message
    if (message.senderId !== req.user.userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only delete your own messages'
      });
    }

    // Check if message is deletable
    if (message.senderType !== 'user') {
      return res.status(400).json({
        error: 'Cannot delete',
        message: 'Only user messages can be deleted'
      });
    }

    // Soft delete - mark as deleted instead of removing
    const updateParams = {
      TableName: TABLES.MESSAGES,
      Key: { messageId },
      UpdateExpression: 'SET isDeleted = :isDeleted, deletedAt = :deletedAt',
      ExpressionAttributeValues: {
        ':isDeleted': true,
        ':deletedAt': new Date().toISOString()
      }
    };

    await docClient.update(updateParams).promise();

    res.json({
      success: true,
      message: 'Message deleted successfully'
    });

  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to delete message'
    });
  }
});

module.exports = router;
