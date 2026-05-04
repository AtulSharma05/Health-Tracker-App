const mongoose = require('mongoose');

const foodLogSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    imageBase64: { type: String }, // optional: store thumbnail for history
    foodName: { type: String, required: true, trim: true },
    mealType: {
      type: String,
      enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
      default: 'Snack',
    },
    calories: { type: Number, required: true, min: 0 },
    protein: { type: Number, required: true, min: 0 },
    carbs: { type: Number, required: true, min: 0 },
    fats: { type: Number, required: true, min: 0 },
    fiber: { type: Number, default: 0, min: 0 },
    confidence: { type: Number, default: 0, min: 0, max: 1 },
    aiRawResponse: { type: String }, // store raw AI response for debugging
    savedToMeals: { type: Boolean, default: false },
    mealId: { type: mongoose.Schema.Types.ObjectId, ref: 'Meal' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('FoodLog', foodLogSchema);
