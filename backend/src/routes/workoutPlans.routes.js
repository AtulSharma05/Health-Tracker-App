const express = require('express');
const router = express.Router();
const workoutPlanController = require('../controllers/workoutPlanController');
const { requireUnifiedAuth } = require('../middleware/unifiedAuth');

// All routes require authentication
router.use(requireUnifiedAuth);

/**
 * @route   POST /api/v1/workout-plans/generate
 * @desc    Generate personalized workout plan using AI
 * @access  Private
 */
router.post('/generate', workoutPlanController.generatePlan);

/**
 * @route   POST /api/v1/workout-plans/recommend-exercises
 * @desc    Get AI-powered exercise recommendations
 * @access  Private
 */
router.post('/recommend-exercises', workoutPlanController.recommendExercises);

/**
 * @route   POST /api/v1/workout-plans/predict-sets
 * @desc    Predict optimal sets and reps for exercise
 * @access  Private
 */
router.post('/predict-sets', workoutPlanController.predictSetsReps);

/**
 * @route   GET /api/v1/workout-plans/status
 * @desc    Check AI Planner service status
 * @access  Private
 */
router.get('/status', workoutPlanController.getStatus);

module.exports = router;
