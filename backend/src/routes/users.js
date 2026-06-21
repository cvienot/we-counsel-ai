const express = require('express');
const { docClient, TABLES, GetCommand, PutCommand, QueryCommand, UpdateCommand, ScanCommand, TransactWriteCommand } = require('../config/database');
const { authenticateToken } = require('../middleware/authMiddleware');
const { randomUUID } = require('crypto');

const router = express.Router();
const tierRank = { free: 0, essential: 1, premium: 2 };

const nextUsageResetDate = (from = new Date()) => {
  const resetDate = new Date(from);
  resetDate.setMonth(resetDate.getMonth() + 1, 1);
  return resetDate;
};

const selectedCoupleTier = (...plans) => plans.reduce((best, plan) => {
  const normalizedPlan = plan || 'free';
  return (tierRank[normalizedPlan] || 0) > (tierRank[best] || 0)
    ? normalizedPlan
    : best;
}, 'free');

// @route   GET /api/users/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const { password, ...userProfile } = req.user;
    
    // Get partner info if exists
    if (req.user.partnerId) {
      const partnerParams = {
        TableName: TABLES.USERS,
        Key: { userId: req.user.partnerId }
      };
      
      const partnerResult = await docClient.send(new GetCommand(partnerParams));
      if (partnerResult.Item) {
        const { password, ...partnerInfo } = partnerResult.Item;
        userProfile.partner = partnerInfo;
      }
    }

    res.json({
      success: true,
      profile: userProfile
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get user profile'
    });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { firstName, lastName, language } = req.body;
    const userId = req.user.userId;

    // Build update expression dynamically
    const updateExpressions = [];
    const expressionAttributeValues = {
      ':updatedAt': new Date().toISOString()
    };
    const expressionAttributeNames = {};

    if (firstName) {
      updateExpressions.push('firstName = :firstName');
      expressionAttributeValues[':firstName'] = firstName;
    }

    if (lastName) {
      updateExpressions.push('lastName = :lastName');
      expressionAttributeValues[':lastName'] = lastName;
    }

    if (language) {
      updateExpressions.push('#lang = :language');
      expressionAttributeValues[':language'] = language;
      expressionAttributeNames['#lang'] = 'language'; // 'language' is a reserved word in DynamoDB
    }

    // Always update timestamp
    updateExpressions.push('updatedAt = :updatedAt');

    if (updateExpressions.length === 1) {
      // Only timestamp, no actual updates
      return res.status(400).json({
        error: 'Validation error',
        message: 'At least one field must be provided for update'
      });
    }

    const params = {
      TableName: TABLES.USERS,
      Key: { userId },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW'
    };

    // Add ExpressionAttributeNames only if we have reserved words
    if (Object.keys(expressionAttributeNames).length > 0) {
      params.ExpressionAttributeNames = expressionAttributeNames;
    }

    const result = await docClient.send(new UpdateCommand(params));
    const { passwordHash, ...updatedUser } = result.Attributes;

    // Get partner info if exists
    if (updatedUser.partnerId) {
      const partnerParams = {
        TableName: TABLES.USERS,
        Key: { userId: updatedUser.partnerId }
      };
      
      const partnerResult = await docClient.send(new GetCommand(partnerParams));
      if (partnerResult.Item) {
        const { password, ...partnerInfo } = partnerResult.Item;
        updatedUser.partner = partnerInfo;
      }
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: updatedUser
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to update profile'
    });
  }
});

// @route   GET /api/users/invitations
// @desc    Get user's sent invitations
// @access  Private
router.get('/invitations', authenticateToken, async (req, res) => {
  try {
    const params = {
      TableName: TABLES.INVITATIONS,
      FilterExpression: 'inviterId = :inviterId',
      ExpressionAttributeValues: {
        ':inviterId': req.user.userId
      }
    };

    const result = await docClient.send(new ScanCommand(params));

    res.json({
      success: true,
      invitations: result.Items
    });
  } catch (error) {
    console.error('Get invitations error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get invitations'
    });
  }
});

// @route   POST /api/users/accept-invitation/:invitationId
// @desc    Accept partner invitation
// @access  Private
router.post('/accept-invitation/:invitationId', authenticateToken, async (req, res) => {
  try {
    const { invitationId } = req.params;
    const userId = req.user.userId;

    // Get invitation
    const invitationParams = {
      TableName: TABLES.INVITATIONS,
      Key: { invitationId }
    };

    const invitationResult = await docClient.send(new GetCommand(invitationParams));
    
    if (!invitationResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Invitation not found'
      });
    }

    const invitation = invitationResult.Item;

    // Check if invitation is still valid
    if (invitation.status !== 'pending') {
      return res.status(400).json({
        error: 'Invalid invitation',
        message: 'Invitation has already been processed'
      });
    }

    if (new Date(invitation.expiresAt) < new Date()) {
      return res.status(400).json({
        error: 'Expired invitation',
        message: 'This invitation has expired'
      });
    }

    // Check if user already has a partner
    if (req.user.partnerId) {
      return res.status(400).json({
        error: 'Already paired',
        message: 'You already have a partner'
      });
    }

    // Prevent inviter from accepting their own invitation
    if (invitation.inviterId === userId) {
      return res.status(400).json({
        error: 'Invalid action',
        message: 'You cannot accept your own invitation'
      });
    }

    // Get inviter
    const inviterParams = {
      TableName: TABLES.USERS,
      Key: { userId: invitation.inviterId }
    };

    const inviterResult = await docClient.send(new GetCommand(inviterParams));
    
    if (!inviterResult.Item) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Inviter not found'
      });
    }

    const inviter = inviterResult.Item;

    // Check if inviter already has a partner
    if (inviter.partnerId) {
      return res.status(400).json({
        error: 'Partner unavailable',
        message: 'The inviter already has a partner'
      });
    }

    // Complete the pending couple created when the invitation was sent, or
    // create one for legacy invitations that predate pending-couple support.
    const coupleId = invitation.coupleId || inviter.coupleId || randomUUID();
    const currentTimestamp = new Date().toISOString();

    const existingCoupleResult = await docClient.send(new GetCommand({
      TableName: TABLES.COUPLES,
      Key: { coupleId }
    }));
    const existingCouple = existingCoupleResult.Item;

    // Get the higher subscription tier from both users' registration choices
    const inviterPlan = inviter.selectedPlan || 'free';
    const accepterPlan = req.user.selectedPlan || 'free';
    const coupleTier = selectedCoupleTier(existingCouple?.subscriptionTier, inviterPlan, accepterPlan);

    const coupleExists = !!existingCouple;

    // Start transaction to update all records
    const transactItems = [
      coupleExists
        ? {
            Update: {
              TableName: TABLES.COUPLES,
              Key: { coupleId },
              UpdateExpression: `SET
                partner1Id = :partner1Id,
                partner2Id = :partner2Id,
                #status = :status,
                isActive = :isActive,
                subscriptionTier = :tier,
                subscriptionStatus = if_not_exists(subscriptionStatus, :subscriptionStatus),
                subscriptionStartDate = if_not_exists(subscriptionStartDate, :subscriptionStartDate),
                aiMessagesUsed = if_not_exists(aiMessagesUsed, :zero),
                aiMessagesResetDate = if_not_exists(aiMessagesResetDate, :resetDate),
                updatedAt = :updatedAt
                REMOVE pendingInviteeEmail`,
              ExpressionAttributeNames: {
                '#status': 'status'
              },
              ExpressionAttributeValues: {
                ':partner1Id': invitation.inviterId,
                ':partner2Id': userId,
                ':status': 'active',
                ':isActive': true,
                ':tier': coupleTier,
                ':subscriptionStatus': 'active',
                ':subscriptionStartDate': currentTimestamp,
                ':zero': 0,
                ':resetDate': nextUsageResetDate().toISOString(),
                ':updatedAt': currentTimestamp
              }
            }
          }
        : {
            Put: {
              TableName: TABLES.COUPLES,
              Item: {
                coupleId,
                partner1Id: invitation.inviterId,
                partner2Id: userId,
                createdAt: currentTimestamp,
                updatedAt: currentTimestamp,
                isActive: true,
                status: 'active',
                subscriptionTier: coupleTier,
                subscriptionStatus: 'active',
                subscriptionStartDate: currentTimestamp,
                aiMessagesUsed: 0,
                aiMessagesResetDate: nextUsageResetDate().toISOString()
              }
            }
          },
      {
        Update: {
          TableName: TABLES.USERS,
          Key: { userId: invitation.inviterId },
          UpdateExpression: 'SET partnerId = :partnerId, coupleId = :coupleId',
          ExpressionAttributeValues: {
            ':partnerId': userId,
            ':coupleId': coupleId
          }
        }
      },
      {
        Update: {
          TableName: TABLES.USERS,
          Key: { userId },
          UpdateExpression: 'SET partnerId = :partnerId, coupleId = :coupleId',
          ExpressionAttributeValues: {
            ':partnerId': invitation.inviterId,
            ':coupleId': coupleId
          }
        }
      },
      {
        Update: {
          TableName: TABLES.INVITATIONS,
          Key: { invitationId },
          UpdateExpression: 'SET #status = :status, acceptedAt = :acceptedAt',
          ExpressionAttributeValues: {
            ':status': 'accepted',
            ':acceptedAt': new Date().toISOString()
          },
          ExpressionAttributeNames: {
            '#status': 'status'
          }
        }
      }
    ];

    const transactParams = {
      TransactItems: transactItems
    };

    await docClient.send(new TransactWriteCommand(transactParams));

    res.json({
      success: true,
      message: 'Invitation accepted successfully',
      couple: {
        coupleId,
        partnerId: invitation.inviterId,
        partnerName: invitation.inviterName
      }
    });

  } catch (error) {
    console.error('Accept invitation error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to accept invitation'
    });
  }
});

module.exports = router;
