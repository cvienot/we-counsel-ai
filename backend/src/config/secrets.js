const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

/**
 * Secrets Manager Configuration
 * 
 * This module handles loading secrets from AWS Secrets Manager in production
 * and falls back to environment variables in development.
 * 
 * Usage:
 *   const { loadSecrets } = require('./config/secrets');
 *   await loadSecrets();
 *   // Now process.env contains all secrets
 */

const client = new SecretsManagerClient({
  region: process.env.AWS_REGION || process.env.DYNAMODB_REGION || 'eu-west-3'
});

/**
 * Load secrets from AWS Secrets Manager
 * @param {string} secretName - Name of the secret to load
 * @returns {Promise<Object>} - Parsed secret object
 */
async function getSecret(secretName) {
  try {
    const command = new GetSecretValueCommand({
      SecretId: secretName
    });
    
    const response = await client.send(command);
    
    if (response.SecretString) {
      return JSON.parse(response.SecretString);
    }
    
    throw new Error('Secret does not contain string data');
  } catch (error) {
    if (error.name === 'ResourceNotFoundException') {
      console.warn(`⚠️  Secret ${secretName} not found in Secrets Manager`);
    } else {
      console.error(`❌ Error retrieving secret ${secretName}:`, error.message);
    }
    throw error;
  }
}

/**
 * Load all application secrets and merge into process.env
 * Only runs in production mode
 */
async function loadSecrets() {
  // Skip in development - use .env file
  if (process.env.NODE_ENV !== 'production') {
    console.log('📝 Development mode: Using .env file for configuration');
    return;
  }

  console.log('🔐 Production mode: Loading secrets from AWS Secrets Manager...');

  try {
    // Load main application secrets bundle
    const secrets = await getSecret('we-counsel/application/secrets');
    
    // Merge secrets into process.env (only if not already set)
    Object.keys(secrets).forEach(key => {
      if (!process.env[key]) {
        process.env[key] = secrets[key];
      }
    });

    console.log('✅ Secrets loaded successfully from Secrets Manager');
    
    // Log which secrets were loaded (without values!)
    console.log('📦 Loaded secrets:', Object.keys(secrets).join(', '));
    
  } catch (error) {
    console.error('❌ Failed to load secrets from Secrets Manager');
    console.error('⚠️  Falling back to environment variables');
    
    // In production, this is a critical error
    if (process.env.NODE_ENV === 'production') {
      console.error('💥 Cannot start without secrets in production mode');
      throw error;
    }
  }
}

/**
 * Load a specific secret by name
 * @param {string} secretName - Name of the secret
 * @returns {Promise<Object>} - Secret value
 */
async function loadSpecificSecret(secretName) {
  try {
    return await getSecret(secretName);
  } catch (error) {
    console.error(`Failed to load secret: ${secretName}`);
    throw error;
  }
}

/**
 * Validate that all required configuration is present
 */
function validateSecrets() {
  const required = [
    'JWT_SECRET',      // From Secrets Manager
    'OPENAI_API_KEY',  // From Secrets Manager
    'AWS_REGION',      // From environment variables
    'DYNAMODB_REGION', // From environment variables
    'EMAIL_FROM'       // From environment variables
  ];

  const productionRequired = [
    'STRIPE_SECRET_KEY',
    'STRIPE_WEBHOOK_SECRET',
    'STRIPE_PRICE_ESSENTIAL_MONTHLY',
    'STRIPE_PRICE_ESSENTIAL_ANNUAL',
    'STRIPE_PRICE_PREMIUM_MONTHLY',
    'STRIPE_PRICE_PREMIUM_ANNUAL'
  ];

  if (process.env.NODE_ENV === 'production') {
    required.push(...productionRequired);
  }

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.error('❌ Missing required configuration:');
    missing.forEach(key => console.error(`   - ${key}`));
    throw new Error(`Missing required configuration: ${missing.join(', ')}`);
  }

  if (process.env.NODE_ENV === 'production') {
    validateProductionSafety();
  }

  console.log('✅ All required configuration is present');
  console.log('   📦 Non-sensitive: AWS_REGION, DYNAMODB_REGION, EMAIL_FROM, SIGNUP_NOTIFICATION_EMAIL, FRONTEND_URL, NODE_ENV');
  console.log('   🔒 Sensitive (from Secrets Manager): JWT_SECRET, OPENAI_API_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET');
  console.log('   💳 Stripe price IDs configured for Essential and Premium monthly/annual plans');
}

function validateProductionSafety() {
  const unsafeFlags = [
    'ENABLE_TEST_ENDPOINTS',
    'MOCK_STRIPE',
    'MOCK_EMAIL',
    'MOCK_AI',
    'USE_MOCK_EMAIL',
    'USE_MOCK_AI'
  ].filter(key => process.env[key] === 'true');

  if (unsafeFlags.length > 0) {
    throw new Error(`Unsafe production flags enabled: ${unsafeFlags.join(', ')}`);
  }

  if (!process.env.FRONTEND_URL || process.env.FRONTEND_URL.includes('localhost')) {
    throw new Error('FRONTEND_URL must be set to the production app URL in production');
  }

  if (!process.env.STRIPE_SECRET_KEY.startsWith('sk_live_') && !process.env.STRIPE_SECRET_KEY.startsWith('rk_live_')) {
    throw new Error('STRIPE_SECRET_KEY must be a live Stripe secret or restricted key in production');
  }

  if (!process.env.STRIPE_WEBHOOK_SECRET.startsWith('whsec_')) {
    throw new Error('STRIPE_WEBHOOK_SECRET must be a Stripe webhook signing secret');
  }

  [
    'STRIPE_PRICE_ESSENTIAL_MONTHLY',
    'STRIPE_PRICE_ESSENTIAL_ANNUAL',
    'STRIPE_PRICE_PREMIUM_MONTHLY',
    'STRIPE_PRICE_PREMIUM_ANNUAL'
  ].forEach(key => {
    if (!process.env[key].startsWith('price_')) {
      throw new Error(`${key} must be a Stripe price ID`);
    }
  });
}

module.exports = {
  loadSecrets,
  loadSpecificSecret,
  validateSecrets,
  getSecret
};
