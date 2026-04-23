const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const { globalErrorHandler, notFound } = require('./middleware/errorHandler');

dotenv.config();

const app = express();

// ── Global middleware ──
app.use(cors());
app.use(express.json());

// ── Health check ──
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'nutripal-backend', version: '1.0.0' });
});

// ── API v1 routes ──
// Auth & identity
app.use('/api/v1/auth', require('./routes/auth.routes'));
app.use('/api/v1/profile', require('./routes/profile.routes'));

// Nutrition domain
app.use('/api/v1/foods', require('./routes/foods.routes'));
app.use('/api/v1/meals', require('./routes/meals.routes'));
app.use('/api/v1/plans', require('./routes/plans.routes'));

// Workout domain
app.use('/api/v1/workouts', require('./routes/workout.routes'));
app.use('/api/v1/workout-plans', require('./routes/workoutPlans.routes'));
app.use('/api/v1/exercises', require('./routes/exercises.routes'));
app.use('/api/v1/pose', require('./routes/pose.routes'));

// ── Error handling (must be after all routes) ──
app.use(notFound);
app.use(globalErrorHandler);

const PORT = process.env.PORT || 4000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/nutripal_db';

async function start() {
  await connectDB(MONGODB_URI);
  app.listen(PORT, () => {
    console.log(`NutriPal backend running on port ${PORT}`);
    console.log(`  Health:    http://localhost:${PORT}/health`);
    console.log(`  API base:  http://localhost:${PORT}/api/v1`);
    console.log(`  Env:       ${process.env.NODE_ENV || 'development'}`);
  });
}

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
