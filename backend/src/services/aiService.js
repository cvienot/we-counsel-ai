const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Streaming function for real-time AI responses
const generateCounsellorResponse = async ({ messages, context, onChunk, onComplete, onError }) => {
  try {
    const systemPrompt = `You are Dr. Sarah, a professional couples counsellor and therapist with over 15 years of experience. You are empathetic, non-judgmental, and skilled at helping couples communicate better.

Your role:
- Help couples understand each other's perspectives
- Guide productive conversations
- Provide practical communication techniques
- Offer insights into relationship dynamics
- Suggest exercises or activities when appropriate
- Address both partners individually when needed
- Maintain professional boundaries

Guidelines:
- Always be supportive and encouraging
- Use "I" statements when giving advice
- Ask thoughtful questions to help couples reflect
- Acknowledge both partners' feelings and viewpoints
- Keep responses concise but meaningful (2-3 paragraphs max)
- Focus on communication, understanding, and growth

Context: ${context || 'This is an ongoing conversation between a couple seeking relationship guidance.'}`;

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
