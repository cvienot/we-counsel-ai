const { EventEmitter } = require('events');

class StreamingService extends EventEmitter {
  constructor() {
    super();
    this.connections = new Map(); // userId -> Set of response objects
    this.typingUsers = new Map(); // conversationId -> Set of userIds
    this.typingTimeouts = new Map(); // userId -> timeout
  }

  // Add a client connection for SSE
  addConnection(userId, res) {
    if (!this.connections.has(userId)) {
      this.connections.set(userId, new Set());
    }
    this.connections.get(userId).add(res);

    // Setup SSE headers
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Cache-Control'
    });

    // Send initial connection confirmation
    res.write(`data: ${JSON.stringify({ type: 'connected', timestamp: Date.now() })}\n\n`);

    // Handle client disconnect
    res.on('close', () => {
      this.removeConnection(userId, res);
    });

    console.log(`SSE connection established for user: ${userId}`);
  }

  // Remove a client connection
  removeConnection(userId, res) {
    if (this.connections.has(userId)) {
      this.connections.get(userId).delete(res);
      if (this.connections.get(userId).size === 0) {
        this.connections.delete(userId);
      }
    }
    console.log(`SSE connection closed for user: ${userId}`);
  }

  // Send message to specific user(s)
  sendToUser(userId, data) {
    if (this.connections.has(userId)) {
      const connections = this.connections.get(userId);
      const message = `data: ${JSON.stringify(data)}\n\n`;
      
      connections.forEach(res => {
        try {
          res.write(message);
        } catch (error) {
          console.error('Error sending message to user:', error);
          this.removeConnection(userId, res);
        }
      });
    }
  }

  // Send message to all users in a conversation
  sendToConversation(conversationId, senderUserId, data) {
    // We'll need to get the partner's userId from the conversation
    // For now, we'll emit an event that the conversation route can handle
    this.emit('conversationMessage', {
      conversationId,
      senderUserId,
      data
    });
  }

  // Handle typing indicators
  setTyping(conversationId, userId, isTyping) {
    if (!this.typingUsers.has(conversationId)) {
      this.typingUsers.set(conversationId, new Set());
    }

    const typingSet = this.typingUsers.get(conversationId);
    
    if (isTyping) {
      typingSet.add(userId);
      
      // Clear existing timeout
      if (this.typingTimeouts.has(userId)) {
        clearTimeout(this.typingTimeouts.get(userId));
      }
      
      // Set timeout to automatically stop typing after 3 seconds
      const timeout = setTimeout(() => {
        this.setTyping(conversationId, userId, false);
      }, 3000);
      
      this.typingTimeouts.set(userId, timeout);
    } else {
      typingSet.delete(userId);
      
      // Clear timeout
      if (this.typingTimeouts.has(userId)) {
        clearTimeout(this.typingTimeouts.get(userId));
        this.typingTimeouts.delete(userId);
      }
    }

    // Notify other users in the conversation about typing status
    this.emit('typingUpdate', {
      conversationId,
      userId,
      isTyping,
      typingUsers: Array.from(typingSet)
    });
  }

  // Stream AI response chunks
  streamAIResponse(conversationId, messageId, chunk, isComplete = false) {
    this.emit('aiStreamChunk', {
      conversationId,
      messageId,
      chunk,
      isComplete,
      timestamp: Date.now()
    });
  }

  // Send new message notification
  sendMessageNotification(conversationId, senderUserId, message) {
    this.emit('newMessage', {
      conversationId,
      senderUserId,
      message,
      timestamp: Date.now()
    });
  }
}

// Create singleton instance
const streamingService = new StreamingService();

module.exports = streamingService;
