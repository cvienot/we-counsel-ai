# We Counsel - Development Setup Guide

## Quick Start

### First Time Setup

1. **Setup Development Environment**
   ```bash
   cd backend
   npm run setup:dev
   ```

   This will:
   - Start DynamoDB Local in the background
   - Create all required database tables
   - Seed the database with test data
   - Give you test credentials

### Daily Development

1. **Start API Server** (DynamoDB should already be running)
   ```bash
   cd backend
   npm run dev
   ```

2. **Start Frontend** (in a separate terminal)
   ```bash
   cd frontend
   flutter run -d chrome --web-port 8080
   ```

## Test Accounts

After running `npm run setup:dev`, you'll have these test accounts:

- **User 1**: `john@example.com` / `password123`
- **User 2**: `jane@example.com` / `password123`

These users are already paired as a couple with a conversation thread containing sample messages.

## Database Management

### Available Commands

```bash
# Database status and management
npm run db:status    # Check if DynamoDB is running
npm run db:start     # Start DynamoDB Local
npm run db:stop      # Stop DynamoDB Local
npm run db:restart   # Restart DynamoDB Local
npm run db:reset     # Reset data and recreate with seed data
npm run db:logs      # View DynamoDB logs

# Manual database operations
npm run setup:db     # Create tables only
npm run seed:db      # Seed data only (requires tables to exist)
```

### DynamoDB Web Interface

When DynamoDB Local is running, you can access the web interface at:
- **Web Shell**: http://localhost:8000/shell

## Services URLs

- **API Server**: http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **DynamoDB Local**: http://localhost:8000
- **DynamoDB Web Shell**: http://localhost:8000/shell
- **Flutter Web**: http://localhost:8080

## New Streaming Features

The app now includes real-time features:

### Backend Streaming Endpoints

- `GET /api/streaming/events` - Server-Sent Events for real-time updates
- `POST /api/streaming/typing` - Send typing indicators
- `POST /api/messages/:conversationId/ai-stream` - Send message with streaming AI response

### Real-time Features

1. **AI Response Streaming** - See AI counsellor responses type in real-time
2. **Typing Indicators** - See when your partner is typing
3. **Live Message Delivery** - Messages appear instantly without page refresh

## Troubleshooting

### DynamoDB Issues

If DynamoDB isn't working:
```bash
npm run db:status    # Check status
npm run db:restart   # Restart if needed
npm run db:reset     # Reset everything if corrupted
```

### Port Conflicts

If you get port conflicts:
- DynamoDB uses port 8000
- API server uses port 3000  
- Flutter web uses port 8080

Kill processes using these ports:
```bash
lsof -ti :8000 | xargs kill -9  # Kill DynamoDB
lsof -ti :3000 | xargs kill -9  # Kill API server
lsof -ti :8080 | xargs kill -9  # Kill Flutter web
```

### Fresh Start

To completely reset everything:
```bash
npm run db:stop
rm -rf .dynamodb/
npm run setup:dev
```

## Development Workflow

1. **First time**: Run `npm run setup:dev`
2. **Daily**: Just run `npm run dev` (DynamoDB stays running in background)
3. **Reset data**: Run `npm run db:reset` when you need fresh test data
4. **Clean shutdown**: Run `npm run db:stop` when done for the day

The improved setup ensures DynamoDB Local runs persistently in the background, so you don't lose your data when restarting the API server.
