const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb');
const { unmarshall } = require('@aws-sdk/util-dynamodb');

const client = new DynamoDBClient({
  region: 'eu-west-3',
  endpoint: 'http://localhost:8000'
});

(async () => {
  try {
    // Find John and Jane
    const usersResult = await client.send(new ScanCommand({
      TableName: 'we-counsel-users',
      FilterExpression: 'contains(#fn, :john) OR contains(#fn, :jane)',
      ExpressionAttributeNames: { '#fn': 'firstName' },
      ExpressionAttributeValues: {
        ':john': { S: 'John' },
        ':jane': { S: 'Jane' }
      }
    }));
    
    if (usersResult.Items.length === 0) {
      console.log('❌ No users found with names John or Jane');
      return;
    }
    
    const users = usersResult.Items.map(item => unmarshall(item));
    console.log('✅ Found users:', users.map(u => `${u.firstName} - coupleId: ${u.coupleId}`).join(', '));
    
    const coupleId = users[0].coupleId;
    if (!coupleId) {
      console.log('⚠️  Users not in a couple yet');
      return;
    }
    
    // Find their conversations
    const convsResult = await client.send(new ScanCommand({
      TableName: 'we-counsel-conversations',
      FilterExpression: 'coupleId = :coupleId',
      ExpressionAttributeValues: {
        ':coupleId': { S: coupleId }
      }
    }));
    
    if (convsResult.Items.length === 0) {
      console.log('❌ No conversations found for this couple');
      return;
    }
    
    const conversation = unmarshall(convsResult.Items[0]);
    console.log(`\n💬 Conversation: "${conversation.title}"`);
    
    // Get messages
    const msgsResult = await client.send(new ScanCommand({
      TableName: 'we-counsel-messages',
      FilterExpression: 'conversationId = :convId',
      ExpressionAttributeValues: {
        ':convId': { S: conversation.conversationId }
      }
    }));
    
    const messages = msgsResult.Items.map(item => unmarshall(item)).sort((a, b) => a.timestamp - b.timestamp);
    console.log(`📊 Total messages: ${messages.length}`);
    
    // Find latest AI message
    const aiMessages = messages.filter(m => m.senderType === 'ai');
    if (aiMessages.length === 0) {
      console.log('❌ No AI messages found');
      return;
    }
    
    console.log(`🤖 AI messages: ${aiMessages.length}`);
    
    const latestAI = aiMessages[aiMessages.length - 1];
    console.log(`\n📅 Latest AI message (from ${new Date(latestAI.timestamp).toLocaleString()}):`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(latestAI.content);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Show previous messages for context
    const recentMessages = messages.slice(-5);
    console.log('\n📜 Last 5 messages for context:');
    console.log('─────────────────────────────────────');
    recentMessages.forEach(msg => {
      const sender = msg.senderType === 'ai' ? '🤖 Coach Sarah' : `👤 ${msg.senderName}`;
      const content = msg.content.length > 100 ? msg.content.substring(0, 100) + '...' : msg.content;
      console.log(`${sender}: ${content}\n`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  }
})();
