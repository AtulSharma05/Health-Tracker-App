const mongoose = require('mongoose');

const foodSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, index: true },
    category: {
      type: String,
      enum: ['protein', 'carbs', 'fruits', 'vegetables', 'dairy', 'grains', 'healthy_fats', 'other'],
      required: true,
      index: true,
    },
    caloriesPer100g: { type: Number, required: true, min: 0 },
    proteinG: { type: Number, required: true, min: 0 },
    carbsG: { type: Number, required: true, min: 0 },
    fatsG: { type: Number, required: true, min: 0 },
    fiberG: { type: Number, default: 0, min: 0 },
    servingSizeG: { type: Number, default: 100, min: 1 },
    mealSlots: [{ type: String, enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack'] }],
    tags: [{ type: String, lowercase: true }],
    costUSD: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Food', foodSchema);
