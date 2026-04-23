require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/db');
const Food = require('../models/Food');

const FOODS = [
  { name: 'Chicken Breast', category: 'protein', caloriesPer100g: 165, proteinG: 31, carbsG: 0, fatsG: 3.6, mealSlots: ['Lunch', 'Dinner'], tags: ['high-protein', 'dairy-free', 'gluten-free'], servingSizeG: 120 },
  { name: 'Egg', category: 'protein', caloriesPer100g: 155, proteinG: 13, carbsG: 1.1, fatsG: 11, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 50 },
  { name: 'Tofu', category: 'protein', caloriesPer100g: 76, proteinG: 8, carbsG: 1.9, fatsG: 4.8, mealSlots: ['Lunch', 'Dinner'], tags: ['vegan', 'vegetarian', 'dairy-free', 'gluten-free'], servingSizeG: 150 },
  { name: 'Greek Yogurt', category: 'dairy', caloriesPer100g: 59, proteinG: 10, carbsG: 3.6, fatsG: 0.4, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 150 },
  { name: 'Salmon', category: 'protein', caloriesPer100g: 208, proteinG: 20, carbsG: 0, fatsG: 13, mealSlots: ['Lunch', 'Dinner'], tags: ['high-protein', 'dairy-free', 'gluten-free'], servingSizeG: 120 },
  { name: 'Brown Rice', category: 'grains', caloriesPer100g: 111, proteinG: 2.6, carbsG: 23, fatsG: 0.9, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 150 },
  { name: 'Oats', category: 'grains', caloriesPer100g: 389, proteinG: 17, carbsG: 66, fatsG: 6.9, mealSlots: ['Breakfast'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 50 },
  { name: 'Whole Wheat Bread', category: 'grains', caloriesPer100g: 247, proteinG: 13, carbsG: 41, fatsG: 4.2, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'vegan', 'dairy-free'], servingSizeG: 35 },
  { name: 'Sweet Potato', category: 'carbs', caloriesPer100g: 86, proteinG: 1.6, carbsG: 20, fatsG: 0.1, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 180 },
  { name: 'Banana', category: 'fruits', caloriesPer100g: 89, proteinG: 1.1, carbsG: 23, fatsG: 0.3, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 120 },
  { name: 'Apple', category: 'fruits', caloriesPer100g: 52, proteinG: 0.3, carbsG: 14, fatsG: 0.2, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 150 },
  { name: 'Blueberries', category: 'fruits', caloriesPer100g: 57, proteinG: 0.7, carbsG: 14, fatsG: 0.3, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 100 },
  { name: 'Broccoli', category: 'vegetables', caloriesPer100g: 34, proteinG: 2.8, carbsG: 7, fatsG: 0.4, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 120 },
  { name: 'Spinach', category: 'vegetables', caloriesPer100g: 23, proteinG: 2.9, carbsG: 3.6, fatsG: 0.4, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 80 },
  { name: 'Mixed Salad', category: 'vegetables', caloriesPer100g: 20, proteinG: 1.5, carbsG: 3.5, fatsG: 0.2, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 120 },
  { name: 'Olive Oil', category: 'healthy_fats', caloriesPer100g: 884, proteinG: 0, carbsG: 0, fatsG: 100, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 15 },
  { name: 'Almonds', category: 'healthy_fats', caloriesPer100g: 579, proteinG: 21, carbsG: 22, fatsG: 50, mealSlots: ['Snack', 'Breakfast'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 28 },
  { name: 'Avocado', category: 'healthy_fats', caloriesPer100g: 160, proteinG: 2, carbsG: 9, fatsG: 15, mealSlots: ['Breakfast', 'Lunch'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 100 },
  { name: 'Cottage Cheese', category: 'dairy', caloriesPer100g: 98, proteinG: 11, carbsG: 3.4, fatsG: 4.3, mealSlots: ['Breakfast', 'Lunch'], tags: ['vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 100 },
  { name: 'Chickpeas', category: 'protein', caloriesPer100g: 164, proteinG: 8.9, carbsG: 27.4, fatsG: 2.6, mealSlots: ['Lunch', 'Dinner'], tags: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free'], servingSizeG: 140 },
  { name: 'Moong Dal Chilla', category: 'protein', caloriesPer100g: 150, proteinG: 9.5, carbsG: 18, fatsG: 4.5, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'high-protein', 'dairy-free', 'gluten-free'], servingSizeG: 120 },
  { name: 'Vegetable Upma', category: 'grains', caloriesPer100g: 160, proteinG: 4, carbsG: 24, fatsG: 5.5, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free'], servingSizeG: 180 },
  { name: 'Poha', category: 'grains', caloriesPer100g: 130, proteinG: 3, carbsG: 23, fatsG: 3, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 180 },
  { name: 'Idli', category: 'grains', caloriesPer100g: 146, proteinG: 4.5, carbsG: 29, fatsG: 1, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 110 },
  { name: 'Dosa', category: 'grains', caloriesPer100g: 168, proteinG: 4.5, carbsG: 28, fatsG: 4, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 120 },
  { name: 'Sambar', category: 'vegetables', caloriesPer100g: 75, proteinG: 3.5, carbsG: 10, fatsG: 2.2, mealSlots: ['Breakfast', 'Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 200 },
  { name: 'Roti', category: 'grains', caloriesPer100g: 297, proteinG: 9, carbsG: 55, fatsG: 3.7, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free'], servingSizeG: 40 },
  { name: 'Jeera Rice', category: 'grains', caloriesPer100g: 170, proteinG: 3.2, carbsG: 31, fatsG: 3.2, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 150 },
  { name: 'Rajma Curry', category: 'protein', caloriesPer100g: 140, proteinG: 6.8, carbsG: 18, fatsG: 4.5, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 180 },
  { name: 'Chana Masala', category: 'protein', caloriesPer100g: 150, proteinG: 7.2, carbsG: 20, fatsG: 4.8, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 180 },
  { name: 'Dal Tadka', category: 'protein', caloriesPer100g: 132, proteinG: 7.5, carbsG: 16, fatsG: 4.1, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 180 },
  { name: 'Paneer Bhurji', category: 'protein', caloriesPer100g: 195, proteinG: 14, carbsG: 6, fatsG: 12, mealSlots: ['Breakfast', 'Lunch'], tags: ['indian', 'vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 140 },
  { name: 'Palak Paneer', category: 'dairy', caloriesPer100g: 170, proteinG: 10, carbsG: 7, fatsG: 11, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 180 },
  { name: 'Chicken Curry', category: 'protein', caloriesPer100g: 185, proteinG: 19, carbsG: 4, fatsG: 10, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'high-protein', 'gluten-free', 'dairy-free'], servingSizeG: 180 },
  { name: 'Tandoori Chicken', category: 'protein', caloriesPer100g: 165, proteinG: 25, carbsG: 3, fatsG: 5.5, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'high-protein', 'gluten-free'], servingSizeG: 160 },
  { name: 'Fish Curry', category: 'protein', caloriesPer100g: 170, proteinG: 18, carbsG: 4, fatsG: 9, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'high-protein', 'gluten-free', 'dairy-free'], servingSizeG: 180 },
  { name: 'Aloo Gobi', category: 'vegetables', caloriesPer100g: 110, proteinG: 3, carbsG: 14, fatsG: 4.8, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 180 },
  { name: 'Bhindi Masala', category: 'vegetables', caloriesPer100g: 95, proteinG: 2.6, carbsG: 10, fatsG: 4.8, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 160 },
  { name: 'Cucumber Raita', category: 'dairy', caloriesPer100g: 85, proteinG: 4.2, carbsG: 6, fatsG: 4.2, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'gluten-free'], servingSizeG: 120 },
  { name: 'Masala Omelette', category: 'protein', caloriesPer100g: 170, proteinG: 12, carbsG: 2.5, fatsG: 12, mealSlots: ['Breakfast', 'Snack'], tags: ['indian', 'vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 120 },
  { name: 'Roasted Chana', category: 'protein', caloriesPer100g: 370, proteinG: 20, carbsG: 58, fatsG: 6, mealSlots: ['Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 30 },
  { name: 'Fruit Chaat', category: 'fruits', caloriesPer100g: 80, proteinG: 1.2, carbsG: 18, fatsG: 0.5, mealSlots: ['Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 150 },
  { name: 'Buttermilk', category: 'dairy', caloriesPer100g: 40, proteinG: 3.2, carbsG: 4.8, fatsG: 1.2, mealSlots: ['Snack'], tags: ['indian', 'vegetarian', 'gluten-free'], servingSizeG: 200 },
  { name: 'Besan Chilla', category: 'protein', caloriesPer100g: 165, proteinG: 8.5, carbsG: 19, fatsG: 5.5, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 130 },
  { name: 'Rava Idli', category: 'grains', caloriesPer100g: 180, proteinG: 4.8, carbsG: 30, fatsG: 4.2, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian'], servingSizeG: 110 },
  { name: 'Pesarattu', category: 'protein', caloriesPer100g: 155, proteinG: 9.2, carbsG: 20, fatsG: 4.2, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 130 },
  { name: 'Paneer Paratha', category: 'grains', caloriesPer100g: 280, proteinG: 10, carbsG: 34, fatsG: 11, mealSlots: ['Breakfast'], tags: ['indian', 'vegetarian', 'high-protein'], servingSizeG: 120 },
  { name: 'Curd Rice', category: 'dairy', caloriesPer100g: 145, proteinG: 4, carbsG: 22, fatsG: 4.5, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'gluten-free'], servingSizeG: 180 },
  { name: 'Lemon Rice', category: 'grains', caloriesPer100g: 175, proteinG: 3.4, carbsG: 30, fatsG: 4.6, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 170 },
  { name: 'Vegetable Pulao', category: 'grains', caloriesPer100g: 170, proteinG: 4.2, carbsG: 27, fatsG: 5.2, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 180 },
  { name: 'Quinoa Pulao', category: 'grains', caloriesPer100g: 150, proteinG: 5.8, carbsG: 22, fatsG: 3.8, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free', 'high-protein'], servingSizeG: 170 },
  { name: 'Kadhi', category: 'dairy', caloriesPer100g: 115, proteinG: 4.5, carbsG: 10, fatsG: 6.2, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'gluten-free'], servingSizeG: 180 },
  { name: 'Mix Veg Sabzi', category: 'vegetables', caloriesPer100g: 95, proteinG: 2.9, carbsG: 11, fatsG: 4.3, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 170 },
  { name: 'Baingan Bharta', category: 'vegetables', caloriesPer100g: 105, proteinG: 2.4, carbsG: 11, fatsG: 5.6, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 170 },
  { name: 'Methi Thepla', category: 'grains', caloriesPer100g: 260, proteinG: 8.2, carbsG: 41, fatsG: 7.2, mealSlots: ['Lunch', 'Dinner', 'Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free'], servingSizeG: 75 },
  { name: 'Sprouts Salad', category: 'protein', caloriesPer100g: 95, proteinG: 7.8, carbsG: 14, fatsG: 1.5, mealSlots: ['Snack', 'Breakfast'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free', 'high-protein'], servingSizeG: 150 },
  { name: 'Peanut Chaat', category: 'healthy_fats', caloriesPer100g: 260, proteinG: 11, carbsG: 16, fatsG: 17, mealSlots: ['Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 80 },
  { name: 'Makhana Roasted', category: 'healthy_fats', caloriesPer100g: 350, proteinG: 9.7, carbsG: 65, fatsG: 1.2, mealSlots: ['Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 30 },
  { name: 'Whey Shake', category: 'protein', caloriesPer100g: 390, proteinG: 75, carbsG: 8, fatsG: 6, mealSlots: ['Breakfast', 'Snack'], tags: ['high-protein', 'vegetarian', 'gluten-free'], servingSizeG: 35 },
  { name: 'Skim Milk', category: 'dairy', caloriesPer100g: 35, proteinG: 3.4, carbsG: 5, fatsG: 0.2, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'gluten-free'], servingSizeG: 240 },
  { name: 'Paneer Tikka', category: 'protein', caloriesPer100g: 210, proteinG: 16, carbsG: 5, fatsG: 14, mealSlots: ['Lunch', 'Dinner', 'Snack'], tags: ['indian', 'vegetarian', 'high-protein', 'gluten-free'], servingSizeG: 150 },
  { name: 'Chicken Tikka', category: 'protein', caloriesPer100g: 175, proteinG: 28, carbsG: 3, fatsG: 5.3, mealSlots: ['Lunch', 'Dinner', 'Snack'], tags: ['indian', 'high-protein', 'gluten-free', 'dairy-free'], servingSizeG: 150 },
  { name: 'Egg Bhurji', category: 'protein', caloriesPer100g: 165, proteinG: 11.5, carbsG: 3.5, fatsG: 11, mealSlots: ['Breakfast', 'Lunch'], tags: ['indian', 'high-protein', 'gluten-free', 'dairy-free'], servingSizeG: 130 },
  { name: 'Moong Sprouts Curry', category: 'protein', caloriesPer100g: 120, proteinG: 8.3, carbsG: 14, fatsG: 3.2, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free', 'high-protein'], servingSizeG: 170 },
  { name: 'Soy Chunks Curry', category: 'protein', caloriesPer100g: 155, proteinG: 15.2, carbsG: 9, fatsG: 5.1, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'high-protein'], servingSizeG: 160 },
  { name: 'Millet Khichdi', category: 'grains', caloriesPer100g: 140, proteinG: 4.6, carbsG: 24, fatsG: 2.8, mealSlots: ['Lunch', 'Dinner'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 190 },
  { name: 'Vegetable Soup', category: 'vegetables', caloriesPer100g: 45, proteinG: 1.8, carbsG: 7.4, fatsG: 1.1, mealSlots: ['Dinner', 'Snack'], tags: ['vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 220 },
  { name: 'Grilled Fish', category: 'protein', caloriesPer100g: 150, proteinG: 24, carbsG: 0, fatsG: 5, mealSlots: ['Lunch', 'Dinner'], tags: ['high-protein', 'gluten-free', 'dairy-free'], servingSizeG: 160 },
  { name: 'Moong Dal Soup', category: 'protein', caloriesPer100g: 80, proteinG: 5.5, carbsG: 11, fatsG: 1.2, mealSlots: ['Dinner', 'Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free', 'high-protein'], servingSizeG: 220 },
  { name: 'Hummus', category: 'healthy_fats', caloriesPer100g: 166, proteinG: 7.9, carbsG: 14.3, fatsG: 9.6, mealSlots: ['Snack', 'Breakfast'], tags: ['vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 50 },
  { name: 'Boiled Corn Chaat', category: 'carbs', caloriesPer100g: 96, proteinG: 3.4, carbsG: 21, fatsG: 1.5, mealSlots: ['Snack'], tags: ['indian', 'vegetarian', 'vegan', 'dairy-free', 'gluten-free'], servingSizeG: 140 },
  { name: 'Peanut Butter', category: 'healthy_fats', caloriesPer100g: 588, proteinG: 25, carbsG: 20, fatsG: 50, mealSlots: ['Breakfast', 'Snack'], tags: ['vegetarian', 'vegan', 'dairy-free', 'gluten-free', 'high-protein'], servingSizeG: 20 },
];

async function seed() {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/nutripal_db';
    await connectDB(uri);

    await Food.deleteMany({});
    await Food.insertMany(FOODS);

    console.log(`Seeded ${FOODS.length} foods`);
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

seed();
