# Database Schema Changelog

All notable changes to the database schema will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-06

### Added
- Initial schema definition with versioning system
- Migration manager for creating and validating tables
- CLI tool for schema management (`scripts/db.js`)
- Five core tables:
  - **users**: User accounts with email and couple indexes
  - **couples**: Couple relationships
  - **invitations**: Partner invitation system
  - **conversations**: Conversation threads with couple index
  - **messages**: Messages with conversation-timestamp and user indexes

### Schema Details

#### users table
- Primary Key: `userId` (S)
- GSIs:
  - `email-index`: Query by email for authentication
  - `couple-index`: Query all users in a couple

#### couples table
- Primary Key: `coupleId` (S)
- No GSIs

#### invitations table
- Primary Key: `invitationId` (S)
- GSIs:
  - `inviter-index`: Query invitations by inviter

#### conversations table
- Primary Key: `conversationId` (S)
- GSIs:
  - `couple-index`: Query all conversations for a couple

#### messages table
- Primary Key: `messageId` (S)
- GSIs:
  - `conversationId-timestamp-index`: Query messages chronologically
  - `userId-index`: Query all messages by a user

### Migration Notes
- Run `npm run db:validate` to check schema compliance
- Run `npm run db:fix` to add missing indexes to existing tables
- Schema is environment-agnostic (works with local and AWS DynamoDB)

---

## Template for Future Changes

### [X.Y.Z] - YYYY-MM-DD

### Added
- New tables, indexes, or attributes

### Changed
- Modified table structures or index configurations

### Deprecated
- Features that will be removed in future versions

### Removed
- Deleted tables, indexes, or attributes

### Fixed
- Corrections to schema definitions

### Security
- Security-related schema changes

### Migration Steps
1. Step-by-step instructions for migrating existing data
2. Any required manual interventions
3. Rollback procedures if needed
