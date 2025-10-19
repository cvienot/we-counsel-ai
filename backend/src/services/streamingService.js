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

  // Send message to specific user(s) - returns Promise for sequential writes
  sendToUser(userId, data) {
    return new Promise((resolve) => {
      if (this.connections.has(userId)) {
        const connections = this.connections.get(userId);
        const message = `data: ${JSON.stringify(data)}\n\n`;
        
        let writePromises = [];
        connections.forEach(res => {
          try {
            // res.write returns false if the internal buffer is full
            const needsDrain = !res.write(message);
            
            if (needsDrain) {
              // Wait for drain event before continuing
              writePromises.push(new Promise(drainResolve => {
                res.once('drain', drainResolve);
              }));
            }
          } catch (error) {
            console.error('Error sending message to user:', error);
            this.removeConnection(userId, res);
          }
        });
        
        // Wait for all drains to complete, then resolve
        if (writePromises.length > 0) {
          Promise.all(writePromises).then(resolve);
        } else {
          // If no drains needed, resolve immediately with setImmediate
          setImmediate(resolve);
        }
      } else {
        resolve();
      }
    });
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
      
      // Clear any existing timeout
      if (this.typingTimeouts.has(userId)) {
        clearTimeout(this.typingTimeouts.get(userId));
      }
      
      // Set a long fallback timeout (30 seconds) only as a safety measure
      // The client should handle stopping typing based on input content
      const timeout = setTimeout(() => {
        console.log(`⏰ Typing timeout reached for user ${userId} in conversation ${conversationId}`);
        this.setTyping(conversationId, userId, false);
      }, 30000);
      
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

  // Stream AI response chunks - returns Promise to ensure sequential processing
  async streamAIResponse(conversationId, messageId, chunk, isComplete = false) {
    // Create a promise that will be resolved by the event handler
    const eventData = {
      conversationId,
      messageId,
      chunk,
      isComplete,
      timestamp: Date.now()
    };
    
    // Emit the event and wait for async handlers
    const listeners = this.listeners('aiStreamChunk');
    
    if (listeners.length > 0) {
      // Call all listeners and wait for them to complete
      await Promise.all(listeners.map(listener => listener(eventData)));
    }
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
