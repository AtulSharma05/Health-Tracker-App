const express = require('express');
const mongoose = require('mongoose');
const { requireUnifiedAuth: requireAuth } = require('../middleware/unifiedAuth');
const UserProfile = require('../models/UserProfile');
const { calculateTargets } = require('../utils/nutritionCalculator');

const router = express.Router();

function userObjectId(userId) {
  return new mongoose.Types.ObjectId(userId);
}

router.get('/', requireAuth, async (req, res) => {
  try {
    const profile = await UserProfile.findOne({ userId: userObjectId(req.user.id) });

    if (!profile) {
      return res.json({ profile: null, calculations: null });
    }

    const calculations = calculateTargets(profile.toObject());
    return res.json({ profile, calculations });
  } catch (error) {
    console.error('Fetch profile error:', error);
    return res.status(500).json({ message: 'Failed to fetch profile' });
  }
});

router.put('/', requireAuth, async (req, res) => {
  try {
    const payload = {
      weightKg: req.body.weightKg,
      heightCm: req.body.heightCm,
      age: req.body.age,
      bodyFatPercent: req.body.bodyFatPercent ?? null,
      gender: req.body.gender,
      activityLevel: req.body.activityLevel,
      goalType: req.body.goalType ?? 'recomp',
      aggressiveness: req.body.aggressiveness !== undefined ? Number(req.body.aggressiveness) : 2,
    };

    const profile = await UserProfile.findOneAndUpdate(
      { userId: userObjectId(req.user.id) },
      { $set: payload, $setOnInsert: { userId: userObjectId(req.user.id) } },
      { new: true, upsert: true, runValidators: true }
    );

    const calculations = calculateTargets(profile.toObject());
    return res.json({ profile, calculations });
  } catch (error) {
    if (error.name === 'ValidationError') {
      const firstError = Object.values(error.errors || {})[0];
      const message = firstError?.message || 'Invalid profile values';
      return res.status(400).json({ message });
    }
    console.error('Save profile error:', error);
    return res.status(500).json({ message: 'Failed to save profile' });
  }
});

module.exports = router;
