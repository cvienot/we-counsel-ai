#!/usr/bin/env node

require('dotenv').config({ quiet: true });

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const args = process.argv.slice(2);
const outputJson = args.includes('--json');

function getFlagNumber(name, fallback) {
  const prefix = `--${name}=`;
  const raw = args.find(arg => arg.startsWith(prefix));
  if (!raw) return fallback;

  const value = Number(raw.slice(prefix.length));
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

const windowDays = getFlagNumber('days', 7);
const maxItems = getFlagNumber('max-items', 0);
const region = process.env.DYNAMODB_REGION || process.env.AWS_REGION || 'eu-west-3';
const endpoint = process.env.DYNAMODB_ENDPOINT;
const isRemoteDynamo = !endpoint;

if (isRemoteDynamo && process.env.NODE_ENV !== 'production') {
  console.error('Refusing to query remote DynamoDB unless NODE_ENV=production is set.');
  console.error('For local data, set DYNAMODB_ENDPOINT. For production, run with NODE_ENV=production.');
  process.exit(1);
}

const clientConfig = { region };

if (endpoint) {
  clientConfig.endpoint = endpoint;
  clientConfig.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'local',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'local'
  };
} else if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
  clientConfig.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  };
}

const docClient = DynamoDBDocumentClient.from(new DynamoDBClient(clientConfig));

const TABLES = {
  users: process.env.TABLE_USERS || 'we-counsel-users',
  couples: process.env.TABLE_COUPLES || 'we-counsel-couples',
  conversations: process.env.TABLE_CONVERSATIONS || 'we-counsel-conversations',
  messages: process.env.TABLE_MESSAGES || 'we-counsel-messages',
  invitations: process.env.TABLE_INVITATIONS || 'we-counsel-invitations',
  subscriptions: process.env.TABLE_SUBSCRIPTIONS || 'we-counsel-subscriptions',
  exercises: process.env.TABLE_EXERCISES || 'we-counsel-exercises',
  exerciseSessions: process.env.TABLE_EXERCISE_SESSIONS || 'we-counsel-exercise-sessions'
};

function toTimestamp(value) {
  if (value == null) return null;
  if (typeof value === 'number') return value < 1000000000000 ? value * 1000 : value;
  if (typeof value !== 'string' || value.trim() === '') return null;

  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}

function timestampFrom(item, fields) {
  for (const field of fields) {
    const timestamp = toTimestamp(item[field]);
    if (timestamp) return timestamp;
  }
  return null;
}

function isWithin(timestamp, days) {
  if (!timestamp) return false;
  return timestamp >= Date.now() - days * 24 * 60 * 60 * 1000;
}

function countBy(items, field, fallback = 'unknown') {
  return items.reduce((acc, item) => {
    const value = item[field] == null || item[field] === '' ? fallback : String(item[field]);
    acc[value] = (acc[value] || 0) + 1;
    return acc;
  }, {});
}

function countByDay(items, fields, days) {
  const counts = {};
  const today = new Date();

  for (let offset = days - 1; offset >= 0; offset -= 1) {
    const date = new Date(today.getTime() - offset * 24 * 60 * 60 * 1000);
    counts[date.toISOString().slice(0, 10)] = 0;
  }

  for (const item of items) {
    const timestamp = timestampFrom(item, fields);
    if (!isWithin(timestamp, days)) continue;

    const day = new Date(timestamp).toISOString().slice(0, 10);
    if (counts[day] != null) counts[day] += 1;
  }

  return counts;
}

function sumNumber(items, field) {
  return items.reduce((total, item) => {
    const value = Number(item[field]);
    return Number.isFinite(value) ? total + value : total;
  }, 0);
}

async function scanTable(label, tableName) {
  const items = [];
  let lastKey;
  let pages = 0;

  try {
    do {
      const response = await docClient.send(new ScanCommand({
        TableName: tableName,
        ExclusiveStartKey: lastKey
      }));

      items.push(...(response.Items || []));
      pages += 1;
      lastKey = response.LastEvaluatedKey;
    } while (lastKey && (!maxItems || items.length < maxItems));

    return {
      label,
      tableName,
      count: maxItems ? Math.min(items.length, maxItems) : items.length,
      pages,
      truncated: Boolean(maxItems && items.length >= maxItems),
      items: maxItems ? items.slice(0, maxItems) : items
    };
  } catch (error) {
    return {
      label,
      tableName,
      count: 0,
      pages,
      truncated: false,
      items: [],
      error: `${error.name || 'Error'}: ${error.message}`
    };
  }
}

function buildMetrics(scans) {
  const users = scans.users.items;
  const couples = scans.couples.items;
  const conversations = scans.conversations.items;
  const messages = scans.messages.items;
  const invitations = scans.invitations.items;
  const subscriptions = scans.subscriptions.items;
  const exerciseSessions = scans.exerciseSessions.items;

  const recentUsers = users.filter(item => isWithin(timestampFrom(item, ['createdAt']), windowDays));
  const recentMessages = messages.filter(item => isWithin(timestampFrom(item, ['timestamp', 'createdAt']), windowDays));
  const recentConversations = conversations.filter(item => isWithin(timestampFrom(item, ['createdAt']), windowDays));
  const recentExerciseSessions = exerciseSessions.filter(item => isWithin(timestampFrom(item, ['createdAt', 'startedAt']), windowDays));
  const activePaidCouples = couples.filter(item =>
    item.subscriptionStatus === 'active' &&
    item.subscriptionTier &&
    item.subscriptionTier !== 'free'
  );

  return {
    generatedAt: new Date().toISOString(),
    source: {
      region,
      endpoint: endpoint || 'AWS DynamoDB',
      nodeEnv: process.env.NODE_ENV || '(unset)',
      windowDays,
      maxItems: maxItems || null
    },
    tables: Object.fromEntries(Object.entries(scans).map(([key, scan]) => [
      key,
      {
        tableName: scan.tableName,
        count: scan.count,
        pages: scan.pages,
        truncated: scan.truncated,
        error: scan.error || null
      }
    ])),
    users: {
      total: users.length,
      newInWindow: recentUsers.length,
      withPartner: users.filter(item => item.partnerId).length,
      withCoupleId: users.filter(item => item.coupleId).length,
      acceptedTerms: users.filter(item => item.termsAcceptedAt).length,
      missingTermsAcceptance: users.filter(item => !item.termsAcceptedAt).length,
      byLanguage: countBy(users, 'language'),
      newByDay: countByDay(users, ['createdAt'], windowDays)
    },
    couples: {
      total: couples.length,
      active: couples.filter(item => item.status === 'active').length,
      connected: couples.filter(item => item.user1Id && item.user2Id).length,
      activePaid: activePaidCouples.length,
      byStatus: countBy(couples, 'status'),
      bySubscriptionTier: countBy(couples, 'subscriptionTier'),
      bySubscriptionStatus: countBy(couples, 'subscriptionStatus'),
      aiMessagesUsedTotal: sumNumber(couples, 'aiMessagesUsed')
    },
    invitations: {
      total: invitations.length,
      byStatus: countBy(invitations, 'status'),
      expiredPending: invitations.filter(item => {
        const expiresAt = timestampFrom(item, ['expiresAt']);
        return item.status === 'pending' && expiresAt && expiresAt < Date.now();
      }).length
    },
    conversations: {
      total: conversations.length,
      active: conversations.filter(item => item.isActive === true).length,
      createdInWindow: recentConversations.length,
      byType: countBy(conversations, 'conversationType'),
      recordedMessageCountTotal: sumNumber(conversations, 'messageCount')
    },
    messages: {
      total: messages.length,
      sentInWindow: recentMessages.length,
      bySenderType: countBy(messages, 'senderType'),
      byRecipientType: countBy(messages, 'recipientType'),
      sentByDay: countByDay(messages, ['timestamp', 'createdAt'], windowDays)
    },
    subscriptions: {
      totalRecords: subscriptions.length,
      byTier: countBy(subscriptions, 'tier'),
      byStatus: countBy(subscriptions, 'status'),
      byBillingPeriod: countBy(subscriptions, 'billingPeriod'),
      byPaymentProvider: countBy(subscriptions, 'paymentProvider')
    },
    exerciseSessions: {
      total: exerciseSessions.length,
      createdInWindow: recentExerciseSessions.length,
      byStatus: countBy(exerciseSessions, 'status')
    }
  };
}

function printObject(prefix, object) {
  const entries = Object.entries(object);
  if (entries.length === 0) {
    console.log(`${prefix}: none`);
    return;
  }

  console.log(`${prefix}:`);
  for (const [key, value] of entries) {
    console.log(`  - ${key}: ${value}`);
  }
}

function printMetrics(metrics) {
  console.log('Launch metrics');
  console.log(`Generated: ${metrics.generatedAt}`);
  console.log(`Source: ${metrics.source.endpoint} (${metrics.source.region}, NODE_ENV=${metrics.source.nodeEnv})`);
  console.log(`Window: last ${metrics.source.windowDays} days`);

  console.log('\nTables');
  for (const [key, table] of Object.entries(metrics.tables)) {
    const status = table.error ? `ERROR - ${table.error}` : `${table.count} items${table.truncated ? ' (truncated)' : ''}`;
    console.log(`  - ${key} (${table.tableName}): ${status}`);
  }

  console.log('\nUsers');
  console.log(`  - total: ${metrics.users.total}`);
  console.log(`  - new in window: ${metrics.users.newInWindow}`);
  console.log(`  - with partner: ${metrics.users.withPartner}`);
  console.log(`  - with couple ID: ${metrics.users.withCoupleId}`);
  console.log(`  - accepted terms: ${metrics.users.acceptedTerms}`);
  console.log(`  - missing terms acceptance: ${metrics.users.missingTermsAcceptance}`);
  printObject('  - by language', metrics.users.byLanguage);
  printObject('  - new users by day', metrics.users.newByDay);

  console.log('\nCouples');
  console.log(`  - total: ${metrics.couples.total}`);
  console.log(`  - active: ${metrics.couples.active}`);
  console.log(`  - connected: ${metrics.couples.connected}`);
  console.log(`  - active paid: ${metrics.couples.activePaid}`);
  console.log(`  - AI messages used total: ${metrics.couples.aiMessagesUsedTotal}`);
  printObject('  - by subscription tier', metrics.couples.bySubscriptionTier);
  printObject('  - by subscription status', metrics.couples.bySubscriptionStatus);

  console.log('\nInvitations');
  console.log(`  - total: ${metrics.invitations.total}`);
  console.log(`  - expired pending: ${metrics.invitations.expiredPending}`);
  printObject('  - by status', metrics.invitations.byStatus);

  console.log('\nConversations and messages');
  console.log(`  - conversations total: ${metrics.conversations.total}`);
  console.log(`  - conversations created in window: ${metrics.conversations.createdInWindow}`);
  console.log(`  - messages total: ${metrics.messages.total}`);
  console.log(`  - messages sent in window: ${metrics.messages.sentInWindow}`);
  console.log(`  - recorded conversation message count total: ${metrics.conversations.recordedMessageCountTotal}`);
  printObject('  - messages by sender type', metrics.messages.bySenderType);
  printObject('  - messages by day', metrics.messages.sentByDay);

  console.log('\nSubscriptions');
  console.log(`  - total records: ${metrics.subscriptions.totalRecords}`);
  printObject('  - by tier', metrics.subscriptions.byTier);
  printObject('  - by status', metrics.subscriptions.byStatus);
  printObject('  - by billing period', metrics.subscriptions.byBillingPeriod);
  printObject('  - by payment provider', metrics.subscriptions.byPaymentProvider);

  console.log('\nExercise sessions');
  console.log(`  - total: ${metrics.exerciseSessions.total}`);
  console.log(`  - created in window: ${metrics.exerciseSessions.createdInWindow}`);
  printObject('  - by status', metrics.exerciseSessions.byStatus);
}

async function main() {
  const entries = await Promise.all(
    Object.entries(TABLES).map(async ([label, tableName]) => [label, await scanTable(label, tableName)])
  );
  const scans = Object.fromEntries(entries);
  const metrics = buildMetrics(scans);

  if (outputJson) {
    console.log(JSON.stringify(metrics, null, 2));
  } else {
    printMetrics(metrics);
  }
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
