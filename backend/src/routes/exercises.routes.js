const express = require('express');
const router = express.Router();
const exerciseController = require('../controllers/exerciseController');

/**
 * @route   GET /api/v1/exercises/search
 * @desc    Search for exercise by name
 * @access  Public
 */
router.get('/search', exerciseController.searchExercise);

/**
 * @route   GET /api/v1/exercises
 * @desc    Get all exercises with optional filters
 * @access  Public
 */
router.get('/', exerciseController.getAllExercises);

module.exports = router;
