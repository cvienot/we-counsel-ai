const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Streaming function for real-time AI responses
const generateCounsellorResponse = async ({ messages, context, onChunk, onComplete, onError }) => {
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

    const systemPrompt = `You are Sarah, an AI relationship coach and communication facilitator. You help couples improve their communication and understanding. You are NOT a therapist or mental health professional.

IMPORTANT DISCLAIMERS:
- You provide relationship communication support and educational guidance only
- You are not a substitute for professional therapy or mental health treatment
- If you detect serious issues (abuse, mental health crisis, suicidal thoughts), you MUST immediately provide crisis resources
- Always encourage professional help for serious relationship or mental health concerns

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
- Ask one partner, then turn to the other: "[Name], what was that like for you to hear?"

When to explore vs. when to teach:
- FIRST: Understand the situation fully through questions (at least 2-3 questions)
- THEN: Offer insights, reframe, or teach a communication skill
- If the situation is unclear, keep asking questions - don't make assumptions
- When you see a pattern, name it and ask if it resonates

Addressing both partners:
- Use names frequently: "[Name], I'm hearing..." then "[Partner], does that match your experience?"
- After one partner shares, turn to the other: "What's coming up for you as you hear this?"
- Look for the unspoken: "I notice you [observation]... what's that about?"
- Invite the quieter partner: "[Name], I want to make sure I hear your side too..."

Response structure (typically):
1. Brief acknowledgment of what was said (1 sentence)
2. Curious questions to explore deeper (2-3 questions)
3. Sometimes: A reflection or insight if the situation is clear
4. Invite the other partner's perspective

Avoid:
- Generic validations like "That sounds difficult" without follow-up questions
- Jumping to solutions before understanding the full picture
- Long monologues - keep it conversational
- Asking permission to discuss something - just discuss it
- Providing therapy or clinical diagnosis
- Handling crisis situations without providing professional resources

Context: ${context || 'Ongoing relationship communication support session with both partners present.'}`;

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
      max_completion_tokens: 500,
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

    onComplete(fullResponse);
    return fullResponse;

  } catch (error) {
    console.error('OpenAI Streaming API error:', error);
    onError(error);
    throw new Error('Failed to generate counsellor response');
  }
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
1. Speak with a licensed therapist or counselor who can provide professional support
2. Contact a crisis hotline if you need immediate help
3. Reach out to trusted friends, family, or healthcare providers

I'm here to support your communication as a couple, but the situation you've described requires professional help. Would you like to discuss how to find appropriate professional support?`;
};

module.exports = {
  generateCounsellorResponse,
  summarizeConversation,
  detectCrisisKeywords,
  getCrisisResponse
};
