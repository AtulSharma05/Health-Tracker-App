const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'nutripal-backend' });
});

app.use('/api/v1/auth', require('./routes/auth.routes'));
app.use('/api/v1/foods', require('./routes/foods.routes'));
app.use('/api/v1/meals', require('./routes/meals.routes'));
app.use('/api/v1/plans', require('./routes/plans.routes'));
app.use('/api/v1/profile', require('./routes/profile.routes'));
app.use('/api/v1/workouts', require('./routes/workout.routes'));
app.use('/api/v1/workout-plans', require('./routes/workoutPlans.routes'));
app.use('/api/v1/exercises', require('./routes/exercises.routes'));
app.use('/api/v1/pose', require('./routes/pose.routes'));

app.use((err, req, res, next) => {
  console.error(err);
  if (err && err.statusCode) {
    return res.status(err.statusCode).json({ message: err.message || 'Request failed' });
  }
  return res.status(500).json({ message: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/nutripal_db';

async function start() {
  await connectDB(MONGODB_URI);
  app.listen(PORT, () => {
    console.log(`NutriPal backend running on port ${PORT}`);
  });
}

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
