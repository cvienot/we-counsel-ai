#!/usr/bin/env node

/**
 * Database Reset Script
 * Drops and recreates DynamoDB tables for development
 * Run: npm run reset:db
 */

require('dotenv').config();
const AWS = require('aws-sdk');

// Configure DynamoDB (same as in database.js)
const dynamoConfig = {
  region: process.env.DYNAMODB_REGION || 'us-east-1'
};

if (process.env.NODE_ENV === 'development') {
  dynamoConfig.endpoint = process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
  dynamoConfig.accessKeyId = 'local';
  dynamoConfig.secretAccessKey = 'local';
}

const dynamodb = new AWS.DynamoDB(dynamoConfig);

// Table names
const TABLES = {
  USERS: 'we-counsel-users',
  COUPLES: 'we-counsel-couples', 
  CONVERSATIONS: 'we-counsel-conversations',
  MESSAGES: 'we-counsel-messages',
  INVITATIONS: 'we-counsel-invitations'
};

const resetDatabase = async () => {
  console.log('🗑️  Resetting database tables...');
  
  try {
    // Delete all tables
    const tableNames = Object.values(TABLES);
    for (const tableName of tableNames) {
      try {
        await dynamodb.deleteTable({ TableName: tableName }).promise();
        console.log(`🗑️  Deleted table: ${tableName}`);
      } catch (error) {
        if (error.code === 'ResourceNotFoundException') {
          console.log(`⚠️  Table does not exist: ${tableName}`);
        } else {
          throw error;
        }
      }
    }

    // Wait a moment for tables to be deleted
    console.log('⏳ Waiting for tables to be deleted...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Recreate tables
    const { createTables } = require('../src/config/database');
    await createTables();
    
    console.log('✅ Database reset completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database reset failed:', error);
    process.exit(1);
  }
};

// Run reset if this script is executed directly
if (require.main === module) {
  resetDatabase();
}

module.exports = { resetDatabase };
