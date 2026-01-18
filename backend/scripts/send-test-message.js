require('dotenv').config();
const { docClient, TABLES } = require('../src/config/database');
const { ScanCommand, QueryCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

async function sendTestMessage() {
  try {
    console.log('Finding Alex...\n');

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

    if (!alex) {
      console.log('Alex not found');
      return;
    }

    console.log(`Found Alex (${alex.userId})`);

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

    console.log(`Found couple (${couple.coupleId})`);

    // Find their conversation
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

    console.log(`Found conversation (${conversation.conversationId})\n`);

    // Create a new message from Alex
    const messageId = uuidv4();
    const timestamp = new Date().toISOString();
    
    const message = {
      messageId,
      conversationId: conversation.conversationId,
      senderId: alex.userId,
      senderName: alex.name,
      senderType: 'user',
      content: "You're right Emma. We do need help with this pattern. We keep going in circles.",
      timestamp,
      createdAt: timestamp,
      updatedAt: timestamp
    };

    await docClient.send(new PutCommand({
      TableName: TABLES.MESSAGES,
      Item: message
    }));

    console.log('✅ Message sent from Alex:');
    console.log(`   "${message.content}"\n`);
    console.log('Now you can check the conversation to see if the AI responds with [EXERCISE:active-listening] marker!');

  } catch (error) {
    console.error('Error:', error);
  }
}

sendTestMessage();
