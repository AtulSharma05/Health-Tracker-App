const express = require('express');
const router = express.Router();
const poseAnalysisService = require('../services/poseAnalysisService');
const { requireUnifiedAuth } = require('../middleware/unifiedAuth');

/**
 * @route   GET /api/v1/pose/health
 * @desc    Check if pose analysis API is available
 * @access  Public
 */
router.get('/health', async (req, res) => {
  try {
    const isHealthy = await poseAnalysisService.checkPoseApiHealth();
    
    res.json({
      status: isHealthy ? 'available' : 'unavailable',
      message: isHealthy 
        ? 'Pose analysis API is running' 
        : 'Pose analysis API is not responding',
      apiUrl: process.env.POSE_API_URL || 'http://localhost:8001'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

/**
 * @route   POST /api/v1/pose/start-session
 * @desc    Start a new pose analysis session for an exercise
 * @access  Private
 */
router.post('/start-session', requireUnifiedAuth, async (req, res) => {
  try {
    const { exerciseName } = req.body;
    
    if (!exerciseName) {
      return res.status(400).json({
        success: false,
        message: 'Exercise name is required'
      });
    }

    const session = await poseAnalysisService.startExerciseSession(exerciseName);
    
    res.json(session);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route   GET /api/v1/pose/session-summary
 * @desc    Get current session summary and statistics
 * @access  Private
 */
router.get('/session-summary', requireUnifiedAuth, async (req, res) => {
  try {
    const summary = await poseAnalysisService.getSessionSummary();
    
    res.json({
      success: true,
      data: summary
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route   POST /api/v1/pose/reset
 * @desc    Reset the current pose analysis session
 * @access  Private
 */
router.post('/reset', requireUnifiedAuth, async (req, res) => {
  try {
    const result = await poseAnalysisService.resetSession();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route   GET /api/v1/pose/search
 * @desc    Search for exercises in the pose tracking database
 * @access  Public
 */
router.get('/search', (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const results = poseAnalysisService.searchExercises(q);
    
    res.json({
      success: true,
      count: results.length,
      results
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route   GET /api/v1/pose/exercises
 * @desc    Get all exercises with pose tracking support
 * @access  Public
 */
router.get('/exercises', (req, res) => {
  try {
    const exercises = poseAnalysisService.getAllExercises();
    
    res.json({
      success: true,
      count: exercises.length,
      exercises: exercises.slice(0, 100) // Limit to first 100 for performance
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route   GET /api/v1/pose/exercise-id/:exerciseName
 * @desc    Get pose tracking ID for a specific exercise name
 * @access  Public
 */
router.get('/exercise-id/:exerciseName', (req, res) => {
  try {
    const { exerciseName } = req.params;
    const exerciseId = poseAnalysisService.getExerciseId(exerciseName);
    
    if (!exerciseId) {
      return res.status(404).json({
        success: false,
        message: `No pose tracking data found for exercise: ${exerciseName}`
      });
    }

    res.json({
      success: true,
      exerciseName,
      exerciseId
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
