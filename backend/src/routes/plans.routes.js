const express = require('express');
const mongoose = require('mongoose');
const { requireAuth } = require('../middleware/auth');
const UserProfile = require('../models/UserProfile');
const MealPlan = require('../models/MealPlan');
const { generateMealPlan } = require('../utils/mealPlanner');

const router = express.Router();

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

function userObjectId(userId) {
  return new mongoose.Types.ObjectId(userId);
}

router.post('/generate', requireAuth, asyncHandler(async (req, res) => {
  const duration = 7;
  const {
    planName = 'My Meal Plan',
    vegetarian = false,
    vegan = false,
    dairyFree = false,
    glutenFree = false,
    indianOnly = false,
    excludedFoods = [],
    // ✨ NEW: Macro preferences
    highProtein = false,
    lowCarb = false,
    calorieRange = { min: 1800, max: 2400 },
  } = req.body;

  const profile = await UserProfile.findOne({ userId: userObjectId(req.user.id) });
  if (!profile) {
    return res.status(400).json({ message: 'Profile not found. Complete onboarding first.' });
  }

  const constraints = {
    vegetarian: vegetarian || vegan,
    vegan,
    dairyFree,
    glutenFree,
    indianOnly,
    excludedFoods,
  };

  // ✨ NEW: Pass preferences to meal planner
  const preferences = {
    highProtein,
    lowCarb,
    calorieRange,
  };

  const generated = await generateMealPlan({
    userProfile: profile.toObject(),
    constraints,
    preferences,
  });

  if (generated.error) {
    return res.status(400).json(generated);
  }

  const mealPlan = await MealPlan.create({
    userId: userObjectId(req.user.id),
    planName,
    startDate: new Date(),
    duration,
    meals: generated.meals,
    targets: generated.targets,
    planTotals: generated.planTotals,
    constraints,
    preferences,
    status: 'active',
  });

  return res.status(201).json({
    planId: mealPlan._id,
    planName: mealPlan.planName,
    planDescription: generated.planDescription,
    duration: mealPlan.duration,
    startDate: mealPlan.startDate,
    targets: mealPlan.targets,
    planTotals: mealPlan.planTotals,
    meals: mealPlan.meals,
  });
}));

router.get('/', requireAuth, asyncHandler(async (req, res) => {
  const plans = await MealPlan.find({ userId: userObjectId(req.user.id) }).sort({ createdAt: -1 });
  return res.json({ plans, count: plans.length });
}));

router.get('/:id', requireAuth, asyncHandler(async (req, res) => {
  const plan = await MealPlan.findOne({ _id: req.params.id, userId: userObjectId(req.user.id) });
  if (!plan) {
    return res.status(404).json({ message: 'Plan not found' });
  }
  return res.json({ plan });
}));

router.put('/:id', requireAuth, asyncHandler(async (req, res) => {
  const update = {};
  if (req.body.planName !== undefined) update.planName = req.body.planName;
  if (req.body.status !== undefined) update.status = req.body.status;

  const plan = await MealPlan.findOneAndUpdate(
    { _id: req.params.id, userId: userObjectId(req.user.id) },
    { $set: update },
    { new: true, runValidators: true }
  );

  if (!plan) {
    return res.status(404).json({ message: 'Plan not found' });
  }

  return res.json({ plan });
}));

router.delete('/:id', requireAuth, asyncHandler(async (req, res) => {
  const deleted = await MealPlan.findOneAndDelete({ _id: req.params.id, userId: userObjectId(req.user.id) });
  if (!deleted) {
    return res.status(404).json({ message: 'Plan not found' });
  }
  return res.json({ message: 'Plan deleted' });
}));

module.exports = router;
