#!/usr/bin/env node

/**
 * Database Setup Script
 * Creates DynamoDB tables for development using the migration manager
 * Run: npm run setup:db
 */

require('dotenv').config();
const MigrationManager = require('../src/database/migration-manager');

const setupDatabase = async () => {
  console.log('🗄️  Setting up database tables...');
  
  try {
    const config = {
      region: process.env.DYNAMODB_REGION || 'eu-west-3',
      ...(process.env.DYNAMODB_ENDPOINT && { endpoint: process.env.DYNAMODB_ENDPOINT }),
      billingMode: process.env.DYNAMODB_ENDPOINT ? 'PROVISIONED' : 'PAY_PER_REQUEST'
    };
    
    const manager = new MigrationManager(config);
    await manager.createAllTables();
    
    console.log('✅ Database setup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database setup failed:', error);
    process.exit(1);
  }
};

// Run setup if this script is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = { setupDatabase };
