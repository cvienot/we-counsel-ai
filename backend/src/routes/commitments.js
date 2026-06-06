const express = require('express');
const { randomUUID } = require('crypto');
const {
  docClient,
  TABLES,
  GetCommand,
  PutCommand,
  QueryCommand,
  UpdateCommand
} = require('../config/database');
const { authenticateToken } = require('../middleware/authMiddleware');

const router = express.Router();

const VALID_STATUSES = new Set(['pending', 'done', 'skipped']);

const verifyConversationAccess = async ({ conversationId, coupleId }) => {
  const result = await docClient.send(new GetCommand({
    TableName: TABLES.CONVERSATIONS,
    Key: { conversationId }
  }));

  if (!result.Item || result.Item.coupleId !== coupleId) {
    return null;
  }

  return result.Item;
};

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { status } = req.query;
    const query = {
      TableName: TABLES.COMMITMENTS,
      IndexName: 'coupleId-createdAt-index',
      KeyConditionExpression: 'coupleId = :coupleId',
      ExpressionAttributeValues: {
        ':coupleId': req.user.coupleId
      },
      ScanIndexForward: false
    };

    if (status) {
      query.FilterExpression = '#status = :status';
      query.ExpressionAttributeNames = { '#status': 'status' };
      query.ExpressionAttributeValues[':status'] = status;
    }

    const result = await docClient.send(new QueryCommand(query));

    res.json({
      success: true,
      commitments: result.Items || []
    });
  } catch (error) {
    console.error('Get commitments error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get commitments'
    });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      conversationId,
      sourceMessageId,
      title,
      agreement,
      practice,
      dueAt
    } = req.body;

    if (!conversationId || !title || !agreement || !practice) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'conversationId, title, agreement, and practice are required'
      });
    }

    const conversation = await verifyConversationAccess({
      conversationId,
      coupleId: req.user.coupleId
    });

    if (!conversation) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid conversation access'
      });
    }

    const now = new Date().toISOString();
    const commitmentId = sourceMessageId
      ? `commitment-${sourceMessageId}`
      : randomUUID();

    const item = {
      commitmentId,
      coupleId: req.user.coupleId,
      conversationId,
      sourceMessageId: sourceMessageId || null,
      createdBy: req.user.userId,
      title: title.trim(),
      agreement: agreement.trim(),
      practice: practice.trim(),
      status: 'pending',
      dueAt: dueAt || null,
      createdAt: now,
      updatedAt: now
    };

    try {
      await docClient.send(new PutCommand({
        TableName: TABLES.COMMITMENTS,
        Item: item,
        ConditionExpression: 'attribute_not_exists(commitmentId)'
      }));

      return res.status(201).json({
        success: true,
        commitment: item
      });
    } catch (error) {
      if (error.name !== 'ConditionalCheckFailedException') {
        throw error;
      }

      const existing = await docClient.send(new GetCommand({
        TableName: TABLES.COMMITMENTS,
        Key: { commitmentId }
      }));

      if (!existing.Item || existing.Item.coupleId !== req.user.coupleId) {
        return res.status(409).json({
          error: 'Conflict',
          message: 'Commitment already exists for another conversation'
        });
      }

      return res.json({
        success: true,
        commitment: existing.Item,
        alreadyExists: true
      });
    }
  } catch (error) {
    console.error('Create commitment error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to save commitment'
    });
  }
});

router.patch('/:commitmentId', authenticateToken, async (req, res) => {
  try {
    const { commitmentId } = req.params;
    const { status } = req.body;

    if (!VALID_STATUSES.has(status)) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'status must be pending, done, or skipped'
      });
    }

    const existing = await docClient.send(new GetCommand({
      TableName: TABLES.COMMITMENTS,
      Key: { commitmentId }
    }));

    if (!existing.Item || existing.Item.coupleId !== req.user.coupleId) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Commitment not found'
      });
    }

    const result = await docClient.send(new UpdateCommand({
      TableName: TABLES.COMMITMENTS,
      Key: { commitmentId },
      UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': status,
        ':updatedAt': new Date().toISOString()
      },
      ReturnValues: 'ALL_NEW'
    }));

    res.json({
      success: true,
      commitment: result.Attributes
    });
  } catch (error) {
    console.error('Update commitment error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to update commitment'
    });
  }
});

module.exports = router;
