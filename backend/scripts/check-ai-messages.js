require('dotenv').config();
const { docClient, TABLES, ScanCommand } = require('../src/config/database');

async function checkMessages() {
  const result = await docClient.send(new ScanCommand({
    TableName: TABLES.MESSAGES,
    FilterExpression: 'senderType = :ai',
    ExpressionAttributeValues: {
      ':ai': 'ai'
    }
  }));

  console.log(`\n📊 Found ${result.Items.length} AI messages\n`);
  
  // Sort by timestamp
  const sorted = result.Items.sort((a, b) => b.timestamp - a.timestamp);
  
  // Show last 3
  sorted.slice(0, 3).forEach((msg, i) => {
    console.log(`\n━━━━━━━━━━ Message ${i + 1} ━━━━━━━━━━`);
    console.log(`Time: ${new Date(msg.timestamp).toLocaleString()}`);
    console.log(`Content:\n${msg.content}\n`);
  });
}

checkMessages().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
