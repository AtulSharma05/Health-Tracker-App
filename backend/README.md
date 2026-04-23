# NutriPal — Unified Backend

Merged nutrition + workout + AI planner + pose analysis backend.

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Configure environment (copy and edit)
cp .env.example .env

# 3. Seed the food database (first time only)
npm run seed:foods

# 4. Start the server
npm run dev
```

The backend will start on **http://localhost:4000**.

## NPM Scripts

| Script | Command | Description |
|--------|---------|-------------|
| `npm run dev` | `nodemon src/server.js` | Start with hot-reload |
| `npm start` | `node src/server.js` | Start in production mode |
| `npm run test:smoke` | Smoke test | Tests 19 critical API endpoints |
| `npm run migrate:dry` | Migration dry-run | Preview data migration from legacy DB |
| `npm run migrate:run` | Migration live | Execute data migration from legacy DB |
| `npm run seed:foods` | Seed foods | Populate food database |

## API Endpoints

Base URL: `http://localhost:4000/api/v1`

### Auth & Identity
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register` | — | Email/password registration |
| POST | `/auth/login` | — | Email/password login |
| POST | `/auth/verify-email` | — | Verify email with token |
| GET | `/auth/verify-email?token=` | — | Verify email via link |
| POST | `/auth/resend-verification-email` | — | Resend verification email |
| POST | `/auth/google` | — | Google OAuth login/register |
| POST | `/auth/forgot-password` | — | Request password reset |
| POST | `/auth/reset-password` | — | Reset password with token |
| GET | `/auth/me` | ✅ | Get current user info |
| PUT | `/profile` | ✅ | Update nutrition profile |
| GET | `/profile` | ✅ | Get nutrition profile |

### Nutrition
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/foods/search` | ✅ | Search food database |
| GET | `/foods` | ✅ | List foods |
| POST | `/foods` | ✅ | Add custom food |
| GET | `/meals` | ✅ | List user meals |
| GET | `/meals/stats` | ✅ | Meal statistics |
| POST | `/meals` | ✅ | Log a meal |
| DELETE | `/meals/:id` | ✅ | Delete a meal |
| POST | `/plans/generate` | ✅ | Generate meal plan |
| GET | `/plans` | ✅ | List meal plans |
| GET | `/plans/:id` | ✅ | Get meal plan |
| PUT | `/plans/:id` | ✅ | Update meal plan |
| DELETE | `/plans/:id` | ✅ | Delete meal plan |

### Workout
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/workouts` | ✅ | List user workouts |
| GET | `/workouts/stats` | ✅ | Workout statistics |
| GET | `/workouts/recent` | ✅ | Recent workouts |
| POST | `/workouts` | ✅ | Log a workout |
| GET | `/workouts/:id` | ✅ | Get workout |
| PUT | `/workouts/:id` | ✅ | Update workout |
| DELETE | `/workouts/:id` | ✅ | Delete workout |

### AI Workout Planner
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/workout-plans/generate` | ✅ | AI workout plan |
| POST | `/workout-plans/recommend-exercises` | ✅ | Exercise recommendations |
| POST | `/workout-plans/predict-sets` | ✅ | Set predictions |
| GET | `/workout-plans/status` | ✅ | AI service status |

### Exercise Database
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/exercises/search` | — | Search exercises |
| GET | `/exercises` | — | List exercises |

### Pose Analysis
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/pose/health` | — | Pose service health |
| POST | `/pose/start-session` | ✅ | Start pose session |
| GET | `/pose/session-summary` | ✅ | Get session summary |
| POST | `/pose/reset` | ✅ | Reset session |
| GET | `/pose/search` | — | Search pose exercises |
| GET | `/pose/exercises` | — | List pose exercises |

## External Services

| Service | Default URL | Required |
|---------|------------|----------|
| MongoDB | localhost:27017 | ✅ Yes |
| AI Planner (Python) | localhost:8000 | Optional |
| Pose Corrector (Python) | localhost:8001 | Optional |

## Data Migration

To merge legacy workout_tracker_db data into the canonical nutripal_db:

```bash
# Preview what would happen
npm run migrate:dry

# Execute migration
npm run migrate:run
```

Set `LEGACY_MONGODB_URI` in `.env` if the legacy DB is on a different host.
