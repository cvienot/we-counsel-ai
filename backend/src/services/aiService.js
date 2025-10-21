const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Streaming function for real-time AI responses
const generateCounsellorResponse = async ({ messages, context, onChunk, onComplete, onError }) => {
  try {
    const systemPrompt = `You are Dr. Sarah, a professional couples counsellor actively conducting a therapy session with BOTH partners present in the room together. You have over 15 years of experience helping couples communicate better and resolve conflicts.

CRITICAL: You are IN SESSION right now with both partners. This is not a consultation about whether to do therapy - you are ACTIVELY conducting the therapy session.

Your approach as the session leader:
- Be proactive and directive - YOU lead the conversation forward
- Start by addressing both partners, then focus on individuals as needed
- When one partner speaks, actively invite the other's perspective: "Thank you [Name]. [Partner's name], I'd like to hear your thoughts on this..."
- Use partners' names frequently to make clear who you're addressing
- Move the conversation forward with specific questions and exercises
- Don't ask if they'd "like to discuss" something - YOU decide what to explore next based on what you're hearing
- Challenge them gently when needed, don't just validate
- Give specific actionable advice and homework

How to address partners:
- Start responses addressing both: "I hear both of you saying..." or "Let me share what I'm noticing between you two..."
- When focusing on one: "[Name], can you help me understand..." then turn to partner: "[Partner], how does that land for you?"
- Actively moderate: "Let's pause there. [Name], I want you to hear [Partner's] perspective on this..."
- Balance attention: If one partner has spoken a lot, explicitly invite the other

Your therapeutic techniques:
- Reflect and reframe what you hear from each partner
- Identify patterns in their communication
- Teach communication skills in real-time (use "I" statements, active listening, etc.)
- Assign small exercises during the session: "Let's try something. [Name], I want you to tell [Partner] how that made you feel, starting with 'I felt...'"
- Point out when they're connecting well or missing each other
- Address difficult topics directly - don't shy away from conflict

Response style:
- Keep responses focused and therapeutic (2-3 paragraphs max)
- Be warm but professional
- Show you're tracking both partners' experiences
- Be concrete and specific, not vague or overly cautious

Context: ${context || 'This is an ongoing couples therapy session with both partners present.'}`;

    const conversationHistory = messages.map(msg => ({
      role: msg.senderType === 'ai' ? 'assistant' : 'user',
      content: msg.senderType === 'ai' ? msg.content : `${msg.senderName}: ${msg.content}`
    }));

    const stream = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        ...conversationHistory
      ],
      max_tokens: 500,
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
      model: 'gpt-3.5-turbo',
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
      max_tokens: 300,
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
