/**
 * Workout Routes
 * 
 * RESTful API endpoints for workout tracking
 * All routes require authentication
 */

const express = require('express');
const {
  createWorkout,
  getWorkouts,
  getWorkoutById,
  updateWorkout,
  deleteWorkout,
  getWorkoutStats,
  getRecentWorkouts
} = require('../controllers/workoutController');
const { requireUnifiedAuth } = require('../middleware/unifiedAuth');

const router = express.Router();

// Apply authentication middleware to all workout routes
router.use(requireUnifiedAuth);

/**
 * @route   GET /api/v1/workouts/stats
 * @desc    Get workout statistics for authenticated user
 * @access  Private
 * @query   ?startDate=2023-01-01&endDate=2023-12-31
 */
router.get('/stats', getWorkoutStats);

/**
 * @route   GET /api/v1/workouts/recent
 * @desc    Get recent workouts (last 7 days)
 * @access  Private
 */
router.get('/recent', getRecentWorkouts);

/**
 * @route   GET /api/v1/workouts
 * @desc    Get all workouts for authenticated user (with pagination and filters)
 * @access  Private
 * @query   ?limit=20&page=1&startDate=2023-01-01&endDate=2023-12-31&workoutType=cardio&sortBy=date&sortOrder=desc
 */
router.get('/', getWorkouts);

/**
 * @route   POST /api/v1/workouts
 * @desc    Create a new workout
 * @access  Private
 * @body    {
 *   exerciseName: string (required),
 *   workoutType: string (cardio|strength|flexibility|sports|other),
 *   duration: number (required, in minutes),
 *   caloriesBurned: number (optional, auto-calculated if not provided),
 *   date: string (optional, defaults to now),
 *   sets: number (optional),
 *   reps: number (optional),
 *   weight: number (optional, in kg),
 *   notes: string (optional),
 *   intensityLevel: string (low|moderate|high|extreme)
 * }
 */
router.post('/', createWorkout);

/**
 * @route   GET /api/v1/workouts/:id
 * @desc    Get a single workout by ID
 * @access  Private (user can only access their own workouts)
 */
router.get('/:id', getWorkoutById);

/**
 * @route   PUT /api/v1/workouts/:id
 * @desc    Update a workout
 * @access  Private (user can only update their own workouts)
 * @body    Same as POST, all fields optional
 */
router.put('/:id', updateWorkout);

/**
 * @route   DELETE /api/v1/workouts/:id
 * @desc    Delete a workout
 * @access  Private (user can only delete their own workouts)
 */
router.delete('/:id', deleteWorkout);

module.exports = router;