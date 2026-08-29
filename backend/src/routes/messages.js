const express = require('express');
const { docClient, TABLES, PutCommand, QueryCommand, GetCommand, UpdateCommand } = require('../config/database');
const { authenticateToken } = require('../middleware/authMiddleware');
const { checkAIMessageLimit } = require('../middleware/subscriptionMiddleware');
const { aiService } = require('../services');
const { generateCoachResponse, summarizeConversation } = aiService;
const subscriptionService = require('../services/subscriptionService');
const streamingService = require('../services/streamingService');
const exerciseService = require('../services/exerciseService');
const { randomUUID } = require('crypto');

const router = express.Router();
const RECENT_WINDOW = 15;
const SUMMARY_BATCH_SIZE = 10;

// Helper function to get user's full name with fallback
const getUserFullName = (user) => {
  const firstName = user.firstName || 'User';
  const lastName = user.lastName || '';
  return `${firstName} ${lastName}`.trim();
};

const deduplicateMessages = (messages) => {
  const seen = new Set();

  return messages.filter((message) => {
    const key = message.messageId || `${message.senderId}:${message.timestamp}:${message.content}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

const getAllConversationMessages = async (conversationId) => {
  const messages = [];
  let lastEvaluatedKey;

  do {
    const result = await docClient.send(new QueryCommand({
      TableName: TABLES.MESSAGES,
      IndexName: 'conversationId-timestamp-index',
      KeyConditionExpression: 'conversationId = :conversationId',
      ExpressionAttributeValues: {
        ':conversationId': conversationId
      },
      ScanIndexForward: true,
      ExclusiveStartKey: lastEvaluatedKey
    }));

    messages.push(...(result.Items || []));
    lastEvaluatedKey = result.LastEvaluatedKey;
  } while (lastEvaluatedKey);

  return deduplicateMessages(messages);
};

// Keep a small verbatim window and compact only messages that have fallen out of it.
const buildConversationContext = async (conversation, recentMessages) => {
  const messageCount = conversation.messageCount || 0;
  let contextMessages = deduplicateMessages(recentMessages);
  let contextPrefix = '';

  if (messageCount > RECENT_WINDOW) {
    const summarizedCount = conversation.summarizedMessageCount || 0;
    const eligibleMessageCount = Math.max(0, messageCount - RECENT_WINDOW);
    const unsummarizedEligibleCount = Math.max(0, eligibleMessageCount - summarizedCount);

    if (unsummarizedEligibleCount >= SUMMARY_BATCH_SIZE) {
      console.log(`📊 Updating memory for conversation ${conversation.conversationId} (${unsummarizedEligibleCount} messages ready to compact)`);
      
      try {
        const allMessages = await getAllConversationMessages(conversation.conversationId);
        const currentRecentMessages = allMessages.slice(-RECENT_WINDOW);
        const currentEligibleCount = Math.max(0, allMessages.length - currentRecentMessages.length);
        const startIndex = Math.min(summarizedCount, currentEligibleCount);
        const messagesToSummarize = allMessages.slice(startIndex, currentEligibleCount);

        if (messagesToSummarize.length < SUMMARY_BATCH_SIZE) {
          if (conversation.summary) {
            contextPrefix = `**Session History Summary:**\n${conversation.summary}\n\n**Recent conversation:**\n`;
          }
          return { messages: contextMessages, contextPrefix, hasSummary: !!contextPrefix };
        }

        const { summary, usage } = await summarizeConversation({
          messages: messagesToSummarize,
          conversationTitle: conversation.title,
          previousSummary: conversation.summary
        });

        const updateParams = {
          TableName: TABLES.CONVERSATIONS,
          Key: { conversationId: conversation.conversationId },
          UpdateExpression: 'SET summary = :summary, lastSummarizedAt = :timestamp, summarizedMessageCount = :count, lastSummaryUsage = :usage',
          ExpressionAttributeValues: {
            ':summary': summary,
            ':timestamp': new Date().toISOString(),
            ':count': startIndex + messagesToSummarize.length,
            ':usage': usage || null
          }
        };

        await docClient.send(new UpdateCommand(updateParams));
        
        contextMessages = currentRecentMessages;
        contextPrefix = `**Session History Summary:**\n${summary}\n\n**Recent conversation:**\n`;
        console.log(`✅ Conversation memory updated with ${messagesToSummarize.length} messages`);
      } catch (error) {
        console.error(`❌ Error updating conversation memory:`, error);
        console.warn('⚠️ Continuing without a memory update for this response');
        contextPrefix = '';
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
          Limit: RECENT_WINDOW
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

        // Fetch both partner names from the couple
        let partnerNames = null;
        let waitingForPartner = !req.user.partnerId;
        try {
          const coupleParams = {
            TableName: TABLES.COUPLES,
            Key: { coupleId: req.user.coupleId }
          };
          const coupleResult = await docClient.send(new GetCommand(coupleParams));
          
          if (coupleResult.Item) {
            const couple = coupleResult.Item;
            const p1Id = couple.partner1Id || couple.user1Id;
            const p2Id = couple.partner2Id || couple.user2Id;

            waitingForPartner = couple.status === 'pending_invitee' || !p1Id || !p2Id;

            if (p1Id && p2Id) {
              const [user1Result, user2Result] = await Promise.all([
                docClient.send(new GetCommand({ TableName: TABLES.USERS, Key: { userId: p1Id } })),
                docClient.send(new GetCommand({ TableName: TABLES.USERS, Key: { userId: p2Id } }))
              ]);
              
              if (user1Result.Item && user2Result.Item) {
                partnerNames = {
                  partner1: user1Result.Item.firstName || 'Partner 1',
                  partner2: user2Result.Item.firstName || 'Partner 2'
                };
              }
            }
          }
        } catch (error) {
          console.error('Error fetching partner names:', error);
          // Continue without names if fetch fails
        }

        const waitingContext = waitingForPartner
          ? `\nOnly ${req.user.firstName || 'the current user'} is present in this conversation. Their invited partner has not accepted the invitation yet, so respond only to the present user and help them prepare their own thoughts.`
          : '';
        const contextString = `${contextPrefix}Conversation: ${conversation.title}${conversation.topic ? `, Topic: ${conversation.topic}` : ''}${waitingContext}`;

        const aiMessageId = randomUUID();
        let aiResponseContent = '';

        // Fetch recent exercise history for the couple
        let recentExercises = [];
        try {
          if (req.user.coupleId) {
            const exerciseResult = await docClient.send(new QueryCommand({
              TableName: TABLES.EXERCISE_SESSIONS,
              IndexName: 'coupleId-index',
              KeyConditionExpression: 'coupleId = :coupleId',
              ExpressionAttributeValues: {
                ':coupleId': req.user.coupleId
              },
              ScanIndexForward: false,
              Limit: 3
            }));
            recentExercises = (exerciseResult.Items || []).map(s => {
              const template = exerciseService.EXERCISE_TEMPLATES[s.exerciseId];
              return {
                exerciseId: s.exerciseId,
                exerciseName: template?.name || s.exerciseId,
                status: s.status,
                startedAt: s.startedAt || s.createdAt,
                completedAt: s.completedAt || null
              };
            });
          }
        } catch (err) {
          console.error('Error fetching exercise history for AI context:', err);
        }

        // Stream AI response with proper error handling
        console.log('🤖 Starting AI response generation for conversation:', conversationId);
        try {
          await generateCoachResponse({
            // The GSI may or may not have caught up with the newly saved message.
            // Deduplication keeps the prompt stable in both cases.
            messages: deduplicateMessages([...contextMessages, messageData]),
            context: contextString,
            partnerNames,
            waitingForPartner,
            recentExercises,
            onChunk: async (chunk) => {
              aiResponseContent += chunk;
              await streamingService.streamAIResponse(conversationId, aiMessageId, chunk, false);
            },
            onComplete: async (fullResponse, usage) => {
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
                createdAt: new Date().toISOString(),
                ...(usage ? { aiUsage: usage } : {})
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
