const express = require('express');
const { docClient, TABLES, PutCommand, QueryCommand, GetCommand, UpdateCommand } = require('../config/database');
const { authenticateToken } = require('../middleware/authMiddleware');
const { checkAIMessageLimit } = require('../middleware/subscriptionMiddleware');
const { aiService } = require('../services');
const { generateCoachResponse, summarizeConversation } = aiService;
const subscriptionService = require('../services/subscriptionService');
const streamingService = require('../services/streamingService');
const { randomUUID } = require('crypto');

const router = express.Router();

// Helper function to get user's full name with fallback
const getUserFullName = (user) => {
  const firstName = user.firstName || 'User';
  const lastName = user.lastName || '';
  return `${firstName} ${lastName}`.trim();
};

// Helper function to build context with smart summarization
const buildConversationContext = async (conversation, recentMessages) => {
  const messageCount = conversation.messageCount || 0;
  const RECENT_WINDOW = 15; // Keep last 15 messages in full
  const SUMMARY_THRESHOLD = 20; // Summarize every 20 messages
  
  let contextMessages = recentMessages;
  let contextPrefix = '';

  // If we have more messages than the recent window, check if we need to update summary
  if (messageCount > RECENT_WINDOW) {
    const summarizedCount = conversation.summarizedMessageCount || 0;
    const unsummarizedCount = messageCount - summarizedCount;

    // Need to generate or update summary if we have 20+ new messages since last summary
    if (unsummarizedCount >= SUMMARY_THRESHOLD) {
      console.log(`📊 Generating summary for conversation ${conversation.conversationId} (${unsummarizedCount} new messages)`);
      
      try {
        // Get all messages that haven't been summarized yet
        const oldMessagesParams = {
          TableName: TABLES.MESSAGES,
          IndexName: 'conversationId-timestamp-index',
          KeyConditionExpression: 'conversationId = :conversationId',
          ExpressionAttributeValues: {
            ':conversationId': conversation.conversationId
          },
          ScanIndexForward: true, // Oldest first
          Limit: messageCount - RECENT_WINDOW // Everything except recent window
        };

        const oldMessagesResult = await docClient.send(new QueryCommand(oldMessagesParams));
        const messagesToSummarize = oldMessagesResult.Items;

        // Generate summary of older messages
        console.log(`🔍 Type check: summarizeConversation = ${typeof summarizeConversation}`);
        const summary = await summarizeConversation({
          messages: messagesToSummarize,
          conversationTitle: conversation.title
        });

        // Update conversation with new summary
        const updateParams = {
          TableName: TABLES.CONVERSATIONS,
          Key: { conversationId: conversation.conversationId },
          UpdateExpression: 'SET summary = :summary, lastSummarizedAt = :timestamp, summarizedMessageCount = :count',
          ExpressionAttributeValues: {
            ':summary': summary,
            ':timestamp': new Date().toISOString(),
            ':count': messageCount - RECENT_WINDOW
          }
        };

        await docClient.send(new UpdateCommand(updateParams));
        
        contextPrefix = `**Session History Summary:**\n${summary}\n\n**Recent conversation:**\n`;
        console.log(`✅ Summary generated and stored`);
      } catch (error) {
        console.error(`❌ Error generating summary:`, error);
        throw error;
      }
    } else if (conversation.summary) {
      // Use existing summary
      contextPrefix = `**Session History Summary:**\n${conversation.summary}\n\n**Recent conversation:**\n`;
    }
  }

  return {
    messages: contextMessages,
    contextPrefix,
    hasSummary: !!contextPrefix
  };
};

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

    const conversationResult = await docClient.send(new GetCommand(conversationParams));

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
      IndexName: 'conversationId-timestamp-index',
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

    const messagesResult = await docClient.send(new QueryCommand(messagesParams));

    // Reverse to show oldest first
    const rawMessages = messagesResult.Items.reverse();

    // Get unique user IDs from messages
    const userIds = [...new Set(
      rawMessages
        .filter(m => m.senderType === 'user')
        .map(m => m.senderId)
    )];

    // Fetch user information for all senders
    const userMap = {};
    if (userIds.length > 0) {
      const userPromises = userIds.map(userId =>
        docClient.send(new GetCommand({
          TableName: TABLES.USERS,
          Key: { userId }
        }))
      );
      
      const userResults = await Promise.all(userPromises);
      userResults.forEach(result => {
        if (result.Item) {
          userMap[result.Item.userId] = getUserFullName(result.Item);
        }
      });
    }

    // Populate sender names dynamically
    const messages = rawMessages.map(message => {
      if (message.senderType === 'user' && userMap[message.senderId]) {
        return {
          ...message,
          senderName: userMap[message.senderId]
        };
      }
      return message;
    });

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

// @route   POST /api/messages/:conversationId/ai-stream
// @desc    Send a message and get streaming AI response
// @access  Private (requires subscription check for AI messages)
router.post('/:conversationId/ai-stream', authenticateToken, checkAIMessageLimit, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { content, recipientType = 'both' } = req.body;

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

    const conversationResult = await docClient.send(new GetCommand(conversationParams));

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
      senderName: getUserFullName(req.user),
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

    await docClient.send(new PutCommand(messageParams));

    // Send real-time message notification to partner
    streamingService.sendMessageNotification(conversationId, req.user.userId, messageData);

    // Update conversation
    const updateConversationParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId },
      UpdateExpression: 'SET lastMessageAt = :lastMessageAt, messageCount = if_not_exists(messageCount, :zero) + :increment',
      ExpressionAttributeValues: {
        ':lastMessageAt': new Date().toISOString(),
        ':increment': 1,
        ':zero': 0
      }
    };

    await docClient.send(new UpdateCommand(updateConversationParams));

    // Return user message immediately
    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      userMessage: messageData
    });

    // Generate streaming AI response if appropriate
    if (recipientType === 'both' || recipientType === 'coach') {
      try {
        // Get recent messages for context
        const recentMessagesParams = {
          TableName: TABLES.MESSAGES,
          IndexName: 'conversationId-timestamp-index',
          KeyConditionExpression: 'conversationId = :conversationId',
          ExpressionAttributeValues: {
            ':conversationId': conversationId
          },
          ScanIndexForward: false,
          Limit: 15 // Increased from 10 to 15 for better context
        };

        const recentMessagesResult = await docClient.send(new QueryCommand(recentMessagesParams));
        const recentMessages = recentMessagesResult.Items.reverse();

        // Get updated conversation with current message count for summarization
        const updatedConversationResult = await docClient.send(new GetCommand(conversationParams));
        const updatedConversation = updatedConversationResult.Item;

        // Build smart context with summarization
        const { messages: contextMessages, contextPrefix } = await buildConversationContext(
          updatedConversation,
          recentMessages
        );

        const contextString = `${contextPrefix}Conversation: ${conversation.title}${conversation.topic ? `, Topic: ${conversation.topic}` : ''}`;

        // Fetch both partner names from the couple
        let partnerNames = null;
        try {
          const coupleParams = {
            TableName: TABLES.COUPLES,
            Key: { coupleId: req.user.coupleId }
          };
          const coupleResult = await docClient.send(new GetCommand(coupleParams));
          
          if (coupleResult.Item) {
            const couple = coupleResult.Item;
            // Get both users
            const user1Params = {
              TableName: TABLES.USERS,
              Key: { userId: couple.user1Id }
            };
            const user2Params = {
              TableName: TABLES.USERS,
              Key: { userId: couple.user2Id }
            };
            
            const [user1Result, user2Result] = await Promise.all([
              docClient.send(new GetCommand(user1Params)),
              docClient.send(new GetCommand(user2Params))
            ]);
            
            if (user1Result.Item && user2Result.Item) {
              partnerNames = {
                partner1: user1Result.Item.firstName || 'Partner 1',
                partner2: user2Result.Item.firstName || 'Partner 2'
              };
            }
          }
        } catch (error) {
          console.error('Error fetching partner names:', error);
          // Continue without names if fetch fails
        }

        const aiMessageId = randomUUID();
        let aiResponseContent = '';

        // Stream AI response with proper error handling
        try {
          await generateCoachResponse({
            messages: [...contextMessages, messageData],
            context: contextString,
            partnerNames,
            onChunk: async (chunk) => {
              aiResponseContent += chunk;
              await streamingService.streamAIResponse(conversationId, aiMessageId, chunk, false);
            },
            onComplete: async (fullResponse) => {
              // Save complete AI response to database
              const aiResponse = {
                messageId: aiMessageId,
                conversationId,
                senderId: 'ai-coach',
                senderName: 'Coach Sarah (AI Relationship Coach)',
                senderType: 'ai',
                content: fullResponse,
                recipientType: 'both',
                timestamp: Date.now(),
                createdAt: new Date().toISOString()
              };

              const aiMessageParams = {
                TableName: TABLES.MESSAGES,
                Item: aiResponse
              };

              await docClient.send(new PutCommand(aiMessageParams));

              // Update conversation count
              await docClient.send(new UpdateCommand({
                ...updateConversationParams,
                UpdateExpression: 'SET lastMessageAt = :lastMessageAt, messageCount = messageCount + :increment',
                ExpressionAttributeValues: {
                  ':lastMessageAt': new Date().toISOString(),
                  ':increment': 1
                }
              }));

              // Send completion notification
              streamingService.streamAIResponse(conversationId, aiMessageId, '', true);
              streamingService.sendMessageNotification(conversationId, 'ai-coach', aiResponse);
              
              // Increment AI message usage counter
              await subscriptionService.incrementAIMessageUsage(req.user.userId);
            },
            onError: (error) => {
              console.error('AI streaming error:', error);
              // Send error message to stream
              streamingService.streamAIResponse(conversationId, aiMessageId, '❌ I apologize, but I\'m experiencing technical difficulties right now. Please try again in a moment.', true);
            }
          });
        } catch (aiError) {
          console.error('AI response generation failed:', aiError);
          
          // Create an error message that will be saved and sent to both users
          const errorMessage = {
            messageId: aiMessageId,
            conversationId,
            senderId: 'ai-counsellor',
            senderName: 'Coach Sarah (AI Relationship Coach)',
            senderType: 'ai',
            content: '❌ I apologize, but I\'m currently unable to respond due to technical issues. Your conversation is still being saved, and I\'ll be back online soon.',
            recipientType: 'both',
            timestamp: Date.now(),
            createdAt: new Date().toISOString()
          };

          // Save error message to database
          try {
            const errorMessageParams = {
              TableName: TABLES.MESSAGES,
              Item: errorMessage
            };
            await docClient.send(new PutCommand(errorMessageParams));

            // Update conversation count for error message too
            await docClient.update({
              ...updateConversationParams,
              UpdateExpression: 'SET lastMessageAt = :lastMessageAt, messageCount = messageCount + :increment',
              ExpressionAttributeValues: {
                ':lastMessageAt': new Date().toISOString(),
                ':increment': 1
              }
            }).promise();

            // Send error message to both users via streaming
            streamingService.sendMessageNotification(conversationId, 'ai-counsellor', errorMessage);
          } catch (dbError) {
            console.error('Failed to save AI error message:', dbError);
            // At least try to send a real-time notification
            streamingService.streamAIResponse(conversationId, aiMessageId, '❌ Technical difficulties - please refresh and try again.', true);
          }
        }
      } catch (aiGenerationError) {
        console.error('Error in AI generation section:', aiGenerationError);
      }
    }

  } catch (error) {
    console.error('Send streaming message error:', error);
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

    const messageResult = await docClient.send(new GetCommand(messageParams));

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

    const result = await docClient.send(new UpdateCommand(updateParams));

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

    const messageResult = await docClient.send(new GetCommand(messageParams));

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

    await docClient.send(new UpdateCommand(updateParams));

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

// @route   POST /api/messages/:conversationId/typing
// @desc    Set typing indicator for a conversation
// @access  Private
router.post('/:conversationId/typing', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { isTyping = false } = req.body;
    const userId = req.user.userId;

    // Verify user has access to this conversation
    const conversationParams = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };

    const conversationResult = await docClient.send(new GetCommand(conversationParams));

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

    // Set typing status
    streamingService.setTyping(conversationId, userId, isTyping);

    res.json({
      success: true,
      isTyping,
      userId
    });

  } catch (error) {
    console.error('Set typing error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to set typing status'
    });
  }
});

module.exports = router;
