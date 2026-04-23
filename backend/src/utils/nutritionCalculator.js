const ACTIVITY_FACTORS = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  very_active: 1.725,
  athlete: 1.9,
};

// Index 0 = mild (aggressiveness=1), 1 = moderate (=2), 2 = aggressive (=3)
const GOAL_PRESETS = {
  maintenance: { multipliers: [1.0,  1.0,  1.0 ], proteinPerKg: 1.8, fatsPerKg: 0.9, label: 'Maintenance'   },
  recomp:      { multipliers: [0.9,  0.9,  0.9 ], proteinPerKg: 2.2, fatsPerKg: 0.8, label: 'Recomposition'  },
  fat_loss:    { multipliers: [0.90, 0.85, 0.80], proteinPerKg: 2.4, fatsPerKg: 0.7, label: 'Fat Loss'        },
  muscle_gain: { multipliers: [1.05, 1.08, 1.12], proteinPerKg: 2.0, fatsPerKg: 1.0, label: 'Muscle Gain'    },
};

const AGG_LABELS = ['Mild', 'Moderate', 'Aggressive'];

function round(value, digits = 0) {
  const p = 10 ** digits;
  return Math.round(value * p) / p;
}

function calculateBmr({ weightKg, heightCm, age, gender }) {
  const s = gender === 'male' ? 5 : -161;
  return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + s;
}

function calculateTargets(profile) {
  const { weightKg, heightCm, age, bodyFatPercent, gender, activityLevel, goalType, aggressiveness } = profile;

  const bmr = calculateBmr({ weightKg, heightCm, age, gender });
  const activityFactor = ACTIVITY_FACTORS[activityLevel] || ACTIVITY_FACTORS.moderate;
  const maintenanceCalories = bmr * activityFactor;

  const preset = GOAL_PRESETS[goalType] || GOAL_PRESETS.recomp;
  const aggIndex = Math.max(0, Math.min(2, (aggressiveness || 2) - 1));
  const calorieMultiplier = preset.multipliers[aggIndex];
  const targetCalories = maintenanceCalories * calorieMultiplier;

  const aggLabel = AGG_LABELS[aggIndex];
  const goalLabel =
    goalType === 'maintenance' || goalType === 'recomp'
      ? preset.label
      : `${preset.label} – ${aggLabel}`;

  const leanMassKg = bodyFatPercent != null ? weightKg * (1 - bodyFatPercent / 100) : null;
  const proteinBaseKg = leanMassKg ?? weightKg;
  const { proteinPerKg, fatsPerKg } = preset;
  const proteinG = proteinBaseKg * proteinPerKg;
  const fatsG = weightKg * fatsPerKg;

  const proteinCalories = proteinG * 4;
  const fatCalories = fatsG * 9;
  const remainingCalories = Math.max(targetCalories - proteinCalories - fatCalories, 0);
  const carbsG = remainingCalories / 4;

  // kept for backward compatibility
  const recompCalories = maintenanceCalories * 0.9;

  return {
    inputs: { weightKg, heightCm, age, bodyFatPercent, gender, activityLevel, goalType, aggressiveness },
    factors: { activityFactor, proteinPerKg, fatsPerKg, calorieMultiplier, goalLabel },
    formulas: {
      bmr: 'Mifflin-St Jeor: 10*weight + 6.25*height - 5*age + s  (s = +5 male, -161 female)',
      maintenance: 'maintenanceCalories = BMR × activityFactor',
      target:
        goalType === 'fat_loss'
          ? `fatLossCalories = maintenance × ${calorieMultiplier}  (${aggLabel} deficit)`
          : goalType === 'muscle_gain'
            ? `muscleGainCalories = maintenance × ${calorieMultiplier}  (${aggLabel} surplus)`
            : goalType === 'recomp'
              ? 'recompCalories = maintenanceCalories × 0.90'
              : 'targetCalories = maintenanceCalories',
      protein: `proteinG = (leanMass or bodyWeight) × ${proteinPerKg} g/kg  (${goalLabel})`,
      fats:    `fatsG = bodyWeight × ${fatsPerKg} g/kg  (${goalLabel})`,
      carbs:   'carbsG = (targetCalories − proteinCalories − fatCalories) / 4',
    },
    results: {
      bmr: round(bmr),
      maintenanceCalories: round(maintenanceCalories),
      recompCalories: round(recompCalories),
      targetCalories: round(targetCalories),
      proteinG: round(proteinG),
      carbsG: round(carbsG),
      fatsG: round(fatsG),
      proteinCalories: round(proteinCalories),
      carbCalories: round(carbsG * 4),
      fatCalories: round(fatCalories),
      goalLabel,
    },
  };
}

module.exports = { calculateTargets };
