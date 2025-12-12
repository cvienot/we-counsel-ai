/**
 * Database Migration Manager
 * 
 * Handles creation, validation, and migration of database schema
 * across different environments and providers.
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { 
  CreateTableCommand, 
  DescribeTableCommand, 
  UpdateTableCommand,
  ListTablesCommand 
} = require('@aws-sdk/client-dynamodb');
const schema = require('./schema');

class MigrationManager {
  constructor(config = {}) {
    this.client = new DynamoDBClient({
      region: config.region || process.env.DYNAMODB_REGION || 'eu-west-3',
      ...(config.endpoint && { endpoint: config.endpoint })
    });
    this.billingMode = config.billingMode || 'PAY_PER_REQUEST';
  }

  /**
   * Get table name with optional prefix for different environments
   */
  getTableName(schemaTableName, prefix = '') {
    return prefix ? `${prefix}-${schemaTableName}` : schemaTableName;
  }

  /**
   * Create DynamoDB table from schema definition
   */
  async createTable(tableKey, tablePrefix = '') {
    const tableSchema = schema.tables[tableKey];
    if (!tableSchema) {
      throw new Error(`Table schema not found: ${tableKey}`);
    }

    const tableName = this.getTableName(tableSchema.tableName, tablePrefix);
    
    // Build attribute definitions from primary key and GSI keys
    const attributeDefinitions = new Set();
    
    // Add primary key attributes
    attributeDefinitions.add({
      AttributeName: tableSchema.primaryKey.partitionKey.name,
      AttributeType: tableSchema.primaryKey.partitionKey.type
    });
    
    if (tableSchema.primaryKey.sortKey) {
      attributeDefinitions.add({
        AttributeName: tableSchema.primaryKey.sortKey.name,
        AttributeType: tableSchema.primaryKey.sortKey.type
      });
    }

    // Add GSI key attributes
    tableSchema.globalSecondaryIndexes.forEach(gsi => {
      attributeDefinitions.add({
        AttributeName: gsi.keys.partitionKey.name,
        AttributeType: gsi.keys.partitionKey.type
      });
      
      if (gsi.keys.sortKey) {
        attributeDefinitions.add({
          AttributeName: gsi.keys.sortKey.name,
          AttributeType: gsi.keys.sortKey.type
        });
      }
    });

    // Convert Set to Array and remove duplicates by name
    const uniqueAttributes = Array.from(attributeDefinitions).reduce((acc, attr) => {
      if (!acc.find(a => a.AttributeName === attr.AttributeName)) {
        acc.push(attr);
      }
      return acc;
    }, []);

    // Build key schema
    const keySchema = [
      {
        AttributeName: tableSchema.primaryKey.partitionKey.name,
        KeyType: 'HASH'
      }
    ];
    
    if (tableSchema.primaryKey.sortKey) {
      keySchema.push({
        AttributeName: tableSchema.primaryKey.sortKey.name,
        KeyType: 'RANGE'
      });
    }

    // Build GSIs
    const globalSecondaryIndexes = tableSchema.globalSecondaryIndexes.map(gsi => {
      const gsiKeySchema = [
        {
          AttributeName: gsi.keys.partitionKey.name,
          KeyType: 'HASH'
        }
      ];
      
      if (gsi.keys.sortKey) {
        gsiKeySchema.push({
          AttributeName: gsi.keys.sortKey.name,
          KeyType: 'RANGE'
        });
      }

      const gsiDef = {
        IndexName: gsi.indexName,
        KeySchema: gsiKeySchema,
        Projection: { ProjectionType: gsi.projection }
      };

      // Add provisioned throughput for DynamoDB Local (PROVISIONED mode)
      if (this.billingMode === 'PROVISIONED') {
        gsiDef.ProvisionedThroughput = {
          ReadCapacityUnits: 5,
          WriteCapacityUnits: 5
        };
      }

      return gsiDef;
    });

    const params = {
      TableName: tableName,
      AttributeDefinitions: uniqueAttributes,
      KeySchema: keySchema,
      BillingMode: this.billingMode,
      ...(globalSecondaryIndexes.length > 0 && { GlobalSecondaryIndexes: globalSecondaryIndexes })
    };

    // Add provisioned throughput for PROVISIONED billing mode
    if (this.billingMode === 'PROVISIONED') {
      params.ProvisionedThroughput = {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5
      };
    }

    try {
      const command = new CreateTableCommand(params);
      const result = await this.client.send(command);
      console.log(`✅ Created table: ${tableName}`);
      return result;
    } catch (error) {
      if (error.name === 'ResourceInUseException') {
        console.log(`ℹ️  Table already exists: ${tableName}`);
        return null;
      }
      throw error;
    }
  }

  /**
   * Validate that a table matches the schema
   */
  async validateTable(tableKey, tablePrefix = '') {
    const tableSchema = schema.tables[tableKey];
    const tableName = this.getTableName(tableSchema.tableName, tablePrefix);

    try {
      const command = new DescribeTableCommand({ TableName: tableName });
      const result = await this.client.send(command);
      const table = result.Table;

      const issues = [];

      // Check GSIs
      const schemaGSIs = tableSchema.globalSecondaryIndexes.map(g => g.indexName).sort();
      const actualGSIs = (table.GlobalSecondaryIndexes || []).map(g => g.IndexName).sort();
      
      const missingGSIs = schemaGSIs.filter(g => !actualGSIs.includes(g));
      const extraGSIs = actualGSIs.filter(g => !schemaGSIs.includes(g));

      if (missingGSIs.length > 0) {
        issues.push({ type: 'missing_gsi', indexes: missingGSIs });
      }
      
      if (extraGSIs.length > 0) {
        issues.push({ type: 'extra_gsi', indexes: extraGSIs });
      }

      if (issues.length === 0) {
        console.log(`✅ ${tableName}: Schema valid`);
        return { valid: true, issues: [] };
      } else {
        console.log(`⚠️  ${tableName}: Schema mismatch`);
        issues.forEach(issue => {
          if (issue.type === 'missing_gsi') {
            console.log(`   Missing GSIs: ${issue.indexes.join(', ')}`);
          }
          if (issue.type === 'extra_gsi') {
            console.log(`   Extra GSIs: ${issue.indexes.join(', ')}`);
          }
        });
        return { valid: false, issues };
      }
    } catch (error) {
      if (error.name === 'ResourceNotFoundException') {
        console.log(`❌ ${tableName}: Table does not exist`);
        return { valid: false, issues: [{ type: 'table_not_found' }] };
      }
      throw error;
    }
  }

  /**
   * Add missing GSIs to an existing table
   */
  async addMissingIndexes(tableKey, tablePrefix = '') {
    const validation = await this.validateTable(tableKey, tablePrefix);
    
    if (validation.valid) {
      console.log(`No missing indexes for ${tableKey}`);
      return;
    }

    const missingGSIIssue = validation.issues.find(i => i.type === 'missing_gsi');
    if (!missingGSIIssue) {
      console.log(`No missing GSIs to add for ${tableKey}`);
      return;
    }

    const tableSchema = schema.tables[tableKey];
    const tableName = this.getTableName(tableSchema.tableName, tablePrefix);

    // Add each missing GSI one at a time (DynamoDB limitation)
    for (const indexName of missingGSIIssue.indexes) {
      const gsiSchema = tableSchema.globalSecondaryIndexes.find(g => g.indexName === indexName);
      
      if (!gsiSchema) continue;

      // Build attribute definitions for this GSI
      const attributeDefinitions = [
        {
          AttributeName: gsiSchema.keys.partitionKey.name,
          AttributeType: gsiSchema.keys.partitionKey.type
        }
      ];

      if (gsiSchema.keys.sortKey) {
        attributeDefinitions.push({
          AttributeName: gsiSchema.keys.sortKey.name,
          AttributeType: gsiSchema.keys.sortKey.type
        });
      }

      // Build key schema
      const keySchema = [
        {
          AttributeName: gsiSchema.keys.partitionKey.name,
          KeyType: 'HASH'
        }
      ];

      if (gsiSchema.keys.sortKey) {
        keySchema.push({
          AttributeName: gsiSchema.keys.sortKey.name,
          KeyType: 'RANGE'
        });
      }

      const params = {
        TableName: tableName,
        AttributeDefinitions: attributeDefinitions,
        GlobalSecondaryIndexUpdates: [
          {
            Create: {
              IndexName: indexName,
              KeySchema: keySchema,
              Projection: { ProjectionType: gsiSchema.projection }
            }
          }
        ]
      };

      try {
        const command = new UpdateTableCommand(params);
        await this.client.send(command);
        console.log(`✅ Added GSI ${indexName} to ${tableName}`);
        
        // Wait for index to become active before adding next one
        await this.waitForIndexActive(tableName, indexName);
      } catch (error) {
        console.error(`❌ Failed to add GSI ${indexName}:`, error.message);
      }
    }
  }

  /**
   * Wait for GSI to become ACTIVE
   */
  async waitForIndexActive(tableName, indexName, maxAttempts = 60) {
    for (let i = 0; i < maxAttempts; i++) {
      const command = new DescribeTableCommand({ TableName: tableName });
      const result = await this.client.send(command);
      
      const gsi = result.Table.GlobalSecondaryIndexes?.find(g => g.IndexName === indexName);
      
      if (gsi && gsi.IndexStatus === 'ACTIVE') {
        console.log(`✅ GSI ${indexName} is now ACTIVE`);
        return true;
      }
      
      console.log(`   Waiting for ${indexName} to become ACTIVE... (${i + 1}/${maxAttempts})`);
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
    
    throw new Error(`Timeout waiting for ${indexName} to become ACTIVE`);
  }

  /**
   * Create all tables from schema
   */
  async createAllTables(tablePrefix = '') {
    console.log(`\n🚀 Creating all tables (schema version: ${schema.SCHEMA_VERSION})\n`);
    
    const tableKeys = Object.keys(schema.tables);
    
    for (const tableKey of tableKeys) {
      await this.createTable(tableKey, tablePrefix);
    }
    
    console.log('\n✅ All tables created\n');
  }

  /**
   * Validate all tables
   */
  async validateAllTables(tablePrefix = '') {
    console.log(`\n🔍 Validating all tables (schema version: ${schema.SCHEMA_VERSION})\n`);
    
    const tableKeys = Object.keys(schema.tables);
    const results = {};
    
    for (const tableKey of tableKeys) {
      results[tableKey] = await this.validateTable(tableKey, tablePrefix);
    }
    
    const allValid = Object.values(results).every(r => r.valid);
    
    if (allValid) {
      console.log('\n✅ All tables are valid\n');
    } else {
      console.log('\n⚠️  Some tables have issues\n');
    }
    
    return results;
  }

  /**
   * Fix all tables by adding missing indexes
   */
  async fixAllTables(tablePrefix = '') {
    console.log(`\n🔧 Fixing all tables (schema version: ${schema.SCHEMA_VERSION})\n`);
    
    const tableKeys = Object.keys(schema.tables);
    
    for (const tableKey of tableKeys) {
      await this.addMissingIndexes(tableKey, tablePrefix);
    }
    
    console.log('\n✅ All tables fixed\n');
  }

  /**
   * Export schema as JSON for documentation
   */
  exportSchema() {
    return {
      version: schema.SCHEMA_VERSION,
      tables: schema.tables
    };
  }
}

module.exports = MigrationManager;
