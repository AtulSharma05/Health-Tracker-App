/**
 * Workout Model
 * 
 * Mongoose schema for workout tracking data
 * Includes exercise details, duration, calories, and user association
 */

const mongoose = require('mongoose');

const workoutSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required'],
    index: true // For efficient querying by user
  },
  
  exerciseName: {
    type: String,
    required: [true, 'Exercise name is required'],
    trim: true,
    maxlength: [100, 'Exercise name cannot exceed 100 characters']
  },
  
  workoutType: {
    type: String,
    enum: ['cardio', 'strength', 'flexibility', 'sports', 'other'],
    default: 'other'
  },
  
  duration: {
    type: Number, // Duration in minutes
    required: [true, 'Duration is required'],
    min: [1, 'Duration must be at least 1 minute'],
    max: [600, 'Duration cannot exceed 10 hours']
  },
  
  caloriesBurned: {
    type: Number,
    min: [0, 'Calories burned cannot be negative'],
    max: [5000, 'Calories burned seems too high']
  },
  
  date: {
    type: Date,
    required: [true, 'Workout date is required'],
    default: Date.now,
    validate: {
      validator: function(value) {
        // Don't allow future dates beyond tomorrow
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        return value <= tomorrow;
      },
      message: 'Workout date cannot be in the future'
    }
  },
  
  // Optional fields for strength training
  sets: {
    type: Number,
    min: [1, 'Sets must be at least 1'],
    max: [50, 'Sets cannot exceed 50']
  },
  
  reps: {
    type: Number,
    min: [1, 'Reps must be at least 1'],
    max: [1000, 'Reps cannot exceed 1000']
  },
  
  weight: {
    type: Number, // Weight in kg
    min: [0.5, 'Weight must be at least 0.5 kg'],
    max: [500, 'Weight cannot exceed 500 kg']
  },
  
  notes: {
    type: String,
    maxlength: [500, 'Notes cannot exceed 500 characters'],
    trim: true
  },
  
  // For tracking intensity level
  intensityLevel: {
    type: String,
    enum: ['low', 'moderate', 'high', 'extreme'],
    default: 'moderate'
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for efficient querying
workoutSchema.index({ userId: 1, date: -1 }); // Query workouts by user and date
workoutSchema.index({ userId: 1, workoutType: 1 }); // Query by user and type
workoutSchema.index({ date: -1 }); // Query recent workouts

// Virtual for calories per minute
workoutSchema.virtual('caloriesPerMinute').get(function() {
  return this.duration > 0 ? Math.round((this.caloriesBurned / this.duration) * 100) / 100 : 0;
});

// Instance method to check if workout is today
workoutSchema.methods.isToday = function() {
  const today = new Date();
  const workoutDate = this.date;
  
  return today.getDate() === workoutDate.getDate() &&
         today.getMonth() === workoutDate.getMonth() &&
         today.getFullYear() === workoutDate.getFullYear();
};

// Static method to get user's workout stats
workoutSchema.statics.getUserStats = async function(userId, startDate, endDate) {
  const stats = await this.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(userId),
        date: {
          $gte: startDate || new Date(0),
          $lte: endDate || new Date()
        }
      }
    },
    {
      $group: {
        _id: null,
        totalWorkouts: { $sum: 1 },
        totalDuration: { $sum: '$duration' },
        totalCalories: { $sum: '$caloriesBurned' },
        avgDuration: { $avg: '$duration' },
        avgCalories: { $avg: '$caloriesBurned' },
        workoutTypes: { $addToSet: '$workoutType' },
        mostFrequentExercise: { $first: '$exerciseName' }
      }
    }
  ]);
  
  return stats.length > 0 ? stats[0] : {
    totalWorkouts: 0,
    totalDuration: 0,
    totalCalories: 0,
    avgDuration: 0,
    avgCalories: 0,
    workoutTypes: [],
    mostFrequentExercise: null
  };
};

// Static method to calculate workout streak
workoutSchema.statics.getWorkoutStreak = async function(userId) {
  const workouts = await this.find(
    { userId },
    { date: 1 },
    { sort: { date: -1 } }
  );
  
  if (workouts.length === 0) return 0;
  
  // Get unique workout dates (in case multiple workouts on same day)
  const uniqueDates = [...new Set(workouts.map(w => {
    const d = new Date(w.date);
    d.setHours(0, 0, 0, 0);
    return d.getTime();
  }))].sort((a, b) => b - a); // Sort descending
  
  if (uniqueDates.length === 0) return 0;
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayTime = today.getTime();
  
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayTime = yesterday.getTime();
  
  // Check if the most recent workout is today or yesterday
  const mostRecentWorkout = uniqueDates[0];
  if (mostRecentWorkout !== todayTime && mostRecentWorkout !== yesterdayTime) {
    return 0; // Streak broken - no workout today or yesterday
  }
  
  // Count consecutive days
  let streak = 1;
  for (let i = 1; i < uniqueDates.length; i++) {
    const currentDay = uniqueDates[i - 1];
    const previousDay = uniqueDates[i];
    
    // Calculate difference in days
    const daysDiff = Math.round((currentDay - previousDay) / (1000 * 60 * 60 * 24));
    
    if (daysDiff === 1) {
      // Consecutive day
      streak++;
    } else {
      // Gap found, stop counting
      break;
    }
  }
  
  return streak;
};

// Pre-save middleware for data validation
workoutSchema.pre('save', function(next) {
  // Ensure date is not in future
  if (this.date > new Date()) {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    if (this.date > tomorrow) {
      return next(new Error('Workout date cannot be in the future'));
    }
  }
  
  // Auto-calculate calories if not provided (rough estimation)
  if (!this.caloriesBurned && this.duration) {
    const caloriesPerMinute = {
      'cardio': 8,
      'strength': 6,
      'flexibility': 3,
      'sports': 10,
      'other': 5
    };
    
    this.caloriesBurned = this.duration * (caloriesPerMinute[this.workoutType] || 5);
  }
  
  next();
});

const Workout = mongoose.model('Workout', workoutSchema);

module.exports = Workout;