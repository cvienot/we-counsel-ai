const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const { docClient, TABLES, GetCommand } = require('../config/database');
const exerciseService = require('../services/exerciseService');
const { generateCoachResponse } = require('../services/aiService');

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

    // Save summary
    await docClient.send(new UpdateCommand({
      TableName: TABLES.EXERCISE_SESSIONS,
      Key: { sessionId },
      UpdateExpression: 'SET summary = :summary',
      ExpressionAttributeValues: {
        ':summary': summary
      }
    }));

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

    // Get current step details
    const template = exerciseService.EXERCISE_TEMPLATES[session.exerciseId];
    const currentStep = template.steps[session.currentStep - 1];

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
