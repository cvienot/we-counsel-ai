const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const progressService = require('../services/progressService');

const router = express.Router();

/**
 * GET /api/progress/dashboard
 * Get full progress dashboard data for the authenticated user's couple
 */
router.get('/dashboard', authenticateToken, async (req, res) => {
  try {
    const coupleId = req.user.coupleId;

    if (!coupleId) {
      return res.status(400).json({
        error: 'No couple found',
        message: 'You need to be connected with a partner to view progress',
      });
    }

    const dashboard = await progressService.getDashboard(coupleId);

    res.json({
      success: true,
      ...dashboard,
    });
  } catch (error) {
    console.error('Progress dashboard error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to load progress dashboard',
    });
  }
});

/**
 * GET /api/progress/exercises
 * Get exercise statistics only
 */
router.get('/exercises', authenticateToken, async (req, res) => {
  try {
    const coupleId = req.user.coupleId;

    if (!coupleId) {
      return res.status(400).json({
        error: 'No couple found',
        message: 'You need to be connected with a partner to view progress',
      });
    }

    const exerciseStats = await progressService.getExerciseStats(coupleId);

    res.json({
      success: true,
      exerciseStats,
    });
  } catch (error) {
    console.error('Exercise stats error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to load exercise statistics',
    });
  }
});

/**
 * GET /api/progress/activity
 * Get weekly activity data
 */
router.get('/activity', authenticateToken, async (req, res) => {
  try {
    const coupleId = req.user.coupleId;

    if (!coupleId) {
      return res.status(400).json({
        error: 'No couple found',
        message: 'You need to be connected with a partner to view progress',
      });
    }

    const [weeklyActivity, streak] = await Promise.all([
      progressService.getWeeklyActivity(coupleId),
      progressService.getActivityStreak(coupleId),
    ]);

    res.json({
      success: true,
      weeklyActivity,
      streak,
    });
  } catch (error) {
    console.error('Activity stats error:', error);
    res.status(500).json({
      error: 'Server error',
      message: 'Failed to load activity data',
    });
  }
});

module.exports = router;
