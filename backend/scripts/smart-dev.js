#!/usr/bin/env node

/**
 * Smart Development Script
 * Manages DynamoDB Local and Express server with automatic table creation
 */

const { spawn, exec } = require('child_process');
const path = require('path');

// Colors for console output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m'
};

const log = (color, message) => console.log(`${colors[color]}${message}${colors.reset}`);

// Check if a process is running on a specific port
const checkPort = (port) => {
  return new Promise((resolve) => {
    exec(`lsof -i :${port}`, (error) => {
      resolve(!error); // true if port is in use
    });
  });
};

// Kill process on a specific port
const killPort = (port) => {
  return new Promise((resolve) => {
    exec(`lsof -ti :${port} | xargs kill -9`, (error) => {
      resolve(!error);
    });
  });
};

// Wait for a service to be ready
const waitForService = (port, maxAttempts = 30) => {
  return new Promise((resolve, reject) => {
    let attempts = 0;
    const check = async () => {
      attempts++;
      const isReady = await checkPort(port);
      if (isReady) {
        resolve(true);
      } else if (attempts >= maxAttempts) {
        reject(new Error(`Service on port ${port} not ready after ${maxAttempts} attempts`));
      } else {
        setTimeout(check, 1000);
      }
    };
    check();
  });
};

// Start DynamoDB Local and setup tables
const startDynamoWithTables = async () => {
  console.log('🚀 Starting DynamoDB Local...');
  
  // Start DynamoDB Local
  const dynamoProcess = spawn('node', ['scripts/start-dynamodb.js'], {
    stdio: 'inherit',
    cwd: process.cwd()
  });

  // Wait for DynamoDB to be ready
  try {
    await waitForService(8000);
    console.log('✅ DynamoDB Local is ready');
    
    // Setup tables
    console.log('🗄️  Creating database tables...');
    const setupProcess = spawn('node', ['scripts/setup-database.js'], {
      stdio: 'inherit',
      cwd: process.cwd()
    });
    
    await new Promise((resolve, reject) => {
      setupProcess.on('close', (code) => {
        if (code === 0) {
          console.log('✅ Database tables created');
          resolve();
        } else {
          reject(new Error(`Database setup failed with code ${code}`));
        }
      });
    });
    
    return dynamoProcess;
  } catch (error) {
    dynamoProcess.kill();
    throw error;
  }
};

// Main development function
const runDev = async (shouldReset = false) => {
  try {
    // Check if services are running
    const dynamoRunning = await checkPort(8000);
    const serverRunning = await checkPort(3000);
    
    if (shouldReset) {
      console.log('🔄 Resetting development environment...');
      if (dynamoRunning) {
        console.log('🛑 Stopping DynamoDB Local...');
        await killPort(8000);
      }
      if (serverRunning) {
        console.log('🛑 Stopping Express server...');
        await killPort(3000);
      }
      // Wait a moment for cleanup
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
    
    // Start or restart DynamoDB if needed
    let dynamoProcess;
    if (!dynamoRunning || shouldReset) {
      dynamoProcess = await startDynamoWithTables();
    } else {
      console.log('✅ DynamoDB Local already running on port 8000');
    }
    
    // Start or restart server if needed
    if (!serverRunning || shouldReset) {
      console.log('🚀 Starting Express server...');
      const serverProcess = spawn('npx', ['nodemon', 'src/server.js'], {
        stdio: 'inherit',
        cwd: process.cwd()
      });
      
      // Handle process cleanup
      process.on('SIGINT', () => {
        console.log('\n🛑 Shutting down development environment...');
        if (dynamoProcess) dynamoProcess.kill();
        serverProcess.kill();
        process.exit(0);
      });
      
      process.on('SIGTERM', () => {
        if (dynamoProcess) dynamoProcess.kill();
        serverProcess.kill();
        process.exit(0);
      });
      
    } else {
      console.log('✅ Express server already running on port 3000');
    }
    
    console.log('\n🎉 Development environment ready!');
    console.log('📊 DynamoDB Local: http://localhost:8000');
    console.log('🔗 API Server: http://localhost:3000');
    console.log('🏥 Health Check: http://localhost:3000/health');
    console.log('\nPress Ctrl+C to stop all services');
    
  } catch (error) {
    console.error('❌ Failed to start development environment:', error.message);
    process.exit(1);
  }
};

// Parse command line arguments
const command = process.argv[2];

if (command === 'reset') {
  runDev(true);
} else {
  runDev(false);
}
