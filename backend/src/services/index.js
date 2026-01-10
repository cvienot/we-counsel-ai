/**
 * Service Loader
 * Conditionally loads mock or real services based on environment variables
 */

function loadEmailService() {
  if (process.env.MOCK_EMAIL === 'true') {
    console.log('📧 Loading MOCK email service');
    return require('./__mocks__/emailService');
  }
  console.log('📧 Loading REAL email service');
  return require('./emailService');
}

function loadAIService() {
  if (process.env.MOCK_AI === 'true') {
    console.log('🤖 Loading MOCK AI service');
    return require('./__mocks__/aiService');
  }
  console.log('🤖 Loading REAL AI service');
  return require('./aiService');
}

function loadStripeService() {
  if (process.env.MOCK_STRIPE === 'true') {
    console.log('💳 Loading MOCK Stripe service');
    return require('./__mocks__/stripeService');
  }
  console.log('💳 Loading REAL Stripe service');
  return require('./stripeService');
}

module.exports = {
  emailService: loadEmailService(),
  aiService: loadAIService(),
  stripeService: loadStripeService()
};
