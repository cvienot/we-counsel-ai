/**
 * Mock AI Service for Testing
 * Generates deterministic AI responses for testing
 */

// In-memory storage for test assertions
global.mockAIStore = global.mockAIStore || [];

const generateCoachResponse = async ({ messages, context, recentExercises, onChunk, onComplete, onError }) => {
  try {
    // Generate deterministic mock response based on last message
    const lastMessage = messages[messages.length - 1];
    const mockResponse = generateMockResponse(lastMessage.content);
    
    // Store for assertions
    global.mockAIStore.push({
      messagesCount: messages.length,
      context,
      lastUserMessage: lastMessage.content,
      response: mockResponse,
      timestamp: new Date().toISOString()
    });
    
    console.log('🤖 MOCK AI Response:', mockResponse.substring(0, 50) + '...');
    
    // Simulate streaming with small delay
    const words = mockResponse.split(' ');
    let currentText = '';
    
    for (const word of words) {
      currentText += (currentText ? ' ' : '') + word;
      await onChunk(word + ' ');
      // Small delay to simulate streaming (faster for tests)
      await new Promise(resolve => setTimeout(resolve, 10));
    }
    
    await onComplete(mockResponse);
    return mockResponse;
  } catch (error) {
    console.error('Mock AI error:', error);
    if (onError) {
      onError(error);
    }
    throw error;
  }
};

function generateMockResponse(userMessage) {
  const lowerMessage = userMessage.toLowerCase();
  
  // Generate contextual mock responses
  if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
    return "Hello! Thank you for reaching out. I'm Sarah, your AI relationship coach. I'm here to help you and your partner improve your communication. What would you like to discuss today?";
  }
  
  if (lowerMessage.includes('problem') || lowerMessage.includes('issue') || lowerMessage.includes('difficult')) {
    return "Thank you for sharing that with me. It takes courage to acknowledge challenges in a relationship. Can you tell me more about what you're experiencing? Understanding the context will help me provide better communication guidance.";
  }
  
  if (lowerMessage.includes('communication')) {
    return "Communication is fundamental to any healthy relationship. I appreciate you bringing this up. Let's explore what effective communication looks like for you both and identify some strategies that might help.";
  }

  if (lowerMessage.includes('commitment e2e')) {
    return "You have both landed on something concrete enough to practice outside this thread.\n\n[COMMITMENT:pause-reflect-script]\ntitle=Practice the pause-reflect script\nagreement=Pause before explaining, reflect the feeling, reassure both sides will be heard, then discuss facts.\npractice=Try the script once this week on a low-stakes topic and come back with what happened.\ndue_days=7";
  }
  
  if (lowerMessage.includes('thank')) {
    return "You're welcome! I'm here to support your communication. Remember, working on your relationship is a journey, and you're taking positive steps by being here.";
  }
  
  // Default response
  return "Thank you for sharing that. I'm here to support your communication as a couple. This is a safe space where we can explore your thoughts and feelings together. How does your partner feel about this?";
}

const summarizeConversation = async ({ messages, conversationTitle }) => {
  // Generate a mock summary based on message content
  const messageCount = messages.length;
  const userMessages = messages.filter(m => m.senderType === 'user');
  const topics = new Set();
  
  // Extract some keywords from messages
  userMessages.forEach(msg => {
    const content = msg.content.toLowerCase();
    if (content.includes('problem') || content.includes('issue')) topics.add('challenges');
    if (content.includes('feel') || content.includes('emotion')) topics.add('emotions');
    if (content.includes('communication')) topics.add('communication');
    if (content.includes('love') || content.includes('care')) topics.add('affection');
  });
  
  const topicsList = Array.from(topics).join(', ') || 'relationship dynamics';
  
  const summary = `Session Summary for "${conversationTitle}":

The couple engaged in ${messageCount} exchanges discussing ${topicsList}. Both partners participated actively in the conversation, sharing their perspectives and feelings. Key themes included understanding each other's needs and working on their relationship together. The session showed progress in opening up communication channels.

Areas for continued focus: Further exploration of underlying needs, practicing active listening, and building emotional connection.`;

  console.log('🤖 MOCK AI Summary generated:', summary.substring(0, 100) + '...');
  
  return summary;
};

module.exports = {
  generateCoachResponse,
  summarizeConversation
};
