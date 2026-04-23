# NutriPal Backend

Node + Express + MongoDB backend for NutriPal.

## Setup
1. cd backend
2. npm install
3. copy .env.example to .env
4. npm run dev

## API Base
- http://localhost:4000/api/v1

## Endpoints
- POST /auth/register
- POST /auth/login
- GET /auth/me
- GET /meals
- POST /meals
- DELETE /meals/:id
- POST /plans/generate

## Integrated Workout + AI Endpoints
- GET /workouts
- POST /workouts
- GET /workouts/stats
- GET /workouts/recent
- POST /workout-plans/generate
- POST /workout-plans/recommend-exercises
- POST /workout-plans/predict-sets
- GET /workout-plans/status
- GET /exercises/search?name=
- GET /pose/health
- POST /pose/start-session
- GET /pose/session-summary
- POST /pose/reset
