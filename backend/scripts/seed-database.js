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
        firstName: 'John',
        lastName: 'Doe',
        passwordHash: await bcrypt.hash('password123', 10),
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        userId: uuidv4(),
        email: 'jane@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
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

    // ========================================
    // Create SECOND test couple (Alex & Emma)
    // ========================================
    
    const users2 = [
      {
        userId: uuidv4(),
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Smith',
        passwordHash: await bcrypt.hash('password123', 10),
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        userId: uuidv4(),
        email: 'emma@example.com',
        firstName: 'Emma',
        lastName: 'Smith',
        passwordHash: await bcrypt.hash('password123', 10),
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ];

    const coupleId2 = uuidv4();
    const couple2 = {
      coupleId: coupleId2,
      user1Id: users2[0].userId,
      user2Id: users2[1].userId,
      status: 'active',
      subscriptionTier: 'premium',
      subscriptionStatus: 'active',
      aiMessagesUsed: 5,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    users2[0].partnerId = users2[1].userId;
    users2[0].coupleId = coupleId2;
    users2[1].partnerId = users2[0].userId;
    users2[1].coupleId = coupleId2;

    console.log('\n👥 Creating second test couple (Alex & Emma)...');
    for (const user of users2) {
      await dynamodb.send(new PutCommand({
        TableName: 'we-counsel-users',
        Item: user
      }));
      console.log(`   ✅ Created user: ${user.email}`);
      await delay(100);
    }

    await dynamodb.send(new PutCommand({
      TableName: 'we-counsel-couples',
      Item: couple2
    }));
    console.log('   ✅ Created couple relationship between Alex and Emma');

    // Create conversation with communication conflict
    const conversationId2 = uuidv4();
    const conversation2 = {
      conversationId: conversationId2,
      coupleId: coupleId2,
      user1Id: users2[0].userId,
      user2Id: users2[1].userId,
      title: 'Main Conversation',
      isMainThread: true,
      conversationType: 'main',
      isActive: true,
      messageCount: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await dynamodb.send(new PutCommand({
      TableName: 'we-counsel-conversations',
      Item: conversation2
    }));
    console.log('   ✅ Created conversation for Alex and Emma');

    // Messages showing communication breakdown (likely to trigger exercise suggestion)
    const messages2 = [
      {
        messageId: uuidv4(),
        conversationId: conversationId2,
        senderId: users2[0].userId,
        senderName: 'Alex Smith',
        senderType: 'user',
        content: "I feel like we keep having the same argument over and over. Every time I try to explain how I feel, it turns into a fight.",
        recipientType: 'both',
        timestamp: Date.now() - 7200000, // 2 hours ago
        createdAt: new Date(Date.now() - 7200000).toISOString()
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId2,
        senderId: users2[1].userId,
        senderName: 'Emma Smith',
        senderType: 'user',
        content: "That's because you never actually listen to what I'm saying! You just wait for your turn to talk.",
        recipientType: 'both',
        timestamp: Date.now() - 6900000,
        createdAt: new Date(Date.now() - 6900000).toISOString()
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId2,
        senderId: 'ai-coach',
        senderName: 'Coach Sarah (AI Relationship Coach)',
        senderType: 'ai',
        content: "💭 @Alex and @Emma, I hear frustration from both of you - Alex feeling unheard and Emma feeling like the listening isn't genuine. This is a really common pattern.\n\n🤔 Let me understand better: @Alex, when you say it turns into a fight, what usually happens first - does the tone shift, do interruptions start, or something else? And @Emma, when you feel like Alex is just waiting to talk, what would 'really listening' look like to you?\n\n💡 I'm noticing you both want the same thing - to feel heard - but you're stuck in a cycle where neither of you feels that's happening.",
        recipientType: 'both',
        timestamp: Date.now() - 6600000,
        createdAt: new Date(Date.now() - 6600000).toISOString()
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId2,
        senderId: users2[0].userId,
        senderName: 'Alex Smith',
        senderType: 'user',
        content: "Usually Emma raises her voice first and I get defensive. Then we're both just talking over each other.",
        recipientType: 'both',
        timestamp: Date.now() - 6300000,
        createdAt: new Date(Date.now() - 6300000).toISOString()
      },
      {
        messageId: uuidv4(),
        conversationId: conversationId2,
        senderId: users2[1].userId,
        senderName: 'Emma Smith',
        senderType: 'user',
        content: "I raise my voice because I feel like I'm being dismissed! And real listening would mean Alex actually reflecting back what I said instead of immediately defending himself.",
        recipientType: 'both',
        timestamp: Date.now() - 6000000,
        createdAt: new Date(Date.now() - 6000000).toISOString()
      }
    ];

    console.log('📝 Creating test messages for Alex and Emma (communication conflict)...');
    for (const message of messages2) {
      await dynamodb.send(new PutCommand({
        TableName: 'we-counsel-messages',
        Item: message
      }));
      await delay(100);
    }
    console.log(`   ✅ Created ${messages2.length} messages showing communication breakdown`);

    console.log('\n🎉 Database seeding completed successfully!');
    console.log('\nTest accounts created:');
    console.log('\nCouple 1 (General conversation):');
    console.log('📧 john@example.com / password123');
    console.log('📧 jane@example.com / password123');
    console.log('   💬 Casual conversation with some messages');
    console.log('\nCouple 2 (Communication conflict - will trigger exercise):');
    console.log('📧 alex@example.com / password123');
    console.log('📧 emma@example.com / password123');
    console.log('   💬 Active communication breakdown scenario');
    console.log('   ⚡ Next AI response likely to suggest Active Listening exercise');
    console.log('\n💡 All accounts are ACTIVE and ready for testing');

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
