const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');
const { docClient, TABLES, QueryCommand, PutCommand, GetCommand, UpdateCommand } = require('../config/database');
const { emailService } = require('../services');
const { sendInvitationEmail, sendWelcomeEmail, sendPasswordResetEmail } = emailService;
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
    const { email, password, firstName, lastName, language, termsAccepted } = req.body;

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

    // Check if terms have been accepted
    if (!termsAccepted) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'You must accept the Terms of Service to create an account'
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

    const existingUser = await docClient.send(new QueryCommand(existingUserParams));

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
    const currentTimestamp = new Date().toISOString();
    const userLanguage = language || 'en';
    
    const userData = {
      userId,
      email: email.toLowerCase(),
      passwordHash: hashedPassword,
      firstName,
      lastName,
      language: userLanguage, // Default to English if not provided
      createdAt: currentTimestamp,
      isActive: true,
      termsAcceptedAt: currentTimestamp,
      termsAcceptedVersion: `1.0.0-${userLanguage}` // Include language in version for tracking
      // Note: partnerId and coupleId are omitted (not set to null) for AWS SDK v3 compatibility
      // Note: subscriptionTier is now on the couple, not the user
    };

    const params = {
      TableName: TABLES.USERS,
      Item: userData
    };

    await docClient.send(new PutCommand(params));

    // Generate token
    const token = generateToken(userId);

    // Send welcome email
    try {
      await sendWelcomeEmail({
        to: email.toLowerCase(),
        firstName,
        language: language || 'en'
      });
    } catch (emailError) {
      console.error('Failed to send welcome email:', emailError);
      // Don't fail registration if email fails
    }

    // Remove password from response
    const { passwordHash: _, ...userResponse} = userData;

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

    const result = await docClient.send(new QueryCommand(params));

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
      
      const partnerResult = await docClient.send(new GetCommand(partnerParams));
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

    const partnerResult = await docClient.send(new QueryCommand(partnerParams));

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

    const existingInvitation = await docClient.send(new QueryCommand(existingInvitationParams));

    // Use existing invitation ID if found, or create new one
    const invitationId = existingInvitation.Items.length > 0 
      ? existingInvitation.Items[0].invitationId 
      : randomUUID();
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

    await docClient.send(new PutCommand(invitationParams));

    const isResend = existingInvitation.Items.length > 0;

    // Send invitation email in inviter's language
    try {
      await sendInvitationEmail({
        to: email,
        inviterName: invitationData.inviterName,
        invitationId,
        message,
        language: req.user.language || 'en'
      });
    } catch (emailError) {
      console.error('Failed to send invitation email:', emailError);
      // Continue despite email failure
    }

    res.status(201).json({
      success: true,
      message: isResend ? 'Invitation resent successfully' : 'Invitation sent successfully',
      invitation: {
        invitationId,
        email: email.toLowerCase(),
        status: 'pending',
        createdAt: invitationData.createdAt,
        resent: isResend
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
      
      const partnerResult = await docClient.send(new GetCommand(partnerParams));
      if (partnerResult.Item) {
        const { passwordHash: _, ...partnerInfo } = partnerResult.Item;
        userResponse.partner = partnerInfo;
      }
    } else {
      // Check for pending invitation sent by this user
      const pendingInvitationParams = {
        TableName: TABLES.INVITATIONS,
        IndexName: 'inviter-index',
        KeyConditionExpression: 'inviterId = :inviterId',
        FilterExpression: '#status = :status',
        ExpressionAttributeValues: {
          ':inviterId': req.user.userId,
          ':status': 'pending'
        },
        ExpressionAttributeNames: {
          '#status': 'status'
        }
      };
      
      const pendingResult = await docClient.send(new QueryCommand(pendingInvitationParams));
      if (pendingResult.Items && pendingResult.Items.length > 0) {
        const latestInvitation = pendingResult.Items.sort((a, b) => 
          new Date(b.createdAt) - new Date(a.createdAt)
        )[0];
        userResponse.pendingInvitation = {
          email: latestInvitation.email,
          createdAt: latestInvitation.createdAt,
          invitationId: latestInvitation.invitationId
        };
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

// @route   POST /api/auth/forgot-password
// @desc    Request a password reset email
// @access  Public
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Please provide an email address'
      });
    }

    // Look up user by email
    const userQuery = await docClient.send(new QueryCommand({
      TableName: TABLES.USERS,
      IndexName: 'email-index',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: { ':email': email.toLowerCase().trim() }
    }));

    // Always return success to prevent email enumeration
    if (!userQuery.Items || userQuery.Items.length === 0) {
      return res.json({
        success: true,
        message: 'If an account with that email exists, a password reset link has been sent'
      });
    }

    const user = userQuery.Items[0];
    const resetToken = randomUUID();
    const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000).toISOString(); // 1 hour

    // Store token on user record
    await docClient.send(new UpdateCommand({
      TableName: TABLES.USERS,
      Key: { userId: user.userId },
      UpdateExpression: 'SET passwordResetToken = :token, resetTokenExpiry = :expiry',
      ExpressionAttributeValues: {
        ':token': resetToken,
        ':expiry': resetTokenExpiry
      }
    }));

    // Send reset email
    try {
      await sendPasswordResetEmail({
        to: user.email,
        resetToken,
        language: user.language || 'en'
      });
    } catch (emailError) {
      console.error('Failed to send password reset email:', emailError);
    }

    res.json({
      success: true,
      message: 'If an account with that email exists, a password reset link has been sent'
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to process password reset request'
    });
  }
});

// @route   POST /api/auth/reset-password
// @desc    Reset password using token
// @access  Public
router.post('/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Please provide token and new password'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Password must be at least 6 characters long'
      });
    }

    // Find user with this reset token
    // Scan is acceptable here since this is a rare operation
    const { ScanCommand } = require('@aws-sdk/lib-dynamodb');
    const scanResult = await docClient.send(new ScanCommand({
      TableName: TABLES.USERS,
      FilterExpression: 'passwordResetToken = :token',
      ExpressionAttributeValues: { ':token': token }
    }));

    if (!scanResult.Items || scanResult.Items.length === 0) {
      return res.status(400).json({
        error: 'Invalid token',
        message: 'This password reset link is invalid or has expired'
      });
    }

    const user = scanResult.Items[0];

    // Check token expiry
    if (new Date(user.resetTokenExpiry) < new Date()) {
      return res.status(400).json({
        error: 'Token expired',
        message: 'This password reset link has expired. Please request a new one'
      });
    }

    // Hash new password and update user
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await docClient.send(new UpdateCommand({
      TableName: TABLES.USERS,
      Key: { userId: user.userId },
      UpdateExpression: 'SET password = :password REMOVE passwordResetToken, resetTokenExpiry',
      ExpressionAttributeValues: {
        ':password': hashedPassword
      }
    }));

    res.json({
      success: true,
      message: 'Password has been reset successfully'
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to reset password'
    });
  }
});

module.exports = router;
