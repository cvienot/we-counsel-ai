const jwt = require('jsonwebtoken');
const { docClient, TABLES, GetCommand } = require('../config/database');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      error: 'Access token required',
      message: 'Please provide a valid access token'
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Fetch user from database to ensure they still exist
    const params = {
      TableName: TABLES.USERS,
      Key: { userId: decoded.userId }
    };

    const result = await docClient.send(new GetCommand(params));
    
    if (!result.Item) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'User not found'
      });
    }

    req.user = result.Item;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expired',
        message: 'Please log in again'
      });
    }
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'Please provide a valid access token'
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      error: 'Server error',
      message: 'Failed to authenticate token'
    });
  }
};

module.exports = {
  authenticateToken
};
