const DynamoDbLocal = require('dynamodb-local');

const startDynamoDbLocal = async () => {
  try {
    const port = 8000;
    console.log('🚀 Starting DynamoDB Local on port', port);
    
    await DynamoDbLocal.launch(port, null, ['-inMemory', '-sharedDb']);
    console.log('✅ DynamoDB Local is running on port', port);
    console.log('🔗 Endpoint: http://localhost:8000');
    
    // Keep the process running
    process.on('SIGINT', async () => {
      console.log('\n🛑 Stopping DynamoDB Local...');
      await DynamoDbLocal.stop(port);
      console.log('✅ DynamoDB Local stopped');
      process.exit(0);
    });
    
    // Keep the process alive
    setInterval(() => {}, 1000);
    
  } catch (error) {
    console.error('❌ Error starting DynamoDB Local:', error);
    process.exit(1);
  }
};

startDynamoDbLocal();
