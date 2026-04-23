const express = require('express');
const Food = require('../models/Food');
const { requireUnifiedAuth: requireAuth } = require('../middleware/unifiedAuth');

const router = express.Router();

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Autocomplete search endpoint - optimized for quick food lookup
router.get('/search', requireAuth, asyncHandler(async (req, res) => {
  const { q = '', category, limit = 20 } = req.query;
  const query = {};

  if (q && q.trim()) {
    query.name = { $regex: q.trim(), $options: 'i' };
  }

  if (category) {
    query.category = category;
  }

  const foods = await Food.find(query)
    .select('name category caloriesPer100g proteinG carbsG fatsG fiberG servingSizeG mealSlots tags')
    .limit(Math.max(1, Math.min(Number(limit), 50)))
    .sort({ name: 1 });

  return res.json({ foods, count: foods.length });
}));

// General food search with filters
router.get('/', requireAuth, asyncHandler(async (req, res) => {
  const { category, search, limit = 50 } = req.query;
  const query = {};

  if (category) query.category = category;
  if (search) query.name = { $regex: search, $options: 'i' };

  const foods = await Food.find(query)
    .limit(Math.max(1, Math.min(Number(limit), 200)))
    .sort({ name: 1 });
  return res.json({ foods, count: foods.length });
}));

// Create a new food item
router.post('/', requireAuth, asyncHandler(async (req, res) => {
  const food = await Food.create(req.body);
  return res.status(201).json({ food });
}));

module.exports = router;
