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
 * Validate that all required secrets are present
 */
function validateSecrets() {
  const required = [
    'JWT_SECRET',
    'OPENAI_API_KEY',
    'AWS_REGION',
    'DYNAMODB_REGION',
    'EMAIL_FROM'
  ];

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.error('❌ Missing required environment variables:');
    missing.forEach(key => console.error(`   - ${key}`));
    throw new Error(`Missing required secrets: ${missing.join(', ')}`);
  }

  console.log('✅ All required secrets are present');
}

module.exports = {
  loadSecrets,
  loadSpecificSecret,
  validateSecrets,
  getSecret
};
