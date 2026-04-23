const aiPlannerService = require('../services/aiPlannerService');

/**
 * Generate personalized workout plan
 * POST /api/v1/workout-plans/generate
 */
exports.generatePlan = async (req, res) => {
  try {
    const {
      goal,
      experience,
      daysPerWeek,
      equipment,
      targetMuscles,
      duration,
      preferences
    } = req.body;

    // Validate required fields
    if (!goal || !experience || !daysPerWeek) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: goal, experience, daysPerWeek'
      });
    }

    // Check if AI server is running
    const isRunning = await aiPlannerService.isServerRunning();
    if (!isRunning) {
      return res.status(503).json({
        success: false,
        message: 'AI Planner service is not available. Please contact administrator.'
      });
    }

    // Generate workout plan
    const plan = await aiPlannerService.generateWorkoutPlan({
      goal,
      experience,
      daysPerWeek: parseInt(daysPerWeek),
      equipment: equipment || [],
      targetMuscles: targetMuscles || [],
      duration: duration || 60,
      preferences: preferences || {}
    });

    res.status(200).json({
      success: true,
      data: {
        plan,
        userId: req.user?._id || null,
        createdAt: new Date()
      }
    });

  } catch (error) {
    console.error('Error generating workout plan:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate workout plan',
      error: error.message
    });
  }
};

/**
 * Get exercise recommendations
 * POST /api/v1/workout-plans/recommend-exercises
 */
exports.recommendExercises = async (req, res) => {
  try {
    const {
      muscleGroup,
      equipment,
      difficulty,
      limit
    } = req.body;

    // Check if AI server is running
    const isRunning = await aiPlannerService.isServerRunning();
    if (!isRunning) {
      return res.status(503).json({
        success: false,
        message: 'AI Planner service is not available'
      });
    }

    // Get recommendations
    const exercises = await aiPlannerService.getExerciseRecommendations({
      muscleGroup,
      equipment: equipment || [],
      difficulty,
      limit: limit || 10
    });

    res.status(200).json({
      success: true,
      data: { exercises }
    });

  } catch (error) {
    console.error('Error getting exercise recommendations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get exercise recommendations',
      error: error.message
    });
  }
};

/**
 * Predict optimal sets and reps
 * POST /api/v1/workout-plans/predict-sets
 */
exports.predictSetsReps = async (req, res) => {
  try {
    const {
      exercise,
      goal,
      experience,
      maxWeight
    } = req.body;

    if (!exercise || !goal || !experience) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: exercise, goal, experience'
      });
    }

    // Check if AI server is running
    const isRunning = await aiPlannerService.isServerRunning();
    if (!isRunning) {
      return res.status(503).json({
        success: false,
        message: 'AI Planner service is not available'
      });
    }

    // Predict sets/reps
    const prediction = await aiPlannerService.predictSetsReps({
      exercise,
      goal,
      experience,
      maxWeight: maxWeight || null
    });

    res.status(200).json({
      success: true,
      data: { prediction }
    });

  } catch (error) {
    console.error('Error predicting sets/reps:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to predict sets/reps',
      error: error.message
    });
  }
};

/**
 * Check AI Planner service status
 * GET /api/v1/workout-plans/status
 */
exports.getStatus = async (req, res) => {
  try {
    const isRunning = await aiPlannerService.isServerRunning();
    
    res.status(200).json({
      success: true,
      data: {
        status: isRunning ? 'online' : 'offline',
        message: isRunning 
          ? 'AI Planner service is running' 
          : 'AI Planner service is not available'
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check service status',
      error: error.message
    });
  }
};
