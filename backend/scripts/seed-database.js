#!/usr/bin/env node

require('dotenv').config();
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const bcrypt = require('bcryptjs');

// Configure AWS DynamoDB to use local instance
const client = new DynamoDBClient({
  region: 'us-east-1',
  endpoint: 'http://localhost:8000',
  credentials: {
    accessKeyId: 'dummy',
    secretAccessKey: 'dummy'
  }
});

const dynamodb = DynamoDBDocumentClient.from(client);

// Helper function to add delay
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function seedDatabase() {
  console.log('🌱 Starting database seeding...');
  
  // Dynamic import for ES modules
  const { v4: uuidv4 } = await import('uuid');

  try {
    // Create test users
    const users = [
      {
        userId: uuidv4(),
        email: 'john@example.com',
        name: 'John Doe',
        passwordHash: await bcrypt.hash('password123', 10),
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        userId: uuidv4(),
        email: 'jane@example.com',
        name: 'Jane Smith',
        passwordHash: await bcrypt.hash('password123', 10),
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ];

    // Create a couple relationship first
    const coupleId = uuidv4();
    const couple = {
      coupleId: coupleId,
      user1Id: users[0].userId,
      user2Id: users[1].userId,
      status: 'active',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // Update users to include couple information
    users[0].partnerId = users[1].userId;
    users[0].coupleId = coupleId;
    users[1].partnerId = users[0].userId;
    users[1].coupleId = coupleId;

    // Insert users
    console.log('👥 Creating test users...');
    for (const user of users) {
      await dynamodb.send(new PutCommand({
        TableName: 'we-counsel-users',
        Item: user,
        ConditionExpression: 'attribute_not_exists(userId)'
      }));
      console.log(`   ✅ Created user: ${user.email}`);
      await delay(100); // Small delay between operations
    }

    // Create the couple relationship
    console.log('💕 Creating couple relationship...');
    await dynamodb.send(new PutCommand({
      TableName: 'we-counsel-couples',
      Item: couple
    }));
    console.log('   ✅ Created couple relationship between John and Jane');

    // Create a conversation between the users
    const conversationId = uuidv4();
    const conversation = {
      conversationId: conversationId,
      coupleId: coupleId,
      user1Id: users[0].userId,
      user2Id: users[1].userId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'active'
    };

    console.log('💬 Creating test conversation...');
    await dynamodb.send(new PutCommand({
      TableName: 'we-counsel-conversations',
      Item: conversation
    }));
    console.log('   ✅ Created conversation between John and Jane');

    // Create some test messages
    const messages = [
      {
        messageId: uuidv4(),
        conversationId: conversationId,
        senderId: users[0].userId,
        content: 'Hi Jane, how are you feeling today?',
        timestamp: Date.now() - 3600000, // 1 hour ago (as number for GSI)
        type: 'user'
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId,
        senderId: users[1].userId,
        content: 'I\'ve been struggling with some anxiety lately. Thanks for asking.',
        timestamp: Date.now() - 3300000, // 55 minutes ago
        type: 'user'
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId,
        senderId: 'ai-counsellor',
        content: 'I understand that anxiety can be challenging. It\'s great that you\'re reaching out for support. Can you tell me more about what triggers these feelings?',
        timestamp: Date.now() - 3000000, // 50 minutes ago
        type: 'ai'
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId,
        senderId: users[1].userId,
        content: 'It usually happens when I have to speak in public or during important meetings at work.',
        timestamp: Date.now() - 2700000, // 45 minutes ago
        type: 'user'
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId,
        senderId: users[0].userId,
        content: 'I can relate to that, Jane. I used to feel the same way. Have you tried any coping strategies?',
        timestamp: Date.now() - 2400000, // 40 minutes ago
        type: 'user'
      }
    ];

    console.log('📝 Creating test messages...');
    for (const message of messages) {
      await dynamodb.send(new PutCommand({
        TableName: 'we-counsel-messages',
        Item: message
      }));
      await delay(100); // Small delay between operations
    }
    console.log(`   ✅ Created ${messages.length} test messages`);

    console.log('\n🎉 Database seeding completed successfully!');
    console.log('\nTest accounts created:');
    console.log('📧 john@example.com / password123');
    console.log('📧 jane@example.com / password123');
    console.log('\n� John and Jane are now linked as a couple');
    console.log('💬 They have a shared conversation with sample messages');
    console.log('\n�💡 Both accounts are ACTIVE and ready for testing');

  } catch (error) {
    if (error.name === 'ConditionalCheckFailedException') {
      console.log('⚠️  Some test data already exists. Run "npm run db:reset" first to start fresh.');
    } else {
      console.error('❌ Error seeding database:', error);
      process.exit(1);
    }
  }
}

// Run the seeding
seedDatabase().then(() => {
  console.log('✨ Seeding process completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Seeding failed:', error);
  process.exit(1);
});
