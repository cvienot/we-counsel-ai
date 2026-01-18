const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand, UpdateCommand, DeleteCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

// Configure DynamoDB client
const dynamoConfig = {
  region: process.env.DYNAMODB_REGION || 'us-east-1'
};

// Use local DynamoDB for development
if (process.env.NODE_ENV === 'development') {
  dynamoConfig.endpoint = process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
  // DynamoDB Local requires these specific dummy credentials
  dynamoConfig.credentials = {
    accessKeyId: 'local',
    secretAccessKey: 'local'
  };
} else if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
  dynamoConfig.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  };
}

const client = new DynamoDBClient(dynamoConfig);
const docClient = DynamoDBDocumentClient.from(client);

// For backwards compatibility with v2 SDK patterns
const dynamodb = client;

// Table names
const TABLES = {
  USERS: 'we-counsel-users',
  COUPLES: 'we-counsel-couples', 
  CONVERSATIONS: 'we-counsel-conversations',
  MESSAGES: 'we-counsel-messages',
  INVITATIONS: 'we-counsel-invitations',
  SUBSCRIPTIONS: 'we-counsel-subscriptions',
  EXERCISES: 'we-counsel-exercises',
  EXERCISE_SESSIONS: 'we-counsel-exercise-sessions'
};

// Create tables if they don't exist (for development)
const createTables = async () => {
  if (process.env.NODE_ENV !== 'development') return;

  const { CreateTableCommand } = require('@aws-sdk/client-dynamodb');

  const tables = [
    {
      TableName: TABLES.USERS,
      KeySchema: [
        { AttributeName: 'userId', KeyType: 'HASH' }
      ],
      AttributeDefinitions: [
        { AttributeName: 'userId', AttributeType: 'S' },
        { AttributeName: 'email', AttributeType: 'S' },
        { AttributeName: 'coupleId', AttributeType: 'S' }
      ],
      GlobalSecondaryIndexes: [
        {
          IndexName: 'email-index',
          KeySchema: [
            { AttributeName: 'email', KeyType: 'HASH' }
          ],
          Projection: { ProjectionType: 'ALL' }
        },
        {
          IndexName: 'couple-index',
          KeySchema: [
            { AttributeName: 'coupleId', KeyType: 'HASH' }
          ],
          Projection: { ProjectionType: 'ALL' }
        }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    },
    {
      TableName: TABLES.COUPLES,
      KeySchema: [
        { AttributeName: 'coupleId', KeyType: 'HASH' }
      ],
      AttributeDefinitions: [
        { AttributeName: 'coupleId', AttributeType: 'S' }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    },
    {
      TableName: TABLES.CONVERSATIONS,
      KeySchema: [
        { AttributeName: 'conversationId', KeyType: 'HASH' }
      ],
      AttributeDefinitions: [
        { AttributeName: 'conversationId', AttributeType: 'S' },
        { AttributeName: 'coupleId', AttributeType: 'S' }
      ],
      GlobalSecondaryIndexes: [
        {
          IndexName: 'couple-index',
          KeySchema: [
            { AttributeName: 'coupleId', KeyType: 'HASH' }
          ],
          Projection: { ProjectionType: 'ALL' }
        }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    },
    {
      TableName: TABLES.MESSAGES,
      KeySchema: [
        { AttributeName: 'messageId', KeyType: 'HASH' }
      ],
      AttributeDefinitions: [
        { AttributeName: 'messageId', AttributeType: 'S' },
        { AttributeName: 'conversationId', AttributeType: 'S' },
        { AttributeName: 'timestamp', AttributeType: 'N' }
      ],
      GlobalSecondaryIndexes: [
        {
          IndexName: 'conversation-timestamp-index',
          KeySchema: [
            { AttributeName: 'conversationId', KeyType: 'HASH' },
            { AttributeName: 'timestamp', KeyType: 'RANGE' }
          ],
          Projection: { ProjectionType: 'ALL' }
        }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    },
    {
      TableName: TABLES.INVITATIONS,
      KeySchema: [
        { AttributeName: 'invitationId', KeyType: 'HASH' }
      ],
      AttributeDefinitions: [
        { AttributeName: 'invitationId', AttributeType: 'S' },
        { AttributeName: 'email', AttributeType: 'S' }
      ],
      GlobalSecondaryIndexes: [
        {
          IndexName: 'email-index',
          KeySchema: [
            { AttributeName: 'email', KeyType: 'HASH' }
          ],
          Projection: { ProjectionType: 'ALL' },
          ProvisionedThroughput: {
            ReadCapacityUnits: 5,
            WriteCapacityUnits: 5
          }
        }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    }
  ];

  for (const table of tables) {
    try {
      await client.send(new CreateTableCommand(table));
      console.log(`✅ Created table: ${table.TableName}`);
    } catch (error) {
      if (error.name === 'ResourceInUseException') {
        console.log(`📋 Table already exists: ${table.TableName}`);
      } else {
        console.error(`❌ Error creating table ${table.TableName}:`, error);
      }
    }
  }
};

module.exports = {
  dynamodb,
  docClient,
  TABLES,
  createTables,
  // Export command classes for use throughout the app
  GetCommand: require('@aws-sdk/lib-dynamodb').GetCommand,
  PutCommand: require('@aws-sdk/lib-dynamodb').PutCommand,
  UpdateCommand: require('@aws-sdk/lib-dynamodb').UpdateCommand,
  DeleteCommand: require('@aws-sdk/lib-dynamodb').DeleteCommand,
  QueryCommand: require('@aws-sdk/lib-dynamodb').QueryCommand,
  ScanCommand: require('@aws-sdk/lib-dynamodb').ScanCommand,
  TransactWriteCommand: require('@aws-sdk/lib-dynamodb').TransactWriteCommand,
};

