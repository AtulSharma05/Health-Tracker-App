const Food = require('../models/Food');
const { calculateTargets } = require('./nutritionCalculator');

const MEAL_SPLIT = [
  { mealType: 'Breakfast', ratio: 0.25 },
  { mealType: 'Lunch', ratio: 0.35 },
  { mealType: 'Dinner', ratio: 0.3 },
  { mealType: 'Snack', ratio: 0.1 },
];
const PLAN_DAYS = 7;

function round(value, digits = 1) {
  const p = 10 ** digits;
  return Math.round(value * p) / p;
}

/// Adjust macro targets based on user preferences
function adjustTargetsForPreferences(targets, preferences) {
  let adjusted = { ...targets };

  // High-protein adjustment: 30%+ of calories from protein
  if (preferences.highProtein) {
    adjusted.protein = (targets.calories * 0.30) / 4; // 4 cal/gram protein
    // Reduce carbs to compensate
    adjusted.carbs = (targets.calories * 0.40) / 4; // 4 cal/gram carbs
    adjusted.fats = (targets.calories * 0.30) / 9; // 9 cal/gram fats
  }

  // Low-carb adjustment: 20-30% of calories from carbs
  if (preferences.lowCarb) {
    adjusted.carbs = (targets.calories * 0.20) / 4; // 20% carbs
    adjusted.protein = (targets.calories * 0.35) / 4; // 35% protein
    adjusted.fats = (targets.calories * 0.45) / 9; // 45% fats (fills the gap)
  }

  // Custom calorie range
  if (preferences.calorieRange) {
    const { min, max } = preferences.calorieRange;
    if (min >= 1000 && max <= 5000) {
      const avgCalories = (min + max) / 2;
      const ratio = avgCalories / targets.calories;
      adjusted.calories = avgCalories;
      adjusted.protein *= ratio;
      adjusted.carbs *= ratio;
      adjusted.fats *= ratio;
    }
  }

  return {
    calories: round(adjusted.calories, 0),
    protein: round(adjusted.protein, 1),
    carbs: round(adjusted.carbs, 1),
    fats: round(adjusted.fats, 1),
  };
}

async function loadCandidateFoods(constraints) {
  const foods = await Food.find({}).lean();

  return foods.filter((food) => {
    const tags = Array.isArray(food.tags) ? food.tags : [];

    if (constraints.excludedFoods?.length && constraints.excludedFoods.includes(food.name)) {
      return false;
    }
    if (constraints.vegan && !tags.includes('vegan')) {
      return false;
    }
    if (constraints.vegetarian && !constraints.vegan && !tags.includes('vegetarian') && !tags.includes('vegan')) {
      return false;
    }
    if (constraints.glutenFree && !tags.includes('gluten-free')) {
      return false;
    }
    if (constraints.dairyFree && !tags.includes('dairy-free')) {
      return false;
    }
    if (constraints.indianOnly && !tags.includes('indian')) {
      return false;
    }

    return true;
  });
}

/// Score a food based on macro fit for the meal type
function scoreFoodForGoal(food, targets, preferences, mealType) {
  let score = 0;

  // Protein preference
  if (preferences.highProtein) {
    const proteinRatio = food.proteinG / (food.proteinG + food.carbsG + food.fatsG);
    score += proteinRatio * 50;
  }

  // Low-carb preference
  if (preferences.lowCarb) {
    const carbRatio = food.carbsG / (food.proteinG + food.carbsG + food.fatsG);
    score += (1 - carbRatio) * 50; // Higher score for lower carb foods
  }

  // Meal-specific preferences
  if (mealType === 'Breakfast' && food.category === 'grains') score += 10;
  if (mealType === 'Lunch' && (food.category === 'protein' || food.category === 'vegetables')) score += 15;
  if (mealType === 'Dinner' && (food.category === 'protein' || food.category === 'vegetables')) score += 15;
  if (mealType === 'Snack' && (food.category === 'fruits' || food.category === 'dairy')) score += 10;

  return score;
}

function pickFoodsForMealSmart(
  foods,
  targetCalories,
  targetProtein,
  targetCarbs,
  targetFats,
  mealType,
  usedFoodNames,
  preferences
) {
  const preferredCategoryByMeal = {
    Breakfast: ['grains', 'fruits', 'dairy', 'protein'],
    Lunch: ['protein', 'grains', 'vegetables', 'healthy_fats'],
    Dinner: ['protein', 'vegetables', 'grains', 'healthy_fats'],
    Snack: ['fruits', 'dairy', 'healthy_fats', 'protein'],
  };

  const categories = preferredCategoryByMeal[mealType] || ['other'];
  const selected = [];
  let calories = 0;
  let protein = 0;
  let carbs = 0;
  let fats = 0;

  for (const category of categories) {
    const pool = foods
      .filter(
        (f) =>
          f.category === category &&
          !usedFoodNames.has(f.name) &&
          Array.isArray(f.mealSlots) &&
          f.mealSlots.includes(mealType)
      )
      .map((f) => ({
        ...f,
        score: scoreFoodForGoal(f, { calories: targetCalories, protein: targetProtein, carbs: targetCarbs, fats: targetFats }, preferences, mealType),
      }))
      .sort((a, b) => b.score - a.score);

    if (!pool.length) continue;

    const food = pool[0]; // Pick highest-scoring food
    const remaining = Math.max(targetCalories - calories, targetCalories * 0.35);
    const grams = Math.max(60, Math.min(220, (remaining / Math.max(food.caloriesPer100g, 1)) * 100));

    const entry = {
      foodId: food._id,
      foodName: food.name,
      servings: round(grams / Math.max(food.servingSizeG || 100, 1), 2),
      grams: round(grams, 0),
      calories: round((food.caloriesPer100g * grams) / 100, 0),
      protein: round((food.proteinG * grams) / 100, 1),
      carbs: round((food.carbsG * grams) / 100, 1),
      fats: round((food.fatsG * grams) / 100, 1),
    };

    selected.push(entry);
    usedFoodNames.add(food.name);

    calories += entry.calories;
    protein += entry.protein;
    carbs += entry.carbs;
    fats += entry.fats;

    if (calories >= targetCalories * 0.92) break;
    if (selected.length >= 3) break;
  }

  return {
    foodItems: selected,
    totals: {
      calories: round(calories, 0),
      protein: round(protein, 1),
      carbs: round(carbs, 1),
      fats: round(fats, 1),
    },
  };
}

function buildDayDate(startDate, dayOffset) {
  const d = new Date(startDate);
  d.setDate(d.getDate() + dayOffset);
  return d;
}

async function generateMealPlan({
  userProfile,
  constraints,
  preferences = {},
}) {
  let calculation = calculateTargets(userProfile);
  let targets = {
    calories: calculation.results.targetCalories,
    protein: calculation.results.proteinG,
    carbs: calculation.results.carbsG,
    fats: calculation.results.fatsG,
  };

  // ✨ NEW: Adjust targets based on preferences
  targets = adjustTargetsForPreferences(targets, preferences);

  const foods = await loadCandidateFoods(constraints);

  if (!foods.length) {
    return {
      error: 'No foods available for selected constraints. Add foods or relax filters.',
      targets,
    };
  }

  const startDate = new Date();
  startDate.setHours(0, 0, 0, 0);

  const meals = [];
  const planTotals = { calories: 0, protein: 0, carbs: 0, fats: 0 };

  for (let day = 0; day < PLAN_DAYS; day++) {
    const usedFoodNames = new Set();

    for (const slot of MEAL_SPLIT) {
      // ✨ NEW: Use smart meal picker with preferences
      const meal = pickFoodsForMealSmart(
        foods,
        targets.calories * slot.ratio,
        targets.protein * slot.ratio,
        targets.carbs * slot.ratio,
        targets.fats * slot.ratio,
        slot.mealType,
        usedFoodNames,
        preferences
      );

      meals.push({
        date: buildDayDate(startDate, day),
        mealType: slot.mealType,
        foodItems: meal.foodItems,
        totals: meal.totals,
      });

      planTotals.calories += meal.totals.calories;
      planTotals.protein += meal.totals.protein;
      planTotals.carbs += meal.totals.carbs;
      planTotals.fats += meal.totals.fats;
    }
  }

  // ✨ NEW: Generate plan description
  const planDescription = _getPlanDescription(preferences, userProfile);

  return {
    meals,
    targets,
    planTotals: {
      calories: round(planTotals.calories, 0),
      protein: round(planTotals.protein, 1),
      carbs: round(planTotals.carbs, 1),
      fats: round(planTotals.fats, 1),
    },
    planDescription,
    preferences,
  };
}

function _getPlanDescription(preferences, userProfile) {
  const parts = [];

  if (preferences.highProtein) {
    parts.push('High-Protein Plan (30% of calories from protein)');
  } else if (preferences.lowCarb) {
    parts.push('Low-Carb Plan (20-30% of calories from carbs)');
  } else {
    parts.push('Balanced Nutrition Plan');
  }

  if (preferences.vegetarian || preferences.vegan) {
    parts.push(preferences.vegan ? 'Vegan' : 'Vegetarian');
  }

  if (preferences.glutenFree) parts.push('Gluten-Free');
  if (preferences.dairyFree) parts.push('Dairy-Free');

  return parts.join(' • ');
}

module.exports = {
  generateMealPlan,
};
