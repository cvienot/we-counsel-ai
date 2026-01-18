const { docClient, TABLES, PutCommand, GetCommand, QueryCommand, UpdateCommand } = require('../config/database');
const { randomUUID } = require('crypto');

/**
 * Exercise Templates
 * Predefined exercises that couples can do together
 */
const EXERCISE_TEMPLATES = {
  'active-listening': {
    exerciseId: 'active-listening',
    name: 'Active Listening Practice',
    description: 'Practice truly hearing each other without judgment or interruption',
    category: 'communication',
    duration: 15,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, share something on your mind for 2-3 minutes. @{partner2}, just listen without responding.',
        guidance: 'Share anything - a feeling, concern, or something you appreciate. Be honest and vulnerable.',
        prompt: '@{partner1}, what would you like to share with @{partner2}?'
      },
      {
        stepNumber: 2,
        instruction: '@{partner2}, reflect back what you heard without adding your own interpretation.',
        guidance: 'Use phrases like "I heard you say..." or "It sounds like you felt..."',
        prompt: '@{partner2}, what did you hear @{partner1} say?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner1}, confirm if @{partner2} understood you correctly.',
        guidance: 'Clarify any misunderstandings gently.',
        prompt: '@{partner1}, did @{partner2} capture what you meant to say?'
      },
      {
        stepNumber: 4,
        instruction: 'Now switch! @{partner2}, share something for 2-3 minutes. @{partner1}, just listen.',
        guidance: 'Same process - share openly while your partner listens fully.',
        prompt: '@{partner2}, what would you like to share with @{partner1}?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner1}, reflect back what you heard.',
        guidance: 'Mirror what you heard without judgment or solutions.',
        prompt: '@{partner1}, what did you hear @{partner2} say?'
      },
      {
        stepNumber: 6,
        instruction: '@{partner2}, confirm if @{partner1} understood you correctly.',
        guidance: 'Appreciate their effort to understand you.',
        prompt: '@{partner2}, did @{partner1} capture what you meant?'
      }
    ]
  },
  
  'appreciation-share': {
    exerciseId: 'appreciation-share',
    name: 'Appreciation Share',
    description: 'Share specific things you appreciate about each other',
    category: 'appreciation',
    duration: 10,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, share 2-3 specific things you appreciate about @{partner2} this week.',
        guidance: 'Be specific - not just "you\'re nice" but "I appreciated when you made dinner Thursday when I was stressed."',
        prompt: '@{partner1}, what do you appreciate about @{partner2}?'
      },
      {
        stepNumber: 2,
        instruction: '@{partner2}, receive the appreciation. Just say "thank you" - no deflecting!',
        guidance: 'Let yourself receive it fully. Notice how it feels.',
        prompt: '@{partner2}, how does it feel to hear that?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner2}, share 2-3 specific things you appreciate about @{partner1}.',
        guidance: 'Be concrete and specific about recent moments.',
        prompt: '@{partner2}, what do you appreciate about @{partner1}?'
      },
      {
        stepNumber: 4,
        instruction: '@{partner1}, receive the appreciation with a simple "thank you."',
        guidance: 'Allow yourself to feel valued.',
        prompt: '@{partner1}, how does it feel to be appreciated like this?'
      }
    ]
  },
  
  'conflict-deescalation': {
    exerciseId: 'conflict-deescalation',
    name: 'Conflict De-escalation',
    description: 'Slow down a heated moment and understand each other\'s needs',
    category: 'conflict',
    duration: 20,
    steps: [
      {
        stepNumber: 1,
        instruction: 'Both of you: Take 3 deep breaths together. Notice your body.',
        guidance: 'Pause before reacting. Create space between feeling and responding.',
        prompt: '@{partner1} and @{partner2}, what do you notice in your body right now? (tension, heat, tightness, etc.)'
      },
      {
        stepNumber: 2,
        instruction: '@{partner1}, name the feeling under the anger or frustration.',
        guidance: 'Go deeper - beneath anger is often hurt, fear, or feeling unimportant.',
        prompt: '@{partner1}, what feeling is beneath the surface? (hurt, scared, dismissed, lonely, etc.)'
      },
      {
        stepNumber: 3,
        instruction: '@{partner2}, reflect what you heard without defending yourself yet.',
        guidance: 'Just acknowledge: "I hear that you feel..."',
        prompt: '@{partner2}, what is @{partner1} really feeling underneath?'
      },
      {
        stepNumber: 4,
        instruction: '@{partner2}, now share your own feeling beneath your reaction.',
        guidance: 'Be vulnerable - what\'s the deeper feeling?',
        prompt: '@{partner2}, what are you feeling underneath your reaction?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner1}, reflect what you heard.',
        guidance: 'Show you understand their underlying feeling.',
        prompt: '@{partner1}, what is @{partner2} really feeling?'
      },
      {
        stepNumber: 6,
        instruction: 'Together: What do each of you need right now to feel safer?',
        guidance: 'Be specific - "I need to feel heard" or "I need reassurance you still care."',
        prompt: 'What specific need does each of you have right now?'
      }
    ]
  }
};

/**
 * Start a new exercise session
 */
const startExercise = async ({ coupleId, conversationId, exerciseId, partnerNames }) => {
  const template = EXERCISE_TEMPLATES[exerciseId];
  
  if (!template) {
    throw new Error(`Exercise not found: ${exerciseId}`);
  }

  // Create exercise session
  const sessionId = randomUUID();
  const session = {
    sessionId,
    coupleId,
    conversationId,
    exerciseId,
    status: 'active',
    currentStep: 1,
    progress: JSON.stringify({
      steps: template.steps.map(step => ({
        stepNumber: step.stepNumber,
        completed: false,
        response: null
      }))
    }),
    startedAt: new Date().toISOString(),
    createdAt: new Date().toISOString()
  };

  await docClient.send(new PutCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    Item: session
  }));

  // Personalize first step with partner names
  const firstStep = { ...template.steps[0] };
  if (partnerNames) {
    firstStep.instruction = firstStep.instruction
      .replace(/@{partner1}/g, partnerNames.partner1)
      .replace(/@{partner2}/g, partnerNames.partner2);
    firstStep.guidance = firstStep.guidance
      .replace(/@{partner1}/g, partnerNames.partner1)
      .replace(/@{partner2}/g, partnerNames.partner2);
    firstStep.prompt = firstStep.prompt
      .replace(/@{partner1}/g, partnerNames.partner1)
      .replace(/@{partner2}/g, partnerNames.partner2);
  }

  return {
    session,
    exercise: {
      ...template,
      currentStep: firstStep
    }
  };
};

/**
 * Progress to next step in exercise
 */
const progressExercise = async ({ sessionId, response, partnerNames }) => {
  // Get current session
  const sessionResult = await docClient.send(new GetCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    Key: { sessionId }
  }));

  if (!sessionResult.Item) {
    throw new Error('Exercise session not found');
  }

  const session = sessionResult.Item;
  const template = EXERCISE_TEMPLATES[session.exerciseId];
  const progress = JSON.parse(session.progress);

  // Update current step with response
  progress.steps[session.currentStep - 1].completed = true;
  progress.steps[session.currentStep - 1].response = response;

  // Check if we're done
  const isComplete = session.currentStep >= template.steps.length;

  if (isComplete) {
    // Mark as completed
    await docClient.send(new UpdateCommand({
      TableName: TABLES.EXERCISE_SESSIONS,
      Key: { sessionId },
      UpdateExpression: 'SET #status = :status, progress = :progress, completedAt = :completedAt',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': 'completed',
        ':progress': JSON.stringify(progress),
        ':completedAt': new Date().toISOString()
      }
    }));

    return {
      completed: true,
      session: {
        ...session,
        status: 'completed',
        progress: JSON.stringify(progress)
      }
    };
  }

  // Move to next step
  const nextStepNumber = session.currentStep + 1;
  await docClient.send(new UpdateCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    Key: { sessionId },
    UpdateExpression: 'SET currentStep = :currentStep, progress = :progress',
    ExpressionAttributeValues: {
      ':currentStep': nextStepNumber,
      ':progress': JSON.stringify(progress)
    }
  }));

  // Personalize next step
  const nextStep = { ...template.steps[nextStepNumber - 1] };
  if (partnerNames) {
    nextStep.instruction = nextStep.instruction
      .replace(/@{partner1}/g, partnerNames.partner1)
      .replace(/@{partner2}/g, partnerNames.partner2);
    nextStep.guidance = nextStep.guidance
      .replace(/@{partner1}/g, partnerNames.partner1)
      .replace(/@{partner2}/g, partnerNames.partner2);
    nextStep.prompt = nextStep.prompt
      .replace(/@{partner1}/g, partnerNames.partner1)
      .replace(/@{partner2}/g, partnerNames.partner2);
  }

  return {
    completed: false,
    session: {
      ...session,
      currentStep: nextStepNumber,
      progress: JSON.stringify(progress)
    },
    nextStep
  };
};

/**
 * Get available exercises
 */
const getExercises = async () => {
  return Object.values(EXERCISE_TEMPLATES);
};

/**
 * Get active exercise session for a conversation
 */
const getActiveSession = async ({ conversationId }) => {
  const result = await docClient.send(new QueryCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    IndexName: 'conversationId-index',
    KeyConditionExpression: 'conversationId = :conversationId',
    FilterExpression: '#status = :status',
    ExpressionAttributeNames: {
      '#status': 'status'
    },
    ExpressionAttributeValues: {
      ':conversationId': conversationId,
      ':status': 'active'
    },
    Limit: 1
  }));

  return result.Items?.[0] || null;
};

module.exports = {
  EXERCISE_TEMPLATES,
  startExercise,
  progressExercise,
  getExercises,
  getActiveSession
};
