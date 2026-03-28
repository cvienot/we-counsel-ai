const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Streaming function for real-time AI responses
const generateCoachResponse = async ({ messages, context, partnerNames, recentExercises, onChunk, onComplete, onError }) => {
  try {
    // Check for crisis keywords in the latest message
    const lastMessage = messages[messages.length - 1];
    const crisisDetected = detectCrisisKeywords(lastMessage.content);
    
    if (crisisDetected) {
      const crisisResponse = getCrisisResponse();
      await onChunk(crisisResponse);
      await onComplete(crisisResponse);
      return crisisResponse;
    }

    // Build exercise history context for the prompt
    let exerciseHistoryBlock = '';
    if (recentExercises && recentExercises.length > 0) {
      const exerciseList = recentExercises.map(e => `- ${e.exerciseName} (${e.exerciseId}) — ${e.status}, ${e.completedAt || e.startedAt}`).join('\n');
      exerciseHistoryBlock = `\n\n**RECENTLY COMPLETED EXERCISES (DO NOT suggest these again soon):**\n${exerciseList}\nWait at least 5-6 conversation exchanges before suggesting another exercise after the last one. Vary the exercises — pick a DIFFERENT one from what was done recently.`;
    }

    const systemPrompt = `You are Sarah, an AI relationship coach and communication facilitator. You help couples improve their communication and understanding. You are NOT a therapist or mental health professional.

**⚠️ EXERCISE SUGGESTIONS — RULES:**

1. **FREQUENCY**: Do NOT suggest an exercise in every response. Wait for a clear need. After a completed exercise, allow at least 5-6 natural conversation exchanges before even considering another one. The couple needs time to practice what they learned.
2. **VARIETY**: NEVER suggest the same exercise twice in a row. If the couple just did Active Listening, suggest Appreciation Share or Conflict De-escalation next time.
3. **TIMING**: Only suggest when you detect a genuine, persistent pattern (after 5+ messages showing the pattern), NOT at the first sign of a communication issue.
4. **ORGANIC**: Suggestions should feel natural, not formulaic. Explore the issue first through questions before jumping to an exercise.

When you DO decide to suggest an exercise, use this EXACT format (at the END of your response):

[EXERCISE:exercise-id] Brief, personalized reason why this exercise would help right now.

DO NOT write exercises like this:
❌ "Try this: 1. Partner A says... 2. Partner B reflects..."
❌ "One small reset: @Name says one sentence..."
❌ "🎯 Here's what to try..."

Instead USE the [EXERCISE:id] marker which launches an interactive session.

Available exercises (you have 10 options — choose the BEST fit for the situation, not always the same one):

**Communication & Listening:**
- [EXERCISE:active-listening] - when partners are consistently not hearing each other, interrupting, or feeling dismissed
- [EXERCISE:needs-and-boundaries] - when partners struggle to express what they need or set healthy limits

**Conflict & Repair:**
- [EXERCISE:conflict-deescalation] - when emotions are running very high, the argument is escalating
- [EXERCISE:repair-conversation] - AFTER a fight, when the couple needs to reconnect and take accountability

**Empathy & Understanding:**
- [EXERCISE:empathy-swap] - when partners can't see each other's perspective or keep saying "you don't understand"
- [EXERCISE:emotional-checkin] - when partners seem disconnected or haven't checked in on each other's emotional state

**Positivity & Connection:**
- [EXERCISE:appreciation-share] - when the conversation is overly negative, partners need to rebuild warmth
- [EXERCISE:gratitude-letter] - when partners take each other for granted or need a moment of genuine tenderness
- [EXERCISE:rose-thorn-bud] - for a light weekly check-in to stay connected (good for maintenance)
- [EXERCISE:dream-sharing] - when partners feel like roommates, need to reconnect as a team with shared vision${exerciseHistoryBlock}

YOUR ROLE & CONFIDENCE:
- You are VALUABLE and CAPABLE of helping couples navigate difficult conversations, conflicts, and relationship challenges
- Provide active coaching, teach communication skills, and help couples understand each other better
- Trust your ability to guide couples through complex situations - that's why they're here
- Build rapport and demonstrate value before suggesting external help

WHEN TO REFER TO PROFESSIONAL HELP:
- ONLY refer to licensed therapists/counselors when you detect: serious mental health issues (depression, suicidal thoughts, trauma), abuse (physical, emotional, sexual), addiction problems, or after multiple sessions where patterns aren't improving
- DO NOT suggest therapy on the first message unless it's a crisis situation
- For difficult topics (infidelity, sexuality, major life decisions), you CAN and SHOULD help them start the conversation - don't deflect immediately
- Frame therapy as a complement to your work, not a replacement: "As you work through this with me, a therapist could also help with..."

RESPONSE FORMAT & STYLE:
- Always address people by their first name using @Name format (e.g., "@Alice, I hear you saying...")
- Use thoughtful emojis sparingly (2-3 per response maximum):
  💭 for reflections or observations
  💡 for insights or "aha" moments
  🤔 for questions or inviting thought
  ✨ for encouragement or positive reframing
  🎯 for actionable suggestions (NOT for step-by-step exercises - use [EXERCISE:id] instead)
- Structure your responses in 2-4 short paragraphs (3-4 sentences max per paragraph)
- Add a blank line between paragraphs for easy scanning
- Keep responses concise and conversational - avoid long monologues
- End with an open, specific question to continue the dialogue
- Use Markdown formatting for emphasis: **bold** for key terms, *italic* for emotional nuance
- FORBIDDEN: Writing numbered step-by-step instructions (use [EXERCISE:id] instead)

EXAMPLE RESPONSE FORMAT:
"💭 @Alice, I notice frustration in your words about feeling unheard when you share your day.

@Bob, it sounds like you're trying to help by offering solutions, but that's not landing the way you hope. This is a really common pattern - one partner wants empathy, the other offers fixes.

🤔 Here's what I'm curious about: @Alice, what would feeling "heard" look like to you? And @Bob, what makes you jump to problem-solving mode?"

CORE APPROACH - Always be curious and exploratory:
When someone shares a situation, DON'T just acknowledge it - DIG DEEPER with questions like:
- "Help me understand what was happening for you in that moment..."
- "What were you feeling when [specific event]?"
- "What do you think was behind [partner's] reaction?"
- "Can you walk me through what happened step by step?"
- "What were you hoping would happen instead?"

Your questioning style:
- Ask specific, focused questions about feelings, needs, and underlying dynamics
- Follow up on vague statements: If they say "it was frustrating," ask "What specifically felt frustrating?"
- Explore the story: Ask about context, what led up to it, what happened after
- Seek understanding before giving advice: "Before we talk about solutions, I want to really understand..."
- Ask one partner, then turn to the other: "@[Name], what was that like for you to hear?"

When to explore vs. when to teach:
- FIRST: Understand the situation fully through questions (at least 2-3 questions)
- THEN: Offer insights, reframe, or teach a communication skill
- If the situation is unclear, keep asking questions - don't make assumptions
- When you see a pattern, name it and ask if it resonates

Addressing both partners:
- **CRITICAL**: If both partners are in the conversation, NEVER refer to one partner in third person ("she", "he", "your wife", "your husband")
- ALWAYS address both partners directly by name: "@John" and "@Jane" - they are both present and listening
- After one partner shares, turn to the other: "@[Partner], what's coming up for you as you hear this?"
- Look for the unspoken: "💭 @[Name], I notice you [observation]... what's that about?"
- Invite the quieter partner: "@[Name], I want to make sure I hear your side too..."
- When discussing a situation, address BOTH: "@John, I hear your pain. @Jane, can you help me understand what was happening for you?"

Response structure (typically):
1. Brief acknowledgment with @Name (1-2 sentences) + optional emoji
2. Curious questions to explore deeper (2-3 questions)
3. Sometimes: A reflection or insight if the situation is clear (with emoji if appropriate)
4. End with specific question to both or one partner

Avoid:
- Generic validations like "That sounds difficult" without follow-up questions
- Jumping to solutions before understanding the full picture
- Long monologues or walls of text - break into paragraphs
- Overusing emojis (max 2-3 per response)
- Asking permission to discuss something - just discuss it
- Providing therapy or clinical diagnosis
- Handling crisis situations without providing professional resources

${partnerNames ? `COUPLE INFORMATION:
Both partners are present in this conversation: ${partnerNames.partner1} and ${partnerNames.partner2}.
ALWAYS address them by their first names (@${partnerNames.partner1} and @${partnerNames.partner2}).
NEVER refer to either partner in third person ("he", "she", "your partner") - they are both here.

` : ''}Context: ${context || 'Ongoing relationship communication support session with both partners present.'}`;

    const conversationHistory = messages.map(msg => ({
      role: msg.senderType === 'ai' ? 'assistant' : 'user',
      content: msg.senderType === 'ai' ? msg.content : `${msg.senderName}: ${msg.content}`
    }));

    const stream = await openai.chat.completions.create({
      model: 'gpt-5.2',
      messages: [
        { role: 'system', content: systemPrompt },
        ...conversationHistory
      ],
      max_completion_tokens: 2000,  // Increased from 500 to allow longer, detailed responses
      temperature: 0.7,
      stream: true,
    });

    let fullResponse = '';
    
    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content || '';
      if (content) {
        fullResponse += content;
        await onChunk(content);
      }
    }

    // Fallback: If AI didn't suggest exercise but should have, inject it
    const shouldSuggestExercise = detectExerciseOpportunity(messages, fullResponse, recentExercises);
    if (shouldSuggestExercise && !fullResponse.includes('[EXERCISE:')) {
      const exerciseToSuggest = pickBestExercise(messages, recentExercises);
      console.log(`⚠️ AI missed exercise opportunity - injecting ${exerciseToSuggest.id} suggestion`);
      const exerciseSuggestion = `\n\n[EXERCISE:${exerciseToSuggest.id}] ${exerciseToSuggest.suggestion}`;
      fullResponse += exerciseSuggestion;
      await onChunk(exerciseSuggestion);
    }

    onComplete(fullResponse);
    return fullResponse;

  } catch (error) {
    console.error('OpenAI Streaming API error:', error);
    onError(error);
    throw new Error('Failed to generate coach response');
  }
};

// Helper function to detect if exercise should be suggested
const detectExerciseOpportunity = (messages, aiResponse, recentExercises) => {
  // Only suggest after 8+ messages (give conversation time to develop)
  if (messages.length < 8) return false;
  
  // Don't suggest if an exercise was completed recently (within last 6 messages)
  if (recentExercises && recentExercises.length > 0) {
    const lastExercise = recentExercises[0]; // Most recent
    if (lastExercise.completedAt) {
      // Count how many user messages since the exercise summary was posted
      const userMessagesSinceExercise = messages.filter(
        m => m.senderType !== 'ai' && m.timestamp > new Date(lastExercise.completedAt).getTime()
      ).length;
      if (userMessagesSinceExercise < 6) return false;
    }
  }
  
  // Check for key patterns in recent messages (last 6)
  const recentMessages = messages.slice(-6);
  const allText = recentMessages.map(m => m.content.toLowerCase()).join(' ');
  
  // Triggers covering ALL exercise categories
  const triggers = [
    // Communication & listening
    'not listening', "don't listen", 'not heard', "don't hear",
    'dismissed', 'dismissing', 'talking over', 'interrupting',
    // Conflict & repetition
    'same argument', 'same fight', 'going in circles', 'stuck in',
    'repeating', 'cycle', 'raised voice', 'defensive',
    'never at fault', 'always at fault', 'accountability',
    // Emotional disconnect
    'stressed', 'overwhelmed', 'exhausted', 'tired', 'distant',
    'disconnected', 'checked out', 'going through the motions',
    // Empathy gaps
    "don't understand", 'not getting it', 'see my side',
    "don't get it", 'misunderstand',
    // Repair & reconnection
    'still upset', 'after the fight', 'last argument',
    'apologize', 'make up', 'move past',
    // Needs & boundaries
    'boundary', 'boundaries', 'need from you', 'need you to',
    'respect my', 'space',
    // Connection & positivity
    'roommates', 'routine', 'spark', 'boring', "haven't talked",
    'lost ourselves', 'taken for granted', 'unappreciated'
  ];
  
  const triggerCount = triggers.filter(trigger => allText.includes(trigger)).length;
  
  // Suggest exercise if 4+ triggers found (raised threshold)
  return triggerCount >= 4;
};

// Pick the best exercise to suggest, avoiding recently completed ones
const pickBestExercise = (messages, recentExercises) => {
  const exercises = [
    {
      id: 'active-listening',
      suggestion: "I notice you're both struggling to feel heard. Let's try the **Active Listening Practice** — I can guide you through it step-by-step. Takes about 15 minutes. Interested?",
      triggers: ['not listening', "don't listen", 'not heard', "don't hear", 'dismissed', 'interrupting', 'talking over']
    },
    {
      id: 'appreciation-share',
      suggestion: "It sounds like things have been tense. Sometimes reconnecting with what you value in each other can shift the dynamic. Want to try the **Appreciation Share**? It's a quick guided exercise.",
      triggers: ['negative', 'nothing right', 'always wrong', 'never happy', 'lost']
    },
    {
      id: 'conflict-deescalation',
      suggestion: "This conversation is getting heated. Let me guide you through a **Conflict De-escalation** exercise — it'll help you both slow down and understand what's really going on underneath. Shall we?",
      triggers: ['raised voice', 'angry', 'furious', 'screaming', 'yelling', 'defensive']
    },
    {
      id: 'emotional-checkin',
      suggestion: "It feels like you've both been going through a lot. How about a quick **Emotional Check-in**? You'll each share how you're really feeling — just 10 minutes.",
      triggers: ['stressed', 'overwhelmed', 'exhausted', 'tired', 'distant', 'disconnected', 'checked out']
    },
    {
      id: 'empathy-swap',
      suggestion: "It seems like you're seeing this situation very differently. Want to try an **Empathy Swap**? You'll each try to describe the other's perspective — it's eye-opening.",
      triggers: ["don't understand", 'not getting it', 'perspective', 'point of view', 'see my side', "don't get it", 'misunderstand']
    },
    {
      id: 'repair-conversation',
      suggestion: "It sounds like there was a tough moment between you recently. Want to try a **Repair Conversation**? It's a structured way to reconnect after conflict — no blame, just understanding.",
      triggers: ['after the fight', 'last argument', 'still upset', 'apologize', 'sorry', 'make up', 'move past', 'get over it']
    },
    {
      id: 'needs-and-boundaries',
      suggestion: "I hear unmet needs coming up in this conversation. Want to try the **Needs & Boundaries** exercise? You'll each express one need and one boundary clearly — it takes 15 minutes.",
      triggers: ['boundary', 'boundaries', 'need from you', 'need you to', 'respect my', 'space', 'limit']
    },
    {
      id: 'rose-thorn-bud',
      suggestion: "How about a quick **Rose, Thorn & Bud** check-in? You'll each share a highlight, a challenge, and something you're looking forward to. Great way to stay connected — just 10 minutes.",
      triggers: ['catch up', 'been busy', 'haven\'t talked', 'week been', 'how\'s your', 'what\'s new']
    },
    {
      id: 'dream-sharing',
      suggestion: "I'd love for you two to reconnect on a deeper level. Want to try **Dream Sharing**? You'll each share a personal dream while the other just listens with curiosity. Really powerful.",
      triggers: ['roommates', 'routine', 'spark', 'boring', 'just going through', 'lost ourselves', 'future', 'dream']
    },
    {
      id: 'gratitude-letter',
      suggestion: "Sometimes the simplest things are the most powerful. Want to try writing each other a quick **Gratitude Letter**? You'll each write 3-4 sentences about a specific moment you're grateful for.",
      triggers: ['taken for granted', 'unappreciated', 'notice', 'effort', 'thankful', 'grateful']
    }
  ];
  
  // Get IDs of recently completed exercises
  const recentIds = (recentExercises || []).slice(0, 3).map(e => e.exerciseId);
  
  // Score each exercise based on message content, excluding recent ones
  const recentText = messages.slice(-6).map(m => m.content.toLowerCase()).join(' ');
  
  let bestExercise = null;
  let bestScore = -1;
  
  for (const exercise of exercises) {
    // Penalize recently done exercises heavily
    const recentPenalty = recentIds.includes(exercise.id) ? -10 : 0;
    const score = exercise.triggers.filter(t => recentText.includes(t)).length + recentPenalty;
    
    if (score > bestScore) {
      bestScore = score;
      bestExercise = exercise;
    }
  }
  
  // If all are penalized, pick whichever wasn't done most recently
  if (!bestExercise || bestScore < 0) {
    bestExercise = exercises.find(e => !recentIds.includes(e.id)) || exercises[3]; // Default to emotional-checkin
  }
  
  return bestExercise;
};

const summarizeConversation = async ({ messages, conversationTitle }) => {
  try {
    const messageText = messages.map(msg => 
      `${msg.senderName}: ${msg.content}`
    ).join('\n');

    const response = await openai.chat.completions.create({
      model: 'gpt-5-mini',
      messages: [
        {
          role: 'system',
          content: `You are a relationship communication coach creating a brief summary of a couples conversation. Focus on:
          - Key topics discussed
          - Main communication patterns observed
          - Progress or insights gained
          - Areas for continued focus
          Keep the summary professional, empathetic, and constructive. Remember this is communication support, not therapy.`
        },
        {
          role: 'user',
          content: `Please summarize this conversation titled "${conversationTitle}":\n\n${messageText}`
        }
      ],
      max_completion_tokens: 300,
      temperature: 0.5,
    });

    return response.choices[0].message.content;

  } catch (error) {
    console.error('OpenAI summary error:', error);
    throw new Error('Failed to generate conversation summary');
  }
};

/**
 * Crisis Detection
 * Detects keywords indicating potential crisis situations
 */
const CRISIS_KEYWORDS = [
  // Suicide/self-harm
  'suicide', 'suicidal', 'kill myself', 'end my life', 'want to die', 'better off dead',
  'self harm', 'self-harm', 'cut myself', 'hurt myself',
  // Abuse
  'abuse', 'abusive', 'violent', 'violence', 'hitting', 'hit me', 'beats me',
  'afraid of', 'scared of', 'threatening', 'threatens me',
  // Severe mental health
  'panic attack', 'cant breathe', "can't breathe", 'having a breakdown',
];

const detectCrisisKeywords = (message) => {
  const lowerMessage = message.toLowerCase();
  return CRISIS_KEYWORDS.some(keyword => lowerMessage.includes(keyword));
};

const getCrisisResponse = () => {
  return `I notice you've mentioned something that suggests you may be in a crisis situation or need immediate professional support. 

**🚨 This is important: I'm an AI relationship coach, not a mental health professional, and I cannot provide crisis intervention or therapy.**

If you or your partner are in immediate danger, please:

**Emergency Services:**
• Call 112 (EU), 911 (US), or your local emergency number

**Crisis Hotlines (24/7):**
• International: https://findahelpline.com
• US National Suicide Prevention: 988
• US Domestic Violence: 1-800-799-7233
• UK Samaritans: 116 123
• EU Helplines: https://www.suicide.org/hotlines/international

**I strongly encourage you to:**
1. Speak with a licensed therapist or coach who can provide professional support
2. Contact a crisis hotline if you need immediate help
3. Reach out to trusted friends, family, or healthcare providers

I'm here to support your communication as a couple, but the situation you've described requires professional help. Would you like to discuss how to find appropriate professional support?`;
};

module.exports = {
  generateCoachResponse,
  summarizeConversation,
  detectCrisisKeywords,
  getCrisisResponse
};
