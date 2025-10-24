const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');
const { docClient, TABLES } = require('../config/database');
const { sendInvitationEmail } = require('../services/emailService');
const { authenticateToken } = require('../middleware/authMiddleware');

const router = express.Router();

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;

    // Validation
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Please provide email, password, first name, and last name'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Password must be at least 6 characters long'
      });
    }

    // Check if user already exists
    const existingUserParams = {
      TableName: TABLES.USERS,
      IndexName: 'email-index',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email.toLowerCase()
      }
    };

    const existingUser = await docClient.query(existingUserParams).promise();

    if (existingUser.Items.length > 0) {
      return res.status(409).json({
        error: 'User exists',
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
            const userId = randomUUID();
    const userData = {
      userId,
      email: email.toLowerCase(),
      passwordHash: hashedPassword,
      firstName,
      lastName,
      createdAt: new Date().toISOString(),
      isActive: true,
      partnerId: null,
      coupleId: null
    };

    const params = {
      TableName: TABLES.USERS,
      Item: userData
    };

    await docClient.put(params).promise();

    // Generate token
    const token = generateToken(userId);

    // Remove password from response
    const { passwordHash: _, ...userResponse } = userData;

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: userResponse
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to register user'
    });
  }
});

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Please provide email and password'
      });
    }

    // Find user by email
    const params = {
      TableName: TABLES.USERS,
      IndexName: 'email-index',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email.toLowerCase()
      }
    };

    const result = await docClient.query(params).promise();

    if (result.Items.length === 0) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Invalid email or password'
      });
    }

    const user = result.Items[0];

    // Check password
    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Invalid email or password'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        error: 'Account disabled',
        message: 'Your account has been disabled'
      });
    }

    // Generate token
    const token = generateToken(user.userId);

    // Remove password from response
    const { passwordHash: _, ...userResponse } = user;
    
    // Get partner info if exists
    if (user.partnerId) {
      const partnerParams = {
        TableName: TABLES.USERS,
        Key: { userId: user.partnerId }
      };
      
      const partnerResult = await docClient.get(partnerParams).promise();
      if (partnerResult.Item) {
        const { passwordHash: _, ...partnerInfo } = partnerResult.Item;
        userResponse.partner = partnerInfo;
      }
    }

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: userResponse
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to log in'
    });
  }
});

// @route   POST /api/auth/invite-partner
// @desc    Send invitation to partner
// @access  Private
router.post('/invite-partner', authenticateToken, async (req, res) => {
  try {
    const { email, message } = req.body;
    const inviterId = req.user.userId;

    // Validation
    if (!email) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Please provide partner email'
      });
    }

    // Check if user already has a partner
    if (req.user.partnerId) {
      return res.status(400).json({
        error: 'Already paired',
        message: 'You already have a partner'
      });
    }

    // Check if trying to invite themselves
    if (email.toLowerCase() === req.user.email.toLowerCase()) {
      return res.status(400).json({
        error: 'Invalid invitation',
        message: 'Cannot invite yourself'
      });
    }

    // Check if partner already exists
    const partnerParams = {
      TableName: TABLES.USERS,
      IndexName: 'email-index',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email.toLowerCase()
      }
    };

    const partnerResult = await docClient.query(partnerParams).promise();

    if (partnerResult.Items.length > 0 && partnerResult.Items[0].partnerId) {
      return res.status(400).json({
        error: 'Partner unavailable',
        message: 'This user already has a partner'
      });
    }

    // Check for existing invitation
    const existingInvitationParams = {
      TableName: TABLES.INVITATIONS,
      IndexName: 'email-index',
      KeyConditionExpression: 'email = :email',
      FilterExpression: 'inviterId = :inviterId AND #status = :status',
      ExpressionAttributeValues: {
        ':email': email.toLowerCase(),
        ':inviterId': inviterId,
        ':status': 'pending'
      },
      ExpressionAttributeNames: {
        '#status': 'status'
      }
    };

    const existingInvitation = await docClient.query(existingInvitationParams).promise();

    if (existingInvitation.Items.length > 0) {
      return res.status(400).json({
        error: 'Invitation exists',
        message: 'You have already sent an invitation to this email'
      });
    }

    // Create invitation
    const invitationId = randomUUID();
    const invitationData = {
      invitationId,
      inviterId,
      inviterName: `${req.user.firstName} ${req.user.lastName}`,
      email: email.toLowerCase(),
      message: message || '',
      status: 'pending',
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days
    };

    const invitationParams = {
      TableName: TABLES.INVITATIONS,
      Item: invitationData
    };

    await docClient.put(invitationParams).promise();

    // Send invitation email
    try {
      await sendInvitationEmail({
        to: email,
        inviterName: invitationData.inviterName,
        invitationId,
        message
      });
    } catch (emailError) {
      console.error('Failed to send invitation email:', emailError);
      // Continue despite email failure
    }

    res.status(201).json({
      success: true,
      message: 'Invitation sent successfully',
      invitation: {
        invitationId,
        email: email.toLowerCase(),
        status: 'pending',
        createdAt: invitationData.createdAt
      }
    });

  } catch (error) {
    console.error('Invite partner error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to send invitation'
    });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const { passwordHash, ...userResponse } = req.user;
    
    // Get partner info if exists
    if (req.user.partnerId) {
      const partnerParams = {
        TableName: TABLES.USERS,
        Key: { userId: req.user.partnerId }
      };
      
      const partnerResult = await docClient.get(partnerParams).promise();
      if (partnerResult.Item) {
        const { passwordHash: _, ...partnerInfo } = partnerResult.Item;
        userResponse.partner = partnerInfo;
      }
    }
    
    res.json({
      success: true,
      user: userResponse
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to get current user'
    });
  }
});

module.exports = router;
