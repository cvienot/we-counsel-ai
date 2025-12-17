// Simple script to test summarization logic

const http = require('http');

async function testSummarization() {
  const apiUrl = 'http://localhost:3001/api';
  
  // Create test users
  console.log('Creating test users...');
  const user1Response = await fetch(`${apiUrl}/test/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `test1-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Test',
      lastName: 'User1',
      language: 'en',
      termsAccepted: true
    })
  });
  const user1Data = await user1Response.json();
  const user1Token = user1Data.token;
  const user1Id = user1Data.user.userId;
  
  const user2Response = await fetch(`${apiUrl}/test/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `test2-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Test',
      lastName: 'User2',
      language: 'en',
      termsAccepted: true
    })
  });
  const user2Data = await user2Response.json();
  const user2Token = user2Data.token;
  
  // Connect partners
  console.log('Connecting partners...');
  await fetch(`${apiUrl}/test/connect-partners`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${user1Token}` },
    body: JSON.stringify({ userId1: user1Id, userId2: user2Data.user.userId })
  });
  
  // Create conversation
  console.log('Creating conversation...');
  const convResponse = await fetch(`${apiUrl}/conversations`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${user1Token}` },
    body: JSON.stringify({ title: 'Test Conversation', type: 'main' })
  });
  const convData = await convResponse.json();
  const conversationId = convData.conversation.conversationId;
  console.log(`Conversation created: ${conversationId}`);
  
  // Send 13 messages (will generate 26 total with AI responses)
  console.log('Sending messages...');
  for (let i = 1; i <= 13; i++) {
    const response = await fetch(`${apiUrl}/messages/${conversationId}/ai-stream`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json', 
        'Authorization': `Bearer ${i % 2 === 0 ? user2Token : user1Token}`
      },
      body: JSON.stringify({
        content: `Test message ${i}`,
        recipientType: 'both'
      })
    });
    console.log(`Message ${i} sent, status: ${response.status}`);
    await new Promise(resolve => setTimeout(resolve, 200)); // Wait for AI response
  }
  
  // Wait for all AI responses to complete
  console.log('Waiting for AI responses to complete...');
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Check conversation
  const checkResponse = await fetch(`${apiUrl}/conversations/${conversationId}`, {
    headers: { 'Authorization': `Bearer ${user1Token}` }
  });
  const checkData = await checkResponse.json();
  const conversation = checkData.conversation;
  
  console.log('\nConversation state:');
  console.log(`- Message count: ${conversation.messageCount}`);
  console.log(`- Summarized count: ${conversation.summarizedMessageCount || 0}`);
  console.log(`- Has summary: ${conversation.summary ? 'YES' : 'NO'}`);
  if (conversation.summary) {
    console.log(`- Summary: ${conversation.summary.substring(0, 150)}...`);
  }
}

testSummarization().catch(console.error);
