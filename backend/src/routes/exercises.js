const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const { docClient, TABLES, GetCommand, UpdateCommand, PutCommand, QueryCommand } = require('../config/database');
const { randomUUID } = require('crypto');
const exerciseService = require('../services/exerciseService');
const { generateCoachResponse } = require('../services/aiService');
const streamingService = require('../services/streamingService');

const router = express.Router();

/**
 * Get available exercises
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const exercises = await exerciseService.getExercises();
    
    res.json({
      success: true,
      exercises
    });
  } catch (error) {
    console.error('Get exercises error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to retrieve exercises'
    });
  }
});

/**
 * Start an exercise
 */
router.post('/start', authenticateToken, async (req, res) => {
  try {
    const { conversationId, exerciseId } = req.body;

    if (!conversationId || !exerciseId) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'conversationId and exerciseId are required'
      });
    }

    // Verify conversation access
    const conversationResult = await docClient.send(new GetCommand({
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    }));

    if (!conversationResult.Item || conversationResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid conversation access'
      });
    }

    // Get partner names
    let partnerNames = null;
    try {
      const coupleResult = await docClient.send(new GetCommand({
        TableName: TABLES.COUPLES,
        Key: { coupleId: req.user.coupleId }
      }));

      console.log('📝 Starting exercise - Couple result:', coupleResult.Item);

      if (coupleResult.Item) {
        const [user1Result, user2Result] = await Promise.all([
          docClient.send(new GetCommand({
            TableName: TABLES.USERS,
            Key: { userId: coupleResult.Item.user1Id }
          })),
          docClient.send(new GetCommand({
            TableName: TABLES.USERS,
            Key: { userId: coupleResult.Item.user2Id }
          }))
        ]);

        console.log('📝 User1:', user1Result.Item);
        console.log('📝 User2:', user2Result.Item);

        if (user1Result.Item && user2Result.Item) {
          partnerNames = {
            partner1: user1Result.Item.firstName || 'Partner 1',
            partner2: user2Result.Item.firstName || 'Partner 2'
          };
          console.log('📝 Partner names:', partnerNames);
        }
      }
    } catch (error) {
      console.error('Error fetching partner names:', error);
    }

    console.log('📝 Final partner names being sent:', partnerNames);

    // Check if there's an active session for this conversation and exercise
    const existingSession = await exerciseService.getActiveSession({ conversationId });
    
    if (existingSession && existingSession.exerciseId === exerciseId) {
      // Resume existing session
      console.log('📝 Resuming existing session:', existingSession.sessionId);
      
      // Get the current step with personalized names
      const template = exerciseService.getExerciseTemplate(exerciseId);
      const currentStepNumber = existingSession.currentStep;
      const currentStep = { ...template.steps[currentStepNumber - 1] };
      
      if (partnerNames) {
        currentStep.instruction = currentStep.instruction
          .replace(/@{partner1}/g, partnerNames.partner1)
          .replace(/@{partner2}/g, partnerNames.partner2);
        currentStep.guidance = currentStep.guidance
          .replace(/@{partner1}/g, partnerNames.partner1)
          .replace(/@{partner2}/g, partnerNames.partner2);
        currentStep.prompt = currentStep.prompt
          .replace(/@{partner1}/g, partnerNames.partner1)
          .replace(/@{partner2}/g, partnerNames.partner2);
      }
      
      return res.json({
        success: true,
        session: existingSession,
        exercise: {
          ...template,
          currentStep
        }
      });
    }

    // Start a new exercise
    const result = await exerciseService.startExercise({
      coupleId: req.user.coupleId,
      conversationId,
      exerciseId,
      partnerNames
    });

    res.json({
      success: true,
      session: result.session,
      exercise: result.exercise
    });
  } catch (error) {
    console.error('Start exercise error:', error);
    res.status(500).json({
      error: 'Server error',
      message: error.message || 'Failed to start exercise'
    });
  }
});

/**
 * Progress exercise to next step
 */
router.post('/:sessionId/progress', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { response } = req.body;

    if (!response || response.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Response is required'
      });
    }

    // Verify session belongs to user's couple
    const sessionResult = await docClient.send(new GetCommand({
      TableName: TABLES.EXERCISE_SESSIONS,
      Key: { sessionId }
    }));

    if (!sessionResult.Item || sessionResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid session access'
      });
    }

    // Get partner names for personalization
    let partnerNames = null;
    try {
      const coupleResult = await docClient.send(new GetCommand({
        TableName: TABLES.COUPLES,
        Key: { coupleId: req.user.coupleId }
      }));

      if (coupleResult.Item) {
        const [user1Result, user2Result] = await Promise.all([
          docClient.send(new GetCommand({
            TableName: TABLES.USERS,
            Key: { userId: coupleResult.Item.user1Id }
          })),
          docClient.send(new GetCommand({
            TableName: TABLES.USERS,
            Key: { userId: coupleResult.Item.user2Id }
          }))
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
    }

    // Progress the exercise
    const result = await exerciseService.progressExercise({
      sessionId,
      response,
      partnerNames
    });

    // Notify partner via SSE that the exercise has progressed
    try {
      const coupleResult2 = await docClient.send(new GetCommand({
        TableName: TABLES.COUPLES,
        Key: { coupleId: req.user.coupleId }
      }));
      if (coupleResult2.Item) {
        const partnerId = coupleResult2.Item.user1Id === req.user.userId
          ? coupleResult2.Item.user2Id
          : coupleResult2.Item.user1Id;
        streamingService.sendToUser(partnerId, {
          type: 'exerciseProgress',
          sessionId,
          currentStep: result.session.currentStep,
          completed: result.completed,
          timestamp: Date.now()
        });
      }
    } catch (notifyError) {
      console.error('Error notifying partner of exercise progress:', notifyError);
    }

    res.json({
      success: true,
      completed: result.completed,
      session: result.session,
      nextStep: result.nextStep
    });
  } catch (error) {
    console.error('Progress exercise error:', error);
    res.status(500).json({
      error: 'Server error',
      message: error.message || 'Failed to progress exercise'
    });
  }
});

/**
 * Get exercise summary (after completion)
 */
router.get('/:sessionId/summary', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;

    const sessionResult = await docClient.send(new GetCommand({
      TableName: TABLES.EXERCISE_SESSIONS,
      Key: { sessionId }
    }));

    if (!sessionResult.Item || sessionResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid session access'
      });
    }

    const session = sessionResult.Item;

    if (session.status !== 'completed') {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Exercise not yet completed'
      });
    }

    // If summary already exists, return it
    if (session.summary) {
      return res.json({
        success: true,
        summary: session.summary
      });
    }

    // Generate summary using AI
    const template = exerciseService.EXERCISE_TEMPLATES[session.exerciseId];
    const progress = JSON.parse(session.progress);
    
    const summaryPrompt = `Generate a brief, encouraging summary of this completed exercise:

Exercise: ${template.name}
Responses:
${progress.steps.map((step, i) => `Step ${i + 1}: ${step.response || 'No response'}`).join('\n')}

Create a 2-3 paragraph summary that:
1. Acknowledges what they practiced
2. Highlights key insights or progress
3. Encourages them to keep using this skill

Keep it positive, specific, and actionable.`;

    let summary = '';
    
    await generateCoachResponse({
      messages: [{ senderType: 'user', content: summaryPrompt }],
      context: 'Exercise summary generation',
      onChunk: (chunk) => { summary += chunk; },
      onComplete: () => {},
      onError: (error) => { console.error('Summary generation error:', error); }
    });

    // Conditional write: only save if no summary exists yet (race-safe)
    try {
      await docClient.send(new UpdateCommand({
        TableName: TABLES.EXERCISE_SESSIONS,
        Key: { sessionId },
        UpdateExpression: 'SET summary = :summary',
        ConditionExpression: 'attribute_not_exists(summary)',
        ExpressionAttributeValues: {
          ':summary': summary
        }
      }));

      // We won the race — post the conversation message
      if (session.conversationId) {
        const messageId = randomUUID();
        const messageData = {
          messageId,
          conversationId: session.conversationId,
          senderId: 'ai-coach',
          senderName: 'AI Coach',
          senderType: 'ai',
          content: `📝 **Exercise Completed: ${template.name}**\n\n${summary}`,
          recipientType: 'both',
          timestamp: Date.now(),
          createdAt: new Date().toISOString()
        };
        await docClient.send(new PutCommand({
          TableName: TABLES.MESSAGES,
          Item: messageData
        }));
        streamingService.sendMessageNotification(session.conversationId, 'ai-coach', messageData);
        console.log('✅ Exercise summary posted to conversation:', session.conversationId);
      }
    } catch (condError) {
      if (condError.name === 'ConditionalCheckFailedException') {
        // Another request already saved a summary — use that one instead
        console.log('ℹ️ Summary already saved by another request, returning existing');
        const existing = await docClient.send(new GetCommand({
          TableName: TABLES.EXERCISE_SESSIONS,
          Key: { sessionId }
        }));
        return res.json({ success: true, summary: existing.Item.summary });
      }
      throw condError;
    }

    res.json({
      success: true,
      summary
    });
  } catch (error) {
    console.error('Get summary error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to generate summary'
    });
  }
});

/**
 * Get exercise history for the couple
 */
router.get('/history', authenticateToken, async (req, res) => {
  try {
    const coupleId = req.user.coupleId;
    if (!coupleId) {
      return res.status(400).json({ error: 'No couple linked' });
    }

    const result = await docClient.send(new QueryCommand({
      TableName: TABLES.EXERCISE_SESSIONS,
      IndexName: 'coupleId-index',
      KeyConditionExpression: 'coupleId = :coupleId',
      ExpressionAttributeValues: {
        ':coupleId': coupleId
      },
      ScanIndexForward: false // Most recent first
    }));

    const sessions = (result.Items || []).map(session => {
      const template = exerciseService.EXERCISE_TEMPLATES[session.exerciseId];
      return {
        sessionId: session.sessionId,
        exerciseId: session.exerciseId,
        exerciseName: template?.name || session.exerciseId,
        status: session.status,
        currentStep: session.currentStep,
        totalSteps: template?.steps?.length || 0,
        summary: session.summary || null,
        startedAt: session.startedAt || session.createdAt,
        completedAt: session.completedAt || null
      };
    });

    res.json({ success: true, sessions });
  } catch (error) {
    console.error('Get exercise history error:', error);
    res.status(500).json({ error: 'Server error', message: 'Failed to get exercise history' });
  }
});

/**
 * Get active session for a conversation
 */
router.get('/active/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;

    // Verify conversation access
    const conversationResult = await docClient.send(new GetCommand({
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    }));

    if (!conversationResult.Item || conversationResult.Item.coupleId !== req.user.coupleId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid conversation access'
      });
    }

    const session = await exerciseService.getActiveSession({ conversationId });

    if (!session) {
      return res.json({
        success: true,
        session: null
      });
    }

    // Get current step details with personalized partner names
    const template = exerciseService.EXERCISE_TEMPLATES[session.exerciseId];
    const currentStep = { ...template.steps[session.currentStep - 1] };

    // Personalize partner names
    try {
      const coupleResult = await docClient.send(new GetCommand({
        TableName: TABLES.COUPLES,
        Key: { coupleId: conversationResult.Item.coupleId }
      }));
      if (coupleResult.Item) {
        const [user1Result, user2Result] = await Promise.all([
          docClient.send(new GetCommand({ TableName: TABLES.USERS, Key: { userId: coupleResult.Item.user1Id } })),
          docClient.send(new GetCommand({ TableName: TABLES.USERS, Key: { userId: coupleResult.Item.user2Id } }))
        ]);
        if (user1Result.Item && user2Result.Item) {
          const p1 = user1Result.Item.firstName || 'Partner 1';
          const p2 = user2Result.Item.firstName || 'Partner 2';
          currentStep.instruction = currentStep.instruction.replace(/@{partner1}/g, p1).replace(/@{partner2}/g, p2);
          currentStep.guidance = currentStep.guidance.replace(/@{partner1}/g, p1).replace(/@{partner2}/g, p2);
          currentStep.prompt = currentStep.prompt.replace(/@{partner1}/g, p1).replace(/@{partner2}/g, p2);
        }
      }
    } catch (err) {
      console.error('Error personalizing active session step:', err);
    }

    res.json({
      success: true,
      session,
      exercise: {
        ...template,
        currentStep
      }
    });
  } catch (error) {
    console.error('Get active session error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to retrieve active session'
    });
  }
});

module.exports = router;
