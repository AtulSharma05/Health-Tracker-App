const express = require('express');
const mongoose = require('mongoose');
const Meal = require('../models/Meal');
const { requireUnifiedAuth: requireAuth } = require('../middleware/unifiedAuth');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  const meals = await Meal.find({ userId: req.user.id }).sort({ createdAt: -1 });
  return res.json({ meals });
});

router.get('/stats', requireAuth, async (req, res) => {
  const periodDays = Math.min(Math.max(parseInt(req.query.periodDays || '7', 10), 1), 90);
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() - (periodDays - 1));

  let userObjectId;
  try {
    userObjectId = new mongoose.Types.ObjectId(req.user.id);
  } catch (_) {
    return res.status(400).json({ message: 'Invalid user id in token' });
  }

  const match = {
    userId: userObjectId,
    createdAt: { $gte: start },
  };

  const [dailyCalories, totalsResult] = await Promise.all([
    Meal.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            $dateToString: {
              format: '%Y-%m-%d',
              date: '$createdAt',
            },
          },
          calories: { $sum: '$calories' },
        },
      },
      { $sort: { _id: 1 } },
    ]),
    Meal.aggregate([
      { $match: match },
      {
        $group: {
          _id: null,
          calories: { $sum: '$calories' },
          protein: { $sum: '$protein' },
          carbs: { $sum: '$carbs' },
          fats: { $sum: '$fats' },
          meals: { $sum: 1 },
        },
      },
    ]),
  ]);

  const totals = totalsResult[0] || {
    calories: 0,
    protein: 0,
    carbs: 0,
    fats: 0,
    meals: 0,
  };

  return res.json({
    periodDays,
    dailyCalories: dailyCalories.map((d) => ({
      date: d._id,
      calories: d.calories,
    })),
    totals,
  });
});

router.post('/', requireAuth, async (req, res) => {
  const { mealName, mealType, calories, protein, carbs, fats } = req.body;

  if (!mealName || !mealType) {
    return res.status(400).json({ message: 'mealName and mealType are required' });
  }

  const meal = await Meal.create({
    userId: req.user.id,
    mealName,
    mealType,
    calories,
    protein,
    carbs,
    fats,
  });

  return res.status(201).json({ meal });
});

router.delete('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  const deleted = await Meal.findOneAndDelete({ _id: id, userId: req.user.id });

  if (!deleted) {
    return res.status(404).json({ message: 'Meal not found' });
  }

  return res.json({ message: 'Meal deleted' });
});

module.exports = router;
