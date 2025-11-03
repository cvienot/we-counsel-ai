require('dotenv').config();

// Load secrets FIRST before any other imports that need them
const { loadSecrets, validateSecrets } = require('./config/secrets');

// Main function to start server with async secret loading
async function startServer() {
  try {
    // Load secrets from AWS Secrets Manager (production only)
    await loadSecrets();
    
    // Validate all required secrets are present
    validateSecrets();

    // NOW import modules that depend on secrets
    const express = require('express');
    const cors = require('cors');
    const helmet = require('helmet');
    const morgan = require('morgan');

    const authRoutes = require('./routes/auth');
    const userRoutes = require('./routes/users');
    const conversationRoutes = require('./routes/conversations');
    const messageRoutes = require('./routes/messages');
    const streamingRoutes = require('./routes/streaming');

    const errorHandler = require('./middleware/errorHandler');
    const streamingService = require('./services/streamingService');

    const app = express();
    const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:8080',  // Flutter web dev server (primary)
    'http://localhost:8081',  // Flutter web dev server (secondary for testing)
    process.env.FRONTEND_URL
  ].filter(Boolean),
  credentials: true
}));

// Logging middleware
app.use(morgan('combined'));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'We Counsel API is running',
    timestamp: new Date().toISOString()
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/conversations', conversationRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/streaming', streamingRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Error handling middleware
app.use(errorHandler);

// Setup streaming service event handlers
streamingService.on('conversationMessage', async ({ conversationId, senderUserId, data }) => {
  try {
    // Get conversation details to find the partner
    const { docClient, TABLES } = require('./config/database');
    const params = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };
    
    const result = await docClient.get(params).promise();
    const conversation = result.Item;
    
    if (conversation && conversation.coupleId) {
      // Get all users in the couple
      const userParams = {
        TableName: TABLES.USERS,
        IndexName: 'couple-index',
        KeyConditionExpression: 'coupleId = :coupleId',
        ExpressionAttributeValues: {
          ':coupleId': conversation.coupleId
        }
      };
      
      const userResult = await docClient.query(userParams).promise();
      const users = userResult.Items;
      
      // Send to all users except the sender
      users.forEach(user => {
        if (user.userId !== senderUserId) {
          streamingService.sendToUser(user.userId, data);
        }
      });
    }
  } catch (error) {
    console.error('Error handling conversation message:', error);
  }
});

streamingService.on('typingUpdate', async ({ conversationId, userId, isTyping, typingUsers }) => {
  try {
    console.log(`🔔 TYPING UPDATE EVENT: conversationId=${conversationId}, userId=${userId}, isTyping=${isTyping}, typingUsers=[${typingUsers.join(', ')}]`);
    
    // Get conversation details to find the partner
    const { docClient, TABLES, GetCommand, QueryCommand } = require('./config/database');
    const params = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };
    
    const result = await docClient.send(new GetCommand(params));
    const conversation = result.Item;
    
    if (conversation && conversation.coupleId) {
      // Get all users in the couple
      const userParams = {
        TableName: TABLES.USERS,
        IndexName: 'couple-index',
        KeyConditionExpression: 'coupleId = :coupleId',
        ExpressionAttributeValues: {
          ':coupleId': conversation.coupleId
        }
      };
      
      const userResult = await docClient.send(new QueryCommand(userParams));
      const users = userResult.Items;
      
      // Send typing update to all users except the one who's typing
      users.forEach(user => {
        if (user.userId !== userId) {
          const typingData = {
            type: 'typing',
            conversationId,
            isTyping,
            userId,
            typingUsers: typingUsers.filter(id => id !== user.userId)
          };
          console.log(`📨 SENDING TYPING UPDATE to user ${user.userId}:`, typingData);
          streamingService.sendToUser(user.userId, typingData);
        } else {
          console.log(`🚫 SKIPPING typing update for sender ${user.userId}`);
        }
      });
    }
  } catch (error) {
    console.error('Error handling typing update:', error);
  }
});

// Cache for conversation participants to avoid repeated DB queries
const conversationParticipantsCache = new Map();

streamingService.on('aiStreamChunk', async ({ conversationId, messageId, chunk, isComplete }) => {
  try {
    let userIds = conversationParticipantsCache.get(conversationId);
    
    // If not cached, fetch from database
    if (!userIds) {
      const { docClient, TABLES, GetCommand, QueryCommand } = require('./config/database');
      const params = {
        TableName: TABLES.CONVERSATIONS,
        Key: { conversationId }
      };
      
      const result = await docClient.send(new GetCommand(params));
      const conversation = result.Item;
      
      if (conversation && conversation.coupleId) {
        // Get all users in the couple
        const userParams = {
          TableName: TABLES.USERS,
          IndexName: 'couple-index',
          KeyConditionExpression: 'coupleId = :coupleId',
          ExpressionAttributeValues: {
            ':coupleId': conversation.coupleId
          }
        };
        
        const userResult = await docClient.send(new QueryCommand(userParams));
        userIds = userResult.Items.map(user => user.userId);
        
        // Cache the user IDs
        conversationParticipantsCache.set(conversationId, userIds);
      }
    }
    
    // Send AI stream chunk to all users sequentially
    if (userIds && userIds.length > 0) {
      // Send to all users in parallel but await all sends
      await Promise.all(userIds.map(userId => 
        streamingService.sendToUser(userId, {
          type: 'aiStream',
          conversationId,
          messageId,
          chunk,
          isComplete
        })
      ));
    }
    
    // Clear cache when streaming completes
    if (isComplete) {
      conversationParticipantsCache.delete(conversationId);
    }
  } catch (error) {
    console.error('Error handling AI stream chunk:', error);
  }
});

streamingService.on('newMessage', async ({ conversationId, senderUserId, message }) => {
  try {
    // Get conversation details to find the partner
    const { docClient, TABLES, GetCommand, QueryCommand } = require('./config/database');
    const params = {
      TableName: TABLES.CONVERSATIONS,
      Key: { conversationId }
    };
    
    const result = await docClient.send(new GetCommand(params));
    const conversation = result.Item;
    
    if (conversation && conversation.coupleId) {
      // Get all users in the couple
      const userParams = {
        TableName: TABLES.USERS,
        IndexName: 'couple-index',
        KeyConditionExpression: 'coupleId = :coupleId',
        ExpressionAttributeValues: {
          ':coupleId': conversation.coupleId
        }
      };
      
      const userResult = await docClient.send(new QueryCommand(userParams));
      const users = userResult.Items;
      
      // Send new message to all users except the sender
      users.forEach(user => {
        if (user.userId !== senderUserId) {
          streamingService.sendToUser(user.userId, {
            type: 'newMessage',
            conversationId,
            message
          });
        }
      });
    }
  } catch (error) {
    console.error('Error handling new message:', error);
  }
});

    // Start server
    app.listen(PORT, () => {
      console.log(`🚀 We Counsel API server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
      console.log(`📡 Streaming service initialized`);
    });

    module.exports = app;
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();
