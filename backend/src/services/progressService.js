const { docClient, TABLES, QueryCommand, GetCommand, ScanCommand } = require('../config/database');

/**
 * Progress Dashboard Service
 * Aggregates data from exercises, messages, and conversations
 * to provide relationship progress insights.
 */

/**
 * Get full dashboard data for a couple
 */
async function getDashboard(coupleId) {
  const [exerciseStats, conversationStats, activityStreak, weeklyActivity] = await Promise.all([
    getExerciseStats(coupleId),
    getConversationStats(coupleId),
    getActivityStreak(coupleId),
    getWeeklyActivity(coupleId),
  ]);

  const healthScore = computeHealthScore({ exerciseStats, conversationStats, activityStreak });

  return {
    healthScore,
    exerciseStats,
    conversationStats,
    activityStreak,
    weeklyActivity,
  };
}

/**
 * Get exercise completion statistics for a couple
 */
async function getExerciseStats(coupleId) {
  const result = await docClient.send(new QueryCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    IndexName: 'coupleId-index',
    KeyConditionExpression: 'coupleId = :coupleId',
    ExpressionAttributeValues: { ':coupleId': coupleId },
  }));

  const sessions = result.Items || [];
  const completed = sessions.filter(s => s.status === 'completed');
  const active = sessions.filter(s => s.status === 'active');

  // Count by category (exercise templates have category info embedded)
  const byCategory = {};
  for (const session of completed) {
    const cat = session.exerciseCategory || 'general';
    byCategory[cat] = (byCategory[cat] || 0) + 1;
  }

  // Recent completions (last 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const recentCompleted = completed.filter(s => 
    new Date(s.completedAt || s.createdAt) >= thirtyDaysAgo
  );

  return {
    total: sessions.length,
    completed: completed.length,
    active: active.length,
    completionRate: sessions.length > 0 ? Math.round((completed.length / sessions.length) * 100) : 0,
    byCategory,
    recentCompleted: recentCompleted.length,
  };
}

/**
 * Get conversation and messaging statistics for a couple
 */
async function getConversationStats(coupleId) {
  // Get all conversations for the couple
  const convResult = await docClient.send(new QueryCommand({
    TableName: TABLES.CONVERSATIONS,
    IndexName: 'couple-index',
    KeyConditionExpression: 'coupleId = :coupleId',
    ExpressionAttributeValues: { ':coupleId': coupleId },
  }));

  const conversations = convResult.Items || [];
  const totalMessages = conversations.reduce((sum, c) => sum + (c.messageCount || 0), 0);
  const activeConversations = conversations.filter(c => c.isActive !== false);

  // Get couple record for AI usage
  const coupleResult = await docClient.send(new GetCommand({
    TableName: TABLES.COUPLES,
    Key: { coupleId },
  }));
  const couple = coupleResult.Item || {};

  return {
    totalConversations: conversations.length,
    activeConversations: activeConversations.length,
    totalMessages,
    aiMessagesUsed: couple.aiMessagesUsed || 0,
    aiMessagesResetDate: couple.aiMessagesResetDate || null,
  };
}

/**
 * Calculate activity streak (consecutive days with messages or exercises)
 */
async function getActivityStreak(coupleId) {
  // Get conversations to find message activity
  const convResult = await docClient.send(new QueryCommand({
    TableName: TABLES.CONVERSATIONS,
    IndexName: 'couple-index',
    KeyConditionExpression: 'coupleId = :coupleId',
    ExpressionAttributeValues: { ':coupleId': coupleId },
  }));

  const conversations = convResult.Items || [];
  if (conversations.length === 0) {
    return { currentStreak: 0, longestStreak: 0, lastActiveDate: null };
  }

  // Get recent messages across all conversations (last 60 days)
  const sixtyDaysAgo = Date.now() - (60 * 24 * 60 * 60 * 1000);
  const activeDays = new Set();

  for (const conv of conversations) {
    const msgResult = await docClient.send(new QueryCommand({
      TableName: TABLES.MESSAGES,
      IndexName: 'conversationId-timestamp-index',
      KeyConditionExpression: 'conversationId = :convId AND #ts >= :since',
      ExpressionAttributeNames: { '#ts': 'timestamp' },
      ExpressionAttributeValues: {
        ':convId': conv.conversationId,
        ':since': sixtyDaysAgo,
      },
      ProjectionExpression: '#ts',
    }));

    for (const msg of (msgResult.Items || [])) {
      const day = new Date(msg.timestamp).toISOString().substring(0, 10); // YYYY-MM-DD
      activeDays.add(day);
    }
  }

  // Also count exercise session days
  const exResult = await docClient.send(new QueryCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    IndexName: 'coupleId-index',
    KeyConditionExpression: 'coupleId = :coupleId',
    ExpressionAttributeValues: { ':coupleId': coupleId },
    ProjectionExpression: 'startedAt, createdAt',
  }));

  for (const session of (exResult.Items || [])) {
    const date = session.startedAt || session.createdAt;
    if (date) {
      const day = date.substring(0, 10);
      activeDays.add(day);
    }
  }

  // Sort days and compute streaks
  const sortedDays = Array.from(activeDays).sort().reverse(); // newest first
  if (sortedDays.length === 0) {
    return { currentStreak: 0, longestStreak: 0, lastActiveDate: null };
  }

  const today = new Date().toISOString().substring(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().substring(0, 10);

  // Current streak: must include today or yesterday
  let currentStreak = 0;
  if (sortedDays[0] === today || sortedDays[0] === yesterday) {
    currentStreak = 1;
    for (let i = 1; i < sortedDays.length; i++) {
      const prev = new Date(sortedDays[i - 1]);
      const curr = new Date(sortedDays[i]);
      const diffDays = (prev - curr) / 86400000;
      if (diffDays === 1) {
        currentStreak++;
      } else {
        break;
      }
    }
  }

  // Longest streak
  let longestStreak = 1;
  let streak = 1;
  const allSorted = Array.from(activeDays).sort(); // oldest first
  for (let i = 1; i < allSorted.length; i++) {
    const prev = new Date(allSorted[i - 1]);
    const curr = new Date(allSorted[i]);
    const diffDays = (curr - prev) / 86400000;
    if (diffDays === 1) {
      streak++;
      longestStreak = Math.max(longestStreak, streak);
    } else {
      streak = 1;
    }
  }

  return {
    currentStreak,
    longestStreak: allSorted.length > 0 ? longestStreak : 0,
    lastActiveDate: sortedDays[0],
    totalActiveDays: activeDays.size,
  };
}

/**
 * Get daily activity for the last 7 days
 */
async function getWeeklyActivity(coupleId) {
  const days = [];
  const now = new Date();

  // Build list of last 7 days
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    days.push(d.toISOString().substring(0, 10));
  }

  // Get conversations for the couple
  const convResult = await docClient.send(new QueryCommand({
    TableName: TABLES.CONVERSATIONS,
    IndexName: 'couple-index',
    KeyConditionExpression: 'coupleId = :coupleId',
    ExpressionAttributeValues: { ':coupleId': coupleId },
  }));

  const conversations = convResult.Items || [];
  const dailyCounts = {};
  for (const day of days) {
    dailyCounts[day] = { messages: 0, exercises: 0 };
  }

  // Count messages per day
  const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);

  for (const conv of conversations) {
    const msgResult = await docClient.send(new QueryCommand({
      TableName: TABLES.MESSAGES,
      IndexName: 'conversationId-timestamp-index',
      KeyConditionExpression: 'conversationId = :convId AND #ts >= :since',
      ExpressionAttributeNames: { '#ts': 'timestamp' },
      ExpressionAttributeValues: {
        ':convId': conv.conversationId,
        ':since': sevenDaysAgo,
      },
      ProjectionExpression: '#ts, senderType',
    }));

    for (const msg of (msgResult.Items || [])) {
      if (msg.senderType === 'ai') continue; // Only count user messages
      const day = new Date(msg.timestamp).toISOString().substring(0, 10);
      if (dailyCounts[day]) {
        dailyCounts[day].messages++;
      }
    }
  }

  // Count exercise sessions per day
  const exResult = await docClient.send(new QueryCommand({
    TableName: TABLES.EXERCISE_SESSIONS,
    IndexName: 'coupleId-index',
    KeyConditionExpression: 'coupleId = :coupleId',
    ExpressionAttributeValues: { ':coupleId': coupleId },
    ProjectionExpression: 'startedAt, createdAt',
  }));

  for (const session of (exResult.Items || [])) {
    const date = session.startedAt || session.createdAt;
    if (date) {
      const day = date.substring(0, 10);
      if (dailyCounts[day]) {
        dailyCounts[day].exercises++;
      }
    }
  }

  return days.map(day => ({
    date: day,
    dayOfWeek: new Date(day).toLocaleDateString('en-US', { weekday: 'short' }),
    messages: dailyCounts[day].messages,
    exercises: dailyCounts[day].exercises,
  }));
}

/**
 * Compute a relationship health score (0-100) based on engagement patterns
 */
function computeHealthScore({ exerciseStats, conversationStats, activityStreak }) {
  let score = 0;

  // Conversation engagement (up to 30 points)
  // Having regular messages shows active communication
  if (conversationStats.totalMessages >= 50) score += 30;
  else if (conversationStats.totalMessages >= 20) score += 20;
  else if (conversationStats.totalMessages >= 5) score += 10;
  else if (conversationStats.totalMessages >= 1) score += 5;

  // Exercise completion (up to 30 points)
  // Completing exercises shows commitment
  if (exerciseStats.completed >= 10) score += 30;
  else if (exerciseStats.completed >= 5) score += 20;
  else if (exerciseStats.completed >= 2) score += 15;
  else if (exerciseStats.completed >= 1) score += 10;

  // Exercise variety (up to 10 points)
  const categoryCount = Object.keys(exerciseStats.byCategory).length;
  if (categoryCount >= 3) score += 10;
  else if (categoryCount >= 2) score += 7;
  else if (categoryCount >= 1) score += 4;

  // Activity streak (up to 20 points)
  if (activityStreak.currentStreak >= 14) score += 20;
  else if (activityStreak.currentStreak >= 7) score += 15;
  else if (activityStreak.currentStreak >= 3) score += 10;
  else if (activityStreak.currentStreak >= 1) score += 5;

  // Recent activity (up to 10 points)
  if (exerciseStats.recentCompleted >= 3) score += 10;
  else if (exerciseStats.recentCompleted >= 1) score += 5;

  return Math.min(100, score);
}

module.exports = {
  getDashboard,
  getExerciseStats,
  getConversationStats,
  getActivityStreak,
  getWeeklyActivity,
};
