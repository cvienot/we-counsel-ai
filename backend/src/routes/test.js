const express = require('express');
const router = express.Router();

/**
 * Testing endpoints - only available when ENABLE_TEST_ENDPOINTS=true
 * These endpoints allow E2E tests to verify mock behavior
 */

if (process.env.ENABLE_TEST_ENDPOINTS === 'true') {
  // Get all mock emails sent
  router.get('/emails', (req, res) => {
    res.json({
      success: true,
      emails: global.mockEmailStore || [],
      count: (global.mockEmailStore || []).length
    });
  });

  // Get mock emails filtered by type
  router.get('/emails/:type', (req, res) => {
    const { type } = req.params;
    const filtered = (global.mockEmailStore || []).filter(email => email.type === type);
    
    res.json({
      success: true,
      emails: filtered,
      count: filtered.length
    });
  });

  // Get all mock AI responses
  router.get('/ai-responses', (req, res) => {
    res.json({
      success: true,
      responses: global.mockAIStore || [],
      count: (global.mockAIStore || []).length
    });
  });

  // Reset all mock stores
  router.post('/reset', (req, res) => {
    global.mockEmailStore = [];
    global.mockAIStore = [];
    
    res.json({
      success: true,
      message: 'All mock stores reset'
    });
  });

  // Get test environment status
  router.get('/status', (req, res) => {
    res.json({
      success: true,
      environment: {
        mockEmail: process.env.MOCK_EMAIL === 'true',
        mockAI: process.env.MOCK_AI === 'true',
        dynamodbEndpoint: process.env.DYNAMODB_ENDPOINT || 'AWS',
        nodeEnv: process.env.NODE_ENV
      },
      stores: {
        emailCount: (global.mockEmailStore || []).length,
        aiResponseCount: (global.mockAIStore || []).length
      }
    });
  });

  console.log('✅ Test endpoints enabled at /api/test/*');
} else {
  // Return 404 if test endpoints are not enabled
  router.use('*', (req, res) => {
    res.status(404).json({
      error: 'Test endpoints not enabled',
      message: 'Set ENABLE_TEST_ENDPOINTS=true to enable test endpoints'
    });
  });
}

module.exports = router;
