const jwt = require('jsonwebtoken');
const { docClient, TABLES } = require('../config/database');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'No token provided'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const params = {
      TableName: TABLES.USERS,
      Key: { userId: decoded.userId }
    };

    const result = await docClient.get(params).promise();

    if (!result.Item) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Invalid token'
      });
    }

    // Check if user is active
    if (!result.Item.isActive) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Account is disabled'
      });
    }

    // Add user to request object
    req.user = result.Item;
    next();

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Invalid token'
      });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Token expired'
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      error: 'Server error',
      message: 'Authentication failed'
    });
  }
};

module.exports = { authenticateToken };
