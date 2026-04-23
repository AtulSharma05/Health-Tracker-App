const mongoose = require('mongoose');

const userProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    weightKg: { type: Number, required: true, min: 20, max: 300 },
    heightCm: { type: Number, required: true, min: 100, max: 250 },
    age: { type: Number, required: true, min: 12, max: 100 },
    bodyFatPercent: { type: Number, min: 3, max: 60, default: null },
    gender: { type: String, enum: ['male', 'female'], required: true },
    activityLevel: {
      type: String,
      enum: ['sedentary', 'light', 'moderate', 'very_active', 'athlete'],
      required: true,
    },
    goalType: {
      type: String,
      enum: ['maintenance', 'recomp', 'fat_loss', 'muscle_gain'],
      default: 'recomp',
    },
    aggressiveness: { type: Number, min: 1, max: 3, default: 2 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserProfile', userProfileSchema);
