require('dotenv').config();
const { docClient, TABLES } = require('../src/config/database');
const { ScanCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');

async function checkConversation() {
  try {
    console.log('Looking for Alex and Emma...\n');

    // Find Alex
    const alexParams = {
      TableName: TABLES.USERS,
      FilterExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': 'alex@example.com'
      }
    };
    const alexResult = await docClient.send(new ScanCommand(alexParams));
    const alex = alexResult.Items[0];

    // Find Emma
    const emmaParams = {
      TableName: TABLES.USERS,
      FilterExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': 'emma@example.com'
      }
    };
    const emmaResult = await docClient.send(new ScanCommand(emmaParams));
    const emma = emmaResult.Items[0];

    if (!alex || !emma) {
      console.log('Alex or Emma not found');
      return;
    }

    console.log(`Found Alex (${alex.userId}) and Emma (${emma.userId})`);

    // Find their couple
    const coupleParams = {
      TableName: TABLES.COUPLES,
      FilterExpression: 'user1Id = :alexId OR user2Id = :alexId',
      ExpressionAttributeValues: {
        ':alexId': alex.userId
      }
    };
    const coupleResult = await docClient.send(new ScanCommand(coupleParams));
    const couple = coupleResult.Items[0];

    if (!couple) {
      console.log('Couple not found');
      return;
    }

    console.log(`Found couple (${couple.coupleId})\n`);

    // Find their conversations
    const convParams = {
      TableName: TABLES.CONVERSATIONS,
      FilterExpression: 'coupleId = :coupleId',
      ExpressionAttributeValues: {
        ':coupleId': couple.coupleId
      }
    };
    const convResult = await docClient.send(new ScanCommand(convParams));
    const conversation = convResult.Items[0];

    if (!conversation) {
      console.log('No conversation found');
      return;
    }

    console.log(`Found conversation (${conversation.conversationId})`);
    console.log(`Title: ${conversation.title || 'Untitled'}\n`);

    // Get messages using the conversationId-timestamp-index
    const messageParams = {
      TableName: TABLES.MESSAGES,
      IndexName: 'conversationId-timestamp-index',
      KeyConditionExpression: 'conversationId = :convId',
      ExpressionAttributeValues: {
        ':convId': conversation.conversationId
      },
      ScanIndexForward: true // Oldest first
    };

    const messageResult = await docClient.send(new QueryCommand(messageParams));
    console.log(`Found ${messageResult.Items.length} messages:\n`);

    messageResult.Items.forEach((msg, idx) => {
      const sender = msg.senderType === 'ai' ? 'AI Coach' : 
                    (msg.senderId === alex.userId ? 'Alex' : 'Emma');
      const date = new Date(msg.timestamp).toLocaleString();
      console.log(`${idx + 1}. [${sender}] ${date}`);
      console.log(`   ${msg.content}`);
      console.log('');
    });

  } catch (error) {
    console.error('Error:', error);
  }
}

checkConversation();
