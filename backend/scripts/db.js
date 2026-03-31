#!/usr/bin/env node

/**
 * Database CLI Tool — Single source of truth for database management
 * 
 * Usage:
 *   npm run db <command>
 * 
 * Commands:
 *   sync        Validate schema and fix any issues (create missing tables, add missing indexes)
 *   validate    Validate schema without making changes
 *   create      Create all tables from schema (skip if exist)
 *   reset       Drop and recreate all tables (local/dev only)
 *   export      Export schema as JSON
 * 
 * Environment variables:
 *   DYNAMODB_ENDPOINT - For local DynamoDB (e.g., http://localhost:8000)
 *   DYNAMODB_REGION   - AWS region (default: eu-west-3)
 *   TABLE_PREFIX      - Prefix for table names (e.g., dev, staging)
 */

require('dotenv').config();
const { DynamoDBClient, DeleteTableCommand, DescribeTableCommand } = require('@aws-sdk/client-dynamodb');
const MigrationManager = require('../src/database/migration-manager');
const schema = require('../src/database/schema');

const command = process.argv[2];

// Configuration
const config = {
  region: process.env.DYNAMODB_REGION || 'eu-west-3',
  ...(process.env.DYNAMODB_ENDPOINT && { endpoint: process.env.DYNAMODB_ENDPOINT }),
  billingMode: process.env.DYNAMODB_ENDPOINT ? 'PROVISIONED' : 'PAY_PER_REQUEST'
};

const tablePrefix = process.env.TABLE_PREFIX || '';
const manager = new MigrationManager(config);

function printConfig() {
  console.log('📋 Configuration:');
  console.log(`   Region: ${config.region}`);
  console.log(`   Endpoint: ${config.endpoint || 'AWS DynamoDB (production)'}`);
  console.log(`   Schema version: ${schema.SCHEMA_VERSION}`);
  if (tablePrefix) console.log(`   Table Prefix: ${tablePrefix}`);
  console.log('');
}

async function sync() {
  printConfig();
  console.log('🔄 Syncing database schema...\n');
  
  const tableKeys = Object.keys(schema.tables);
  let created = 0, fixed = 0, valid = 0;

  for (const tableKey of tableKeys) {
    const validation = await manager.validateTable(tableKey, tablePrefix);
    
    if (validation.issues.some(i => i.type === 'table_not_found')) {
      // Table missing — create it
      await manager.createTable(tableKey, tablePrefix);
      created++;
    } else if (!validation.valid) {
      // Table exists but has issues — fix missing indexes
      await manager.addMissingIndexes(tableKey, tablePrefix);
      fixed++;
    } else {
      valid++;
    }
  }

  console.log(`\n✅ Sync complete: ${valid} valid, ${created} created, ${fixed} fixed\n`);
}

async function validate() {
  printConfig();
  const results = await manager.validateAllTables(tablePrefix);
  const allValid = Object.values(results).every(r => r.valid);
  process.exit(allValid ? 0 : 1);
}

async function create() {
  printConfig();
  await manager.createAllTables(tablePrefix);
}

async function reset() {
  // Safety: only allow reset if using local endpoint or explicitly confirmed
  if (!config.endpoint) {
    console.error('❌ Reset is only allowed with a local DynamoDB endpoint.');
    console.error('   Set DYNAMODB_ENDPOINT to use reset, or delete tables manually in production.');
    process.exit(1);
  }

  printConfig();
  console.log('🗑️  Resetting all tables...\n');

  const client = new DynamoDBClient({
    region: config.region,
    ...(config.endpoint && { endpoint: config.endpoint })
  });

  // Delete all tables from schema
  const tableKeys = Object.keys(schema.tables);
  
  for (const tableKey of tableKeys) {
    const tableName = tablePrefix 
      ? `${tablePrefix}-${schema.tables[tableKey].tableName}` 
      : schema.tables[tableKey].tableName;
    
    try {
      await client.send(new DeleteTableCommand({ TableName: tableName }));
      console.log(`   🗑️  Deleted: ${tableName}`);
    } catch (error) {
      if (error.name === 'ResourceNotFoundException') {
        console.log(`   ⚠️  Not found: ${tableName}`);
      } else {
        throw error;
      }
    }
  }

  console.log('\n⏳ Waiting for tables to be deleted...');
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Recreate all tables
  await manager.createAllTables(tablePrefix);
  console.log('✅ Database reset complete\n');
}

function exportSchema() {
  console.log(JSON.stringify(manager.exportSchema(), null, 2));
}

async function main() {
  try {
    switch (command) {
      case 'sync':      await sync(); break;
      case 'validate':  await validate(); break;
      case 'create':    await create(); break;
      case 'reset':     await reset(); break;
      case 'export':    exportSchema(); break;
      default:
        console.log(`
Database CLI Tool

Usage:
  node scripts/db.js <command>

Commands:
  sync        Validate and fix schema (create missing tables, add missing indexes)
  validate    Validate existing tables against schema (exit 1 if issues found)
  create      Create all tables from schema (skip existing)
  reset       Drop and recreate all tables (local DynamoDB only)
  export      Export schema as JSON

Environment Variables:
  DYNAMODB_ENDPOINT    Local DynamoDB endpoint (e.g., http://localhost:8000)
  DYNAMODB_REGION      AWS region (default: eu-west-3)
  TABLE_PREFIX         Prefix for table names (optional)

Examples:
  node scripts/db.js sync                                          # Sync production
  DYNAMODB_ENDPOINT=http://localhost:8000 node scripts/db.js sync  # Sync local
  DYNAMODB_ENDPOINT=http://localhost:8000 node scripts/db.js reset # Reset local
  node scripts/db.js export > schema.json                          # Export
`);
        process.exit(1);
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
