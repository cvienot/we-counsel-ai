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

const sendSignupNotificationEmail = async ({ to, user }) => {
  const email = {
    type: 'signupNotification',
    to,
    user: {
      userId: user.userId,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      language: user.language,
      selectedPlan: user.selectedPlan,
      createdAt: user.createdAt,
      landingPage: user.landingPage,
      referrer: user.referrer,
      firstTouchUtm: user.firstTouchUtm,
      lastTouchUtm: user.lastTouchUtm,
      firstTouchAdParams: user.firstTouchAdParams,
      lastTouchAdParams: user.lastTouchAdParams
    },
    sentAt: new Date().toISOString(),
    messageId: `mock-signup-notification-${Date.now()}-${Math.random()}`
  };

  global.mockEmailStore.push(email);
  console.log('📧 MOCK EMAIL (Signup Notification):', { to, userEmail: user.email });

  return { MessageId: email.messageId };
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

const sendPasswordResetEmail = async ({ to, resetToken, language = 'en' }) => {
  const email = {
    type: 'passwordReset',
    to,
    resetToken,
    language,
    sentAt: new Date().toISOString(),
    messageId: `mock-password-reset-${Date.now()}-${Math.random()}`
  };
  
  global.mockEmailStore.push(email);
  console.log('📧 MOCK EMAIL (Password Reset):', { to });
  
  return { MessageId: email.messageId };
};

module.exports = {
  sendInvitationEmail,
  sendWelcomeEmail,
  sendSignupNotificationEmail,
  sendMessageNotification,
  sendPasswordResetEmail
};
