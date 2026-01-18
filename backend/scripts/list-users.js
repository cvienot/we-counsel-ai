require('dotenv').config();
const { docClient, TABLES } = require('../src/config/database');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

async function listUsers() {
  try {
    console.log('Scanning users table...\n');

    const result = await docClient.send(new ScanCommand({
      TableName: TABLES.USERS
    }));

    if (!result.Items || result.Items.length === 0) {
      console.log('No users found');
      return;
    }

    console.log(`Found ${result.Items.length} users:\n`);

    result.Items.forEach((user, idx) => {
      console.log(`${idx + 1}. ${user.name} (${user.email})`);
      console.log(`   User ID: ${user.userId}`);
      console.log(`   Couple ID: ${user.coupleId || 'None'}`);
      console.log(`   Created: ${new Date(user.createdAt).toLocaleString()}`);
      console.log('');
    });

  } catch (error) {
    console.error('Error:', error);
  }
}

listUsers();
