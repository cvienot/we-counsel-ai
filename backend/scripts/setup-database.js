#!/usr/bin/env node

/**
 * Database Setup Script
 * Creates DynamoDB tables for development
 * Run: npm run setup:db
 */

require('dotenv').config();
const { createTables } = require('../src/config/database');

const setupDatabase = async () => {
  console.log('🗄️  Setting up database tables...');
  
  try {
    await createTables();
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
