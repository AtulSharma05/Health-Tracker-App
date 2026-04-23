/**
 * Workout Controller
 * 
 * Handles all workout-related operations including CRUD operations,
 * statistics, and workout streaks. Includes user ownership validation.
 */

const Workout = require('../models/Workout');
const { catchAsync, APIError } = require('../middleware/errorHandler');
const mongoose = require('mongoose');

/**
 * @desc    Create a new workout
 * @route   POST /api/v1/workouts
 * @access  Private (requires authentication)
 */
const createWorkout = catchAsync(async (req, res) => {
  const {
    exerciseName,
    workoutType,
    duration,
    caloriesBurned,
    date,
    sets,
    reps,
    weight,
    notes,
    intensityLevel
  } = req.body;

  // Validate required fields
  if (!exerciseName || !duration) {
    throw new APIError('Exercise name and duration are required', 400);
  }

  // Create workout with user ID from auth middleware
  const workout = await Workout.create({
    userId: req.user._id,
    exerciseName: exerciseName.trim(),
    workoutType,
    duration: Number(duration),
    caloriesBurned: caloriesBurned ? Number(caloriesBurned) : undefined,
    date: date ? new Date(date) : new Date(),
    sets: sets ? Number(sets) : undefined,
    reps: reps ? Number(reps) : undefined,
    weight: weight ? Number(weight) : undefined,
    notes: notes ? notes.trim() : undefined,
    intensityLevel
  });

  res.status(201).json({
    success: true,
    message: 'Workout created successfully',
    data: {
      workout
    }
  });
});

/**
 * @desc    Get all workouts for authenticated user
 * @route   GET /api/v1/workouts
 * @access  Private
 * @query   ?limit=10&page=1&startDate=2023-01-01&endDate=2023-12-31&workoutType=cardio
 */
const getWorkouts = catchAsync(async (req, res) => {
  const {
    limit = 20,
    page = 1,
    startDate,
    endDate,
    workoutType,
    sortBy = 'date',
    sortOrder = 'desc'
  } = req.query;

  // Build query filters
  const filters = { userId: req.user._id };

  // Date range filter
  if (startDate || endDate) {
    filters.date = {};
    if (startDate) filters.date.$gte = new Date(startDate);
    if (endDate) filters.date.$lte = new Date(endDate);
  }

  // Workout type filter
  if (workoutType) {
    filters.workoutType = workoutType;
  }

  // Build sort object
  const sort = {};
  sort[sortBy] = sortOrder === 'asc' ? 1 : -1;

  // Calculate pagination
  const skip = (Number(page) - 1) * Number(limit);

  // Execute query with pagination
  const [workouts, totalCount] = await Promise.all([
    Workout.find(filters)
      .sort(sort)
      .limit(Number(limit))
      .skip(skip)
      .select('-__v'),
    Workout.countDocuments(filters)
  ]);

  // Calculate pagination info
  const totalPages = Math.ceil(totalCount / Number(limit));

  res.status(200).json({
    success: true,
    message: 'Workouts retrieved successfully',
    data: {
      workouts,
      pagination: {
        currentPage: Number(page),
        totalPages,
        totalCount,
        hasNextPage: Number(page) < totalPages,
        hasPrevPage: Number(page) > 1
      }
    }
  });
});

/**
 * @desc    Get a single workout by ID
 * @route   GET /api/v1/workouts/:id
 * @access  Private
 */
const getWorkoutById = catchAsync(async (req, res) => {
  const { id } = req.params;

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new APIError('Invalid workout ID', 400);
  }

  const workout = await Workout.findOne({
    _id: id,
    userId: req.user._id // Ensure user owns this workout
  }).select('-__v');

  if (!workout) {
    throw new APIError('Workout not found', 404);
  }

  res.status(200).json({
    success: true,
    message: 'Workout retrieved successfully',
    data: {
      workout
    }
  });
});

/**
 * @desc    Update a workout
 * @route   PUT /api/v1/workouts/:id
 * @access  Private
 */
const updateWorkout = catchAsync(async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new APIError('Invalid workout ID', 400);
  }

  // Remove fields that shouldn't be updated
  delete updateData.userId;
  delete updateData._id;
  delete updateData.createdAt;
  delete updateData.updatedAt;

  // Trim string fields
  if (updateData.exerciseName) {
    updateData.exerciseName = updateData.exerciseName.trim();
  }
  if (updateData.notes) {
    updateData.notes = updateData.notes.trim();
  }

  const workout = await Workout.findOneAndUpdate(
    { _id: id, userId: req.user._id },
    updateData,
    {
      new: true, // Return updated document
      runValidators: true // Run schema validations
    }
  ).select('-__v');

  if (!workout) {
    throw new APIError('Workout not found', 404);
  }

  res.status(200).json({
    success: true,
    message: 'Workout updated successfully',
    data: {
      workout
    }
  });
});

/**
 * @desc    Delete a workout
 * @route   DELETE /api/v1/workouts/:id
 * @access  Private
 */
const deleteWorkout = catchAsync(async (req, res) => {
  const { id } = req.params;

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new APIError('Invalid workout ID', 400);
  }

  const workout = await Workout.findOneAndDelete({
    _id: id,
    userId: req.user._id
  });

  if (!workout) {
    throw new APIError('Workout not found', 404);
  }

  res.status(200).json({
    success: true,
    message: 'Workout deleted successfully',
    data: null
  });
});

/**
 * @desc    Get workout statistics for authenticated user
 * @route   GET /api/v1/workouts/stats
 * @access  Private
 * @query   ?startDate=2023-01-01&endDate=2023-12-31
 */
const getWorkoutStats = catchAsync(async (req, res) => {
  const { startDate, endDate } = req.query;

  // Set date range (default to last 30 days if not provided)
  const endDateTime = endDate ? new Date(endDate) : new Date();
  const startDateTime = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

  // Get basic stats
  const stats = await Workout.getUserStats(req.user._id, startDateTime, endDateTime);
  
  // Get workout streak
  const currentStreak = await Workout.getWorkoutStreak(req.user._id);

  // Get workout frequency by type
  const workoutsByType = await Workout.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(req.user._id),
        date: { $gte: startDateTime, $lte: endDateTime }
      }
    },
    {
      $group: {
        _id: '$workoutType',
        count: { $sum: 1 },
        totalDuration: { $sum: '$duration' },
        totalCalories: { $sum: '$caloriesBurned' }
      }
    },
    {
      $sort: { count: -1 }
    }
  ]);

  // Get most frequent exercises
  const topExercises = await Workout.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(req.user._id),
        date: { $gte: startDateTime, $lte: endDateTime }
      }
    },
    {
      $group: {
        _id: '$exerciseName',
        count: { $sum: 1 },
        avgDuration: { $avg: '$duration' },
        avgCalories: { $avg: '$caloriesBurned' }
      }
    },
    {
      $sort: { count: -1 }
    },
    {
      $limit: 10
    }
  ]);

  // Get weekly progress (last 8 weeks)
  const weeklyProgress = await Workout.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(req.user._id),
        date: { $gte: new Date(Date.now() - 56 * 24 * 60 * 60 * 1000) } // 8 weeks
      }
    },
    {
      $group: {
        _id: {
          year: { $year: '$date' },
          week: { $week: '$date' }
        },
        workoutCount: { $sum: 1 },
        totalDuration: { $sum: '$duration' },
        totalCalories: { $sum: '$caloriesBurned' }
      }
    },
    {
      $sort: { '_id.year': 1, '_id.week': 1 }
    }
  ]);

  res.status(200).json({
    success: true,
    message: 'Workout statistics retrieved successfully',
    data: {
      period: {
        startDate: startDateTime,
        endDate: endDateTime
      },
      overview: {
        ...stats,
        currentStreak
      },
      workoutsByType,
      topExercises,
      weeklyProgress
    }
  });
});

/**
 * @desc    Get recent workouts (last 7 days)
 * @route   GET /api/v1/workouts/recent
 * @access  Private
 */
const getRecentWorkouts = catchAsync(async (req, res) => {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  const recentWorkouts = await Workout.find({
    userId: req.user._id,
    date: { $gte: sevenDaysAgo }
  })
  .sort({ date: -1 })
  .limit(10)
  .select('-__v');

  res.status(200).json({
    success: true,
    message: 'Recent workouts retrieved successfully',
    data: {
      workouts: recentWorkouts,
      count: recentWorkouts.length
    }
  });
});

module.exports = {
  createWorkout,
  getWorkouts,
  getWorkoutById,
  updateWorkout,
  deleteWorkout,
  getWorkoutStats,
  getRecentWorkouts
};