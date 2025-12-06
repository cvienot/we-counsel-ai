#!/usr/bin/env node

/**
 * Database CLI Tool
 * 
 * Usage:
 *   npm run db:create              # Create all tables
 *   npm run db:validate            # Validate schema
 *   npm run db:fix                 # Fix missing indexes
 *   npm run db:export              # Export schema as JSON
 * 
 * Environment variables:
 *   DYNAMODB_ENDPOINT - For local DynamoDB (e.g., http://localhost:8000)
 *   DYNAMODB_REGION   - AWS region (default: eu-west-3)
 *   TABLE_PREFIX      - Prefix for table names (e.g., dev, staging)
 */

const MigrationManager = require('../src/database/migration-manager');

const command = process.argv[2];

// Configuration
const config = {
  region: process.env.DYNAMODB_REGION || 'eu-west-3',
  ...(process.env.DYNAMODB_ENDPOINT && { endpoint: process.env.DYNAMODB_ENDPOINT }),
  billingMode: process.env.DYNAMODB_ENDPOINT ? 'PROVISIONED' : 'PAY_PER_REQUEST'
};

const tablePrefix = process.env.TABLE_PREFIX || '';

const manager = new MigrationManager(config);

async function main() {
  // Output configuration info
  if (command && command !== 'export') {
    console.log('📋 Configuration:');
    console.log(`   Region: ${config.region}`);
    console.log(`   Endpoint: ${config.endpoint || 'AWS DynamoDB (production)'}`);
    if (tablePrefix) {
      console.log(`   Table Prefix: ${tablePrefix}`);
    }
    console.log('');
  }

  try {
    switch (command) {
      case 'create':
        await manager.createAllTables(tablePrefix);
        break;
      
      case 'validate':
        await manager.validateAllTables(tablePrefix);
        break;
      
      case 'fix':
        await manager.fixAllTables(tablePrefix);
        break;
      
      case 'export':
        console.log(JSON.stringify(manager.exportSchema(), null, 2));
        break;
      
      default:
        console.log(`
Database CLI Tool

Usage:
  node scripts/db.js <command>

Commands:
  create      Create all tables from schema
  validate    Validate existing tables against schema
  fix         Add missing indexes to tables
  export      Export schema as JSON

Environment Variables:
  DYNAMODB_ENDPOINT    Local DynamoDB endpoint (e.g., http://localhost:8000)
  DYNAMODB_REGION      AWS region (default: eu-west-3)
  TABLE_PREFIX         Prefix for table names (optional)

Examples:
  # Create tables in AWS
  node scripts/db.js create

  # Validate local tables
  DYNAMODB_ENDPOINT=http://localhost:8000 node scripts/db.js validate

  # Fix production tables
  node scripts/db.js fix

  # Export schema
  node scripts/db.js export > schema.json
        `);
        process.exit(1);
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
