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
  },

  'emotional-checkin': {
    exerciseId: 'emotional-checkin',
    name: 'Emotional Check-in',
    description: 'Share how you\'re really feeling right now — not about the relationship, just you',
    category: 'connection',
    duration: 10,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, take a moment and check in with yourself. How are you feeling right now?',
        guidance: 'This isn\'t about the relationship — it\'s about YOU. Tired? Anxious? Excited? Overwhelmed? Be honest.',
        prompt: '@{partner1}, how are you really feeling today? (not "fine" — what\'s actually going on inside?)'
      },
      {
        stepNumber: 2,
        instruction: '@{partner2}, just listen and reflect back what you heard. No fixing, no advice.',
        guidance: 'Show your partner they\'re heard. "It sounds like you\'re feeling..." is perfect.',
        prompt: '@{partner2}, what did you hear? How is @{partner1} feeling?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner2}, your turn. How are you really feeling today?',
        guidance: 'Same thing — be honest about where you are emotionally right now.',
        prompt: '@{partner2}, how are you really feeling today?'
      },
      {
        stepNumber: 4,
        instruction: '@{partner1}, reflect back what you heard from @{partner2}.',
        guidance: 'Mirror their feelings without trying to fix anything.',
        prompt: '@{partner1}, what did you hear? How is @{partner2} feeling?'
      }
    ]
  },

  'empathy-swap': {
    exerciseId: 'empathy-swap',
    name: 'Empathy Swap',
    description: 'Try to see a recent situation through your partner\'s eyes',
    category: 'empathy',
    duration: 15,
    steps: [
      {
        stepNumber: 1,
        instruction: 'Think of a recent disagreement or tense moment between you two.',
        guidance: 'Pick something recent but not too raw — you need some emotional distance to do this well.',
        prompt: '@{partner1}, briefly describe the situation you\'re thinking of. What happened?'
      },
      {
        stepNumber: 2,
        instruction: '@{partner1}, try to describe what YOU think @{partner2} was feeling and thinking during that moment.',
        guidance: 'Start with "I think you felt..." or "I imagine you were thinking..." Be genuinely curious, not sarcastic.',
        prompt: '@{partner1}, what do you think @{partner2} was feeling and why?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner2}, how accurate was that? Correct or add to what @{partner1} said.',
        guidance: 'Acknowledge what they got right first, then gently clarify what they missed.',
        prompt: '@{partner2}, what did @{partner1} get right? What did they miss?'
      },
      {
        stepNumber: 4,
        instruction: '@{partner2}, now YOU describe what you think @{partner1} was feeling during that same moment.',
        guidance: 'Try to truly step into their shoes. What was driving their behavior?',
        prompt: '@{partner2}, what do you think @{partner1} was feeling and why?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner1}, how accurate was that? Share what they got right and what they missed.',
        guidance: 'Start with appreciation for the effort, then clarify.',
        prompt: '@{partner1}, what did @{partner2} get right? What did they miss?'
      },
      {
        stepNumber: 6,
        instruction: 'Together: What surprised you about how your partner saw the situation?',
        guidance: 'This is the breakthrough moment — often we discover our partner\'s experience was completely different from what we assumed.',
        prompt: 'What was the biggest surprise or insight from seeing through each other\'s eyes?'
      }
    ]
  },

  'repair-conversation': {
    exerciseId: 'repair-conversation',
    name: 'Repair Conversation',
    description: 'Reconnect after a conflict with structured accountability and care',
    category: 'repair',
    duration: 15,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, acknowledge what happened without blame. Just describe the event factually.',
        guidance: 'Stick to facts: "Yesterday when we were discussing X, things got heated." No "you always" or "you never."',
        prompt: '@{partner1}, what happened? (just the facts, no blame)'
      },
      {
        stepNumber: 2,
        instruction: '@{partner1}, share how YOU felt during and after the conflict using "I" statements.',
        guidance: '"I felt hurt when..." not "You made me feel..." Own your emotions.',
        prompt: '@{partner1}, how did you feel during and after? (use "I felt...")'
      },
      {
        stepNumber: 3,
        instruction: '@{partner2}, share your own feelings about what happened, also using "I" statements.',
        guidance: 'Don\'t respond to what they said — share YOUR experience independently.',
        prompt: '@{partner2}, how did you feel during and after? (use "I felt...")'
      },
      {
        stepNumber: 4,
        instruction: 'Each of you: Take responsibility for YOUR part. What could you have done differently?',
        guidance: 'This isn\'t about who was "more wrong." Even a small acknowledgment matters: "I could have paused before reacting."',
        prompt: '@{partner1}, what\'s one thing you could have done differently?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner2}, what\'s one thing you could have done differently?',
        guidance: 'Match your partner\'s vulnerability. This is mutual accountability.',
        prompt: '@{partner2}, what\'s one thing you could have done differently?'
      },
      {
        stepNumber: 6,
        instruction: 'Together: What do each of you need to move forward?',
        guidance: 'Be specific: "I need reassurance that..." or "I need us to agree that next time we\'ll..."',
        prompt: 'What does each of you need from the other to feel reconnected?'
      }
    ]
  },

  'needs-and-boundaries': {
    exerciseId: 'needs-and-boundaries',
    name: 'Needs & Boundaries',
    description: 'Express one unmet need and one boundary clearly and lovingly',
    category: 'communication',
    duration: 15,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, share one need that isn\'t being fully met in the relationship right now.',
        guidance: 'Frame it positively: "I need more quality time" rather than "You never spend time with me." Be specific.',
        prompt: '@{partner1}, what is one need you have that isn\'t being fully met?'
      },
      {
        stepNumber: 2,
        instruction: '@{partner2}, reflect back what you heard without defending or explaining.',
        guidance: 'Just mirror: "I hear that you need..." Show you understand before responding.',
        prompt: '@{partner2}, what did you hear @{partner1} needs?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner1}, share one boundary that\'s important to you.',
        guidance: 'A boundary is about YOUR limits, not controlling the other: "I need you to not bring up X during arguments" or "I need alone time after work before talking about heavy topics."',
        prompt: '@{partner1}, what is one boundary you need respected?'
      },
      {
        stepNumber: 4,
        instruction: '@{partner2}, now share YOUR unmet need.',
        guidance: 'Same approach — positive framing, specific, about what you need (not what they\'re doing wrong).',
        prompt: '@{partner2}, what is one need you have that isn\'t being fully met?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner1}, reflect back what you heard.',
        guidance: 'Mirror their need without judgment.',
        prompt: '@{partner1}, what did you hear @{partner2} needs?'
      },
      {
        stepNumber: 6,
        instruction: '@{partner2}, share one boundary that\'s important to you.',
        guidance: 'Be clear and kind. Boundaries are healthy and necessary.',
        prompt: '@{partner2}, what is one boundary you need respected?'
      }
    ]
  },

  'rose-thorn-bud': {
    exerciseId: 'rose-thorn-bud',
    name: 'Rose, Thorn & Bud',
    description: 'Share a highlight, a challenge, and something you\'re looking forward to',
    category: 'connection',
    duration: 10,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, share your ROSE 🌹 — something good that happened recently.',
        guidance: 'It can be big or small. "I had a great lunch with a friend" counts just as much as a promotion.',
        prompt: '@{partner1}, what\'s your rose? (a recent highlight or positive moment)'
      },
      {
        stepNumber: 2,
        instruction: '@{partner1}, share your THORN 🥀 — something that was difficult or challenging.',
        guidance: 'Be honest about what\'s weighing on you. This isn\'t about blame — just what\'s been hard.',
        prompt: '@{partner1}, what\'s your thorn? (a recent challenge or difficulty)'
      },
      {
        stepNumber: 3,
        instruction: '@{partner1}, share your BUD 🌱 — something you\'re looking forward to.',
        guidance: 'An upcoming event, a goal, even a small pleasure you\'re anticipating.',
        prompt: '@{partner1}, what\'s your bud? (something you\'re looking forward to)'
      },
      {
        stepNumber: 4,
        instruction: '@{partner2}, share your ROSE 🌹 — a recent highlight.',
        guidance: 'Your turn to share something positive from your week.',
        prompt: '@{partner2}, what\'s your rose?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner2}, share your THORN 🥀 — something difficult.',
        guidance: 'What\'s been weighing on you recently?',
        prompt: '@{partner2}, what\'s your thorn?'
      },
      {
        stepNumber: 6,
        instruction: '@{partner2}, share your BUD 🌱 — something you\'re looking forward to.',
        guidance: 'End on a hopeful note — what\'s ahead that excites you?',
        prompt: '@{partner2}, what\'s your bud?'
      }
    ]
  },

  'dream-sharing': {
    exerciseId: 'dream-sharing',
    name: 'Dream Sharing',
    description: 'Share a personal dream or goal while your partner listens with curiosity',
    category: 'connection',
    duration: 15,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, share a personal dream, goal, or aspiration — big or small.',
        guidance: 'This could be a career goal, a travel dream, something you want to learn, or a way you want to grow. No dream is too silly.',
        prompt: '@{partner1}, what is a dream or goal you have for yourself?'
      },
      {
        stepNumber: 2,
        instruction: '@{partner2}, your ONLY job: ask curious, supportive questions. No fixing, no "but how would we..."',
        guidance: 'Ask things like: "What excites you most about that?" or "When did you first start dreaming about this?" — pure curiosity.',
        prompt: '@{partner2}, what curious questions do you have about @{partner1}\'s dream?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner1}, answer their questions and share what it would mean to you to achieve this dream.',
        guidance: 'Let yourself get excited. This is a safe space to dream big.',
        prompt: '@{partner1}, what would it mean to you to make this dream happen?'
      },
      {
        stepNumber: 4,
        instruction: '@{partner2}, now share YOUR dream or goal.',
        guidance: 'Same rules — share openly. Your partner will be curious, not critical.',
        prompt: '@{partner2}, what is a dream or goal you have for yourself?'
      },
      {
        stepNumber: 5,
        instruction: '@{partner1}, ask curious, supportive questions about @{partner2}\'s dream.',
        guidance: 'Be genuinely interested. Ask "tell me more" questions.',
        prompt: '@{partner1}, what curious questions do you have about @{partner2}\'s dream?'
      },
      {
        stepNumber: 6,
        instruction: '@{partner2}, share what it would mean to you.',
        guidance: 'Let yourself be vulnerable about what this dream represents for you.',
        prompt: '@{partner2}, what would it mean to you to make this dream happen?'
      }
    ]
  },

  'gratitude-letter': {
    exerciseId: 'gratitude-letter',
    name: 'Gratitude Letter',
    description: 'Write a short gratitude message to your partner about a specific moment',
    category: 'appreciation',
    duration: 10,
    steps: [
      {
        stepNumber: 1,
        instruction: '@{partner1}, think of a specific moment recently when @{partner2} made you feel loved, supported, or happy.',
        guidance: 'Pick ONE specific moment, not a general quality. "Last Tuesday when you brought me coffee because you noticed I was stressed" is perfect.',
        prompt: '@{partner1}, write a short gratitude message to @{partner2} about a specific moment. (3-4 sentences)'
      },
      {
        stepNumber: 2,
        instruction: '@{partner2}, receive this message. How does it feel to read it?',
        guidance: 'Don\'t deflect with "oh it was nothing." Let yourself feel appreciated.',
        prompt: '@{partner2}, how does it feel to receive this gratitude?'
      },
      {
        stepNumber: 3,
        instruction: '@{partner2}, write YOUR gratitude message to @{partner1} about a specific moment.',
        guidance: 'Same approach — specific, recent, heartfelt. What moment made you grateful for your partner?',
        prompt: '@{partner2}, write a short gratitude message to @{partner1} about a specific moment. (3-4 sentences)'
      },
      {
        stepNumber: 4,
        instruction: '@{partner1}, receive this message. Let it land.',
        guidance: 'Notice what you feel. These moments matter more than we realize.',
        prompt: '@{partner1}, how does it feel to receive this gratitude?'
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
  console.log('📝 Personalizing first step');
  console.log('  Partner names:', partnerNames);
  console.log('  Before replacement:', firstStep);
  
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
  
  console.log('  After replacement:', firstStep);

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
 * Get active or recently completed exercise session for a conversation
 */
const getActiveSession = async ({ conversationId }) => {
  // First try active sessions
  // Note: Do NOT use Limit with FilterExpression – DynamoDB applies Limit
  // before filtering, so a Limit of 1 may scan a non-active item and return
  // zero results even when an active session exists.
  const activeResult = await docClient.send(new QueryCommand({
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
    }
  }));

  if (activeResult.Items?.length > 0) {
    return activeResult.Items[0];
  }

  // If no active session, return the most recently completed one
  const completedResult = await docClient.send(new QueryCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    IndexName: 'conversationId-index',
    KeyConditionExpression: 'conversationId = :conversationId',
    FilterExpression: '#status = :status',
    ExpressionAttributeNames: {
      '#status': 'status'
    },
    ExpressionAttributeValues: {
      ':conversationId': conversationId,
      ':status': 'completed'
    },
    ScanIndexForward: false,
    Limit: 1
  }));

  return completedResult.Items?.[0] || null;
};

const getCompletedSession = async ({ conversationId, exerciseId }) => {
  const result = await docClient.send(new QueryCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    IndexName: 'conversationId-index',
    KeyConditionExpression: 'conversationId = :conversationId',
    FilterExpression: '#status = :status AND #exerciseId = :exerciseId',
    ExpressionAttributeNames: {
      '#status': 'status',
      '#exerciseId': 'exerciseId'
    },
    ExpressionAttributeValues: {
      ':conversationId': conversationId,
      ':exerciseId': exerciseId,
      ':status': 'completed'
    }
  }));

  const sessions = result.Items || [];
  sessions.sort((a, b) => {
    const aTime = a.completedAt || a.createdAt || a.startedAt || '';
    const bTime = b.completedAt || b.createdAt || b.startedAt || '';
    return bTime.localeCompare(aTime);
  });

  return sessions[0] || null;
};

module.exports = {
  EXERCISE_TEMPLATES,
  getExerciseTemplate: (exerciseId) => EXERCISE_TEMPLATES[exerciseId],
  startExercise,
  progressExercise,
  getExercises,
  getActiveSession,
  getCompletedSession
};
