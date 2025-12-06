# Database Schema Management

## Overview

This project uses a versioned schema system to manage database structure across different environments (local, staging, production) and ensure portability.

## Schema Version

Current version: **1.0.0**

The schema is defined in `src/database/schema.js` and serves as the single source of truth for:
- Table structures
- Primary keys
- Global Secondary Indexes (GSIs)
- Attribute types and descriptions

## Quick Start

### Validate Schema

Check if your database matches the schema:

```bash
# AWS DynamoDB
npm run db:validate

# Local DynamoDB
DYNAMODB_ENDPOINT=http://localhost:8000 npm run db:validate
```

### Fix Missing Indexes

Automatically add missing GSIs to existing tables:

```bash
# AWS DynamoDB
npm run db:fix

# Local DynamoDB
DYNAMODB_ENDPOINT=http://localhost:8000 npm run db:fix
```

### Create All Tables

Create all tables from scratch:

```bash
# AWS DynamoDB
npm run db:create

# Local DynamoDB
DYNAMODB_ENDPOINT=http://localhost:8000 npm run db:create
```

### Export Schema

Export schema as JSON for documentation:

```bash
npm run db:export > docs/schema.json
```

## Schema Structure

### Tables

1. **users** - User accounts and profiles
   - Primary Key: `userId`
   - GSIs: `email-index`, `couple-index`

2. **couples** - Couple relationships
   - Primary Key: `coupleId`

3. **invitations** - Partner invitation links
   - Primary Key: `invitationId`
   - GSIs: `inviter-index`

4. **conversations** - Conversation threads
   - Primary Key: `conversationId`
   - GSIs: `couple-index`

5. **messages** - Messages within conversations
   - Primary Key: `messageId`
   - GSIs: `conversationId-timestamp-index`, `userId-index`

## Environment Variables

- `DYNAMODB_ENDPOINT` - For local DynamoDB (e.g., `http://localhost:8000`)
- `DYNAMODB_REGION` - AWS region (default: `eu-west-3`)
- `TABLE_PREFIX` - Optional prefix for table names (e.g., `dev`, `staging`)

## Migration Workflow

### When Moving to a New Environment

1. **Validate current state:**
   ```bash
   npm run db:validate
   ```

2. **If tables don't exist, create them:**
   ```bash
   npm run db:create
   ```

3. **If tables exist but missing indexes:**
   ```bash
   npm run db:fix
   ```

### When Adding a New Index

1. Update `src/database/schema.js`
2. Increment schema version
3. Run validation: `npm run db:validate`
4. Apply changes: `npm run db:fix`
5. Test in development
6. Deploy to production

## Portability

This schema system is designed to work with:
- **AWS DynamoDB** (production)
- **DynamoDB Local** (development)
- **Other NoSQL databases** (with adapter layer)

The schema definition is database-agnostic and can be adapted to other providers by creating new migration managers.

## Best Practices

1. **Always version your schema changes**
   - Update `SCHEMA_VERSION` in `schema.js`
   - Document changes in commit messages

2. **Test locally first**
   - Use DynamoDB Local for testing
   - Validate schema before deploying

3. **Run validation after deployment**
   - Ensure production matches schema
   - Check for missing indexes

4. **Keep schema.js as documentation**
   - Include descriptions for all attributes
   - Document the purpose of each index

## Troubleshooting

### Missing Indexes in Production

```bash
npm run db:validate  # Identify missing indexes
npm run db:fix       # Add them automatically
```

### Schema Mismatch

```bash
npm run db:export > current-schema.json
# Compare with expected schema
git diff src/database/schema.js
```

### Local vs Production Differences

Use `TABLE_PREFIX` to maintain separate schemas:

```bash
# Development
TABLE_PREFIX=dev npm run db:create

# Staging
TABLE_PREFIX=staging npm run db:create
```
