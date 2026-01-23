const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({
  endpoint: 'http://localhost:8000',
  region: 'eu-west-3',
  credentials: {
    accessKeyId: 'dummy',
    secretAccessKey: 'dummy'
  }
});

const docClient = DynamoDBDocumentClient.from(client);
const TABLES = {
  EXERCISE_SESSIONS: 'we-counsel-exercise-sessions'
};

async function checkSessions() {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: TABLES.EXERCISE_SESSIONS
    }));

    console.log('📋 Exercise Sessions:');
    console.log(`Total: ${result.Items.length}\n`);

    // Filter for Alex & Emma's couple
    const alexEmmaSessions = result.Items.filter(s => s.coupleId === '62f5e79f-c636-45b8-9c91-b3355450707b');
    
    if (alexEmmaSessions.length === 0) {
      console.log('No sessions found for Alex & Emma');
      return;
    }

    alexEmmaSessions.forEach(session => {
      console.log('Session:', session.sessionId);
      console.log('  Exercise:', session.exerciseId);
      console.log('  Current Step:', session.currentStep);
      console.log('  Status:', session.status);
      console.log('  Created:', session.createdAt);
      console.log('  Progress:', JSON.parse(session.progress));
      console.log('');
    });

  } catch (error) {
    console.error('Error:', error);
  }
}

checkSessions();
