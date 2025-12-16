const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Streaming function for real-time AI responses
const generateCounsellorResponse = async ({ messages, context, onChunk, onComplete, onError }) => {
  try {
    const systemPrompt = `You are Dr. Sarah, an experienced couples therapist conducting an active therapy session. Both partners are present. Your job is to deeply understand their situation and help them work through it.

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
- THEN: Offer insights, reframe, or teach a skill
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

Context: ${context || 'Ongoing couples therapy session with both partners present.'}`;

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
          content: `You are a professional therapist creating a brief summary of a couples counselling session. Focus on:
          - Key topics discussed
          - Main concerns raised by each partner
          - Progress or insights gained
          - Areas that may need future attention
          Keep the summary professional, empathetic, and constructive.`
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

module.exports = {
  generateCounsellorResponse,
  summarizeConversation
};
