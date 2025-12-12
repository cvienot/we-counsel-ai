/**
 * Mock Email Service for Testing
 * Stores sent emails in memory for test assertions
 */

// In-memory storage for test assertions
global.mockEmailStore = global.mockEmailStore || [];

const sendInvitationEmail = async ({ to, inviterName, invitationId, message, language = 'en' }) => {
  const email = {
    type: 'invitation',
    to,
    inviterName,
    invitationId,
    message,
    language,
    sentAt: new Date().toISOString(),
    messageId: `mock-invitation-${Date.now()}-${Math.random()}`
  };
  
  global.mockEmailStore.push(email);
  console.log('📧 MOCK EMAIL (Invitation):', { to, inviterName, invitationId });
  
  return { MessageId: email.messageId };
};

const sendWelcomeEmail = async ({ to, firstName, email, language = 'en' }) => {
  const emailData = {
    type: 'welcome',
    to,
    firstName,
    email,
    language,
    sentAt: new Date().toISOString(),
    messageId: `mock-welcome-${Date.now()}-${Math.random()}`
  };
  
  global.mockEmailStore.push(emailData);
  console.log('📧 MOCK EMAIL (Welcome):', { to, firstName });
  
  return { MessageId: emailData.messageId };
};

const sendMessageNotification = async ({ to, recipientName, senderName, messagePreview, conversationId, language = 'en' }) => {
  const email = {
    type: 'messageNotification',
    to,
    recipientName,
    senderName,
    messagePreview,
    conversationId,
    language,
    sentAt: new Date().toISOString(),
    messageId: `mock-notification-${Date.now()}-${Math.random()}`
  };
  
  global.mockEmailStore.push(email);
  console.log('📧 MOCK EMAIL (Message Notification):', { to, senderName, messagePreview: messagePreview.substring(0, 50) });
  
  return { MessageId: email.messageId };
};

module.exports = {
  sendInvitationEmail,
  sendWelcomeEmail,
  sendMessageNotification
};
