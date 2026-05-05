# NutriPal Integration - Complete Documentation

**Last Updated**: May 2026  
**Project Status**: Integrated and Unified  
**Current Version**: 1.0.0

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Directory Structure](#directory-structure)
5. [Backend Components](#backend-components)
6. [Frontend Components](#frontend-components)
7. [API Documentation](#api-documentation)
8. [Setup & Installation](#setup--installation)
9. [Running the Project](#running-the-project)
10. [System Features](#system-features)
11. [Data Flow & Workflows](#data-flow--workflows)
12. [Database Schema](#database-schema)
13. [Development Guide](#development-guide)
14. [Troubleshooting](#troubleshooting)
15. [Performance Considerations](#performance-considerations)

---

## Project Overview

**NutriPal** is a comprehensive AI-powered fitness and nutrition management platform that integrates multiple services into a unified ecosystem:

- **Nutrition Tracking**: Capture food via camera, automatically extract nutritional data using AI vision
- **Smart Meal Planning**: Generate personalized 7-day meal plans based on user goals and dietary preferences
- **Workout Management**: Create, track, and manage exercise routines with AI-powered recommendations
- **Real-time Pose Correction**: Computer vision-based form feedback during exercises
- **Analytics & Progress**: Visualize fitness and nutrition metrics over time

### Key Objectives

✅ Unified authentication system across all services  
✅ Seamless integration of AI services (vision, planning, pose detection)  
✅ Real-time communication for live feedback  
✅ Cross-platform support (Android, iOS, Web, Windows)  
✅ Microservices architecture for scalability and reliability  

---

## Architecture

NutriPal follows a **Client-Server Architecture** with **Microservices** for AI workloads:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile/Web App                   │
│                    (Dart - Provider Pattern)                     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  │ REST API + WebSocket
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              Node.js Express Core API (:4000)                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Auth │ Nutrition │ Workouts │ Profile │ Health Checks │   │
│  └────────┬──────────────────────────────────────────────┬─┘   │
│           │                                              │      │
│  ┌────────▼────────────────────────────────────────┬─────▼──┐  │
│  │          MongoDB Atlas / Local Instance        │ Logger │  │
│  └──────────────────────────────────────────────────────────┘  │
└────┬──────────────────────────────────────────────────────────┬─┘
     │ HTTP                                           HTTP │
     ▼                                                      ▼
┌──────────────────────┐                      ┌──────────────────────┐
│  Python AI Planner   │◄──────────────────►  │ Python Pose Corrector│
│  (:8000, FastAPI)    │    Service Calls     │ (:8001, FastAPI)     │
│                      │                      │                      │
│ • Random Forest      │                      │ • MediaPipe          │
│ • Predictions        │                      │ • Joint Tracking     │
│ • Personalization    │                      │ • Angle Calculation  │
└──────────────────────┘                      └──────────────────────┘
         ▲                                              ▲
         │                                              │
    venv-ai/                                      venv-pose/
```

### Core Principles

1. **Separation of Concerns**: Each microservice handles one primary responsibility
2. **Unified Authentication**: All services validate JWT tokens from Node.js
3. **Scalability**: Python services can be deployed independently
4. **Fault Tolerance**: Fallback systems for external APIs (Gemini → OpenRouter)
5. **Real-time Communication**: WebSocket support for live pose feedback

---

## Technology Stack

### Frontend (Mobile/Web)
| Technology | Purpose | Version |
|-----------|---------|---------|
| **Flutter (Dart)** | Cross-platform UI framework | 3.9.2+ |
| **Provider** | State management and dependency injection | 6.1.1 |
| **Dio** | HTTP client for API communication | 5.8.0 |
| **web_socket_channel** | Real-time WebSocket communication | 3.0.3 |
| **fl_chart** | Data visualization (charts & graphs) | 0.68.0 |
| **image_picker** | Camera/gallery integration | 1.1.2 |
| **camera** | Direct camera control | 0.12.0 |
| **google_sign_in** | Social authentication | 6.2.2 |
| **permission_handler** | Runtime permissions management | 12.0.1 |

### Backend (Core API)
| Technology | Purpose | Version |
|-----------|---------|---------|
| **Node.js** | JavaScript runtime | 18+ LTS |
| **Express.js** | Web framework | 4.19.2 |
| **MongoDB** | Document database (Atlas or local) | 6.0+ |
| **Mongoose** | ODM for MongoDB | 8.8.3 |
| **jsonwebtoken (JWT)** | Token-based authentication | 9.0.2 |
| **bcryptjs** | Password hashing | 2.4.3 |
| **Axios** | HTTP client (inter-service communication) | 1.16.0 |
| **Nodemailer** | Email service for verification | 6.9.7 |
| **CORS** | Cross-origin request handling | 2.8.5 |

### AI & Machine Learning (Python)
| Technology | Purpose | Environment |
|-----------|---------|---------|
| **FastAPI** | High-performance async API framework | Both services |
| **Pydantic** | Data validation & serialization | Both services |
| **Scikit-Learn** | Machine learning library | venv-ai/ |
| **MediaPipe** | Computer vision solutions | venv-pose/ |
| **NumPy/Pandas** | Data processing | Both services |
| **OpenCV** | Image processing | venv-pose/ |

### External AI Services
| Service | Purpose | Fallback |
|---------|---------|----------|
| **Google Gemini 2.5 Flash** | Food image analysis | Gemini Flash-Lite |
| **Google Gemini 2.5 Flash-Lite** | Lightweight food analysis | OpenRouter Gemma 3 |
| **OpenRouter Gemma 3 Vision** | Fallback vision model | None |

---

## Directory Structure

```
integration/
│
├── backend/                              # Node.js core API
│   ├── src/
│   │   ├── config/                       # Configuration files database
│   │   ├── controllers/                  # Request handlers
│   │   │   ├── exerciseController.js     # Exercise CRUD operations
│   │   │   ├── workoutController.js      # Workout logging & tracking
│   │   │   └── workoutPlanController.js  # AI-generated plan management
│   │   │
│   │   ├── middleware/                   # Express middleware
│   │   │   └── requireUnifiedAuth.js     # JWT token validation
│   │   │
│   │   ├── models/                       # Mongoose schemas
│   │   │   ├── User.js                   # User identity & auth
│   │   │   ├── UserProfile.js            # Physical metrics & goals
│   │   │   ├── Food.js                   # Food database (nutrition data)
│   │   │   ├── FoodLog.js                # User food consumption records
│   │   │   ├── Meal.js                   # Single meal data
│   │   │   ├── MealPlan.js               # 7-day meal plan templates
│   │   │   └── Workout.js                # Exercise sessions
│   │   │
│   │   ├── routes/                       # Express route handlers
│   │   │   ├── auth.routes.js            # /api/v1/auth/*
│   │   │   ├── foods.routes.js           # /api/v1/foods/*
│   │   │   ├── foodLog.routes.js         # /api/v1/food-log/*
│   │   │   ├── meals.routes.js           # /api/v1/meals/*
│   │   │   ├── plans.routes.js           # /api/v1/plans/*
│   │   │   ├── profile.routes.js         # /api/v1/profile/*
│   │   │   ├── workout.routes.js         # /api/v1/workouts/*
│   │   │   ├── workoutPlans.routes.js    # /api/v1/workout-plans/*
│   │   │   ├── exercises.routes.js       # /api/v1/exercises/*
│   │   │   └── pose.routes.js            # /api/v1/pose/* & WebSocket
│   │   │
│   │   ├── services/                     # Business logic & external APIs
│   │   │   ├── emailService.js           # Email sending & verification
│   │   │   ├── visionAnalysisService.js  # Cascading AI fallback chain
│   │   │   ├── mealPlannerService.js     # Meal plan generation algorithm
│   │   │   └── poseService.js            # WebSocket communication
│   │   │
│   │   ├── utils/                        # Utility functions
│   │   │   ├── nutritionCalculator.js    # TDEE & macro calculations
│   │   │   └── constants.js              # App-wide constants
│   │   │
│   │   ├── scripts/                      # Maintenance & setup scripts
│   │   │   ├── seedFoods.js              # Populate food database
│   │   │   ├── migrateData.js            # Data migration & merging
│   │   │   └── smokeTest.js              # Quick health verification
│   │   │
│   │   └── server.js                     # Express app & MongoDB connection
│   │
│   ├── ai-planner/                       # Python microservice (:8000)
│   │   ├── api_server.py                 # FastAPI entry point
│   │   ├── requirements.txt               # Python dependencies
│   │   └── models/                       # Trained ML models
│   │
│   ├── pose-corrector/                   # Python microservice (:8001)
│   │   ├── pose_corrector_api.py         # FastAPI WebSocket server
│   │   ├── requirements.txt               # Python dependencies
│   │   └── models/                       # MediaPipe & pose data
│   │
│   ├── venv-ai/                          # Python virtual environment (AI Planner)
│   ├── venv-pose/                        # Python virtual environment (Pose Corrector)
│   ├── package.json                      # Node.js dependencies & scripts
│   ├── .env.example                      # Environment template
│   ├── .env                              # Local environment variables (git ignored)
│   └── README.md                         # Backend-specific setup guide
│
├── frontend/                             # Flutter mobile & web app
│   ├── lib/
│   │   ├── main.dart                     # App entry point
│   │   │
│   │   ├── config/                       # Application configuration
│   │   │   └── app_config.dart           # API URLs, constants
│   │   │
│   │   ├── controllers/                  # Business logic & API calls
│   │   │   ├── auth_controller.dart      # Authentication flow
│   │   │   ├── food_controller.dart      # Food logging
│   │   │   ├── meal_controller.dart      # Meal plan management
│   │   │   ├── workout_controller.dart   # Workout tracking
│   │   │   └── pose_controller.dart      # Pose analysis WebSocket
│   │   │
│   │   ├── models/                       # Data models & serialization
│   │   │   ├── User.dart                 # User data structure
│   │   │   ├── Food.dart                 # Food item structure
│   │   │   ├── Meal.dart                 # Meal data structure
│   │   │   ├── MealPlan.dart             # Complete meal plan
│   │   │   ├── Workout.dart              # Workout session data
│   │   │   └── Exercise.dart             # Individual exercise
│   │   │
│   │   ├── pages/                        # Full-screen UI views
│   │   │   ├── auth/                     # Authentication pages
│   │   │   │   ├── login_page.dart       # User login screen
│   │   │   │   ├── register_page.dart    # User registration
│   │   │   │   └── verify_email_page.dart # Email verification
│   │   │   │
│   │   │   ├── onboarding/               # Initial user setup
│   │   │   │   ├── get_started_page.dart # Welcome screen
│   │   │   │   ├── profile_setup_page.dart # Physical metrics collection
│   │   │   │   └── goal_selection_page.dart # User goals & preferences
│   │   │   │
│   │   │   ├── home_page.dart            # Main navigation scaffold
│   │   │   ├── dashboard_page.dart       # Home feed with summaries
│   │   │   ├── analytics_page.dart       # Historical charts & trends
│   │   │   │
│   │   │   ├── nutrition/                # Food & meal planning
│   │   │   │   ├── food_scanner_page.dart # Camera-based food capture
│   │   │   │   ├── food_log_page.dart    # Food history & logs
│   │   │   │   ├── meal_plan_page.dart   # Generated meal plans
│   │   │   │   └── meal_detail_page.dart # Individual meal view
│   │   │   │
│   │   │   └── workout/                  # Exercise tracking
│   │   │       ├── workout_page.dart     # Active workout screen
│   │   │       ├── pose_feedback_page.dart # Real-time pose correction
│   │   │       └── workout_history_page.dart # Past workouts
│   │   │
│   │   ├── services/                     # HTTP & business logic
│   │   │   ├── api_client.dart           # Dio HTTP wrapper
│   │   │   ├── auth_service.dart         # Auth endpoints
│   │   │   ├── food_service.dart         # Food API calls
│   │   │   ├── meal_service.dart         # Meal plan API calls
│   │   │   ├── workout_service.dart      # Workout API calls
│   │   │   └── pose_service.dart         # WebSocket to pose server
│   │   │
│   │   ├── providers/                    # State management (Provider pattern)
│   │   │   ├── auth_provider.dart        # Auth state
│   │   │   ├── food_provider.dart        # Food & FoodLog state
│   │   │   ├── meal_provider.dart        # Meal plan state
│   │   │   ├── workout_provider.dart     # Workout state
│   │   │   └── ui_provider.dart          # Navigation & UI state
│   │   │
│   │   ├── widgets/                      # Reusable UI components
│   │   │   ├── common_widgets.dart       # Generic buttons, cards
│   │   │   ├── nutrition_widgets.dart    # Nutrition-specific widgets
│   │   │   ├── workout_widgets.dart      # Workout-specific widgets
│   │   │   ├── charts/                   # Chart components
│   │   │   └── dialogs/                  # Modal dialogs
│   │   │
│   │   ├── theme/                        # UI styling & theming
│   │   │   ├── app_theme.dart            # Color schemes & typography
│   │   │   └── constants.dart            # UI constants
│   │   │
│   │   └── utils/                        # Helper functions
│   │       ├── formatters.dart           # Date/number formatting
│   │       └── validators.dart           # Input validation
│   │
│   ├── test/                             # Unit & integration tests
│   ├── android/                          # Android-specific code
│   ├── ios/                              # iOS-specific code
│   ├── web/                              # Web-specific code
│   ├── windows/                          # Windows-specific code
│   ├── pubspec.yaml                      # Flutter dependencies
│   ├── analysis_options.yaml             # Dart linting rules
│   └── README.md                         # Frontend-specific guide
│
├── COMPREHENSIVE_GUIDE.md                # Architecture & technical guide
├── DOCUMENTATION.md                      # Feature overview
├── INTEGRATION_STATUS.md                 # Integration progress tracking
├── FULL_DOCUMENTATION.md                 # This file - Complete documentation
├── START_ALL_SERVICES.ps1               # PowerShell script to start all services
└── README.md                             # Quick start guide

```

---

## Backend Components

### Authentication System (Unified)

**Files**: `auth.routes.js`, `requireUnifiedAuth.js`

All services use JWT tokens issued by the Node.js backend:

```javascript
// Token payload structure
{
  sub: userId,              // Alternative: id or userId
  email: user@example.com,
  iat: timestamp,
  exp: timestamp
}
```

**Supported endpoints**:
- `POST /api/v1/auth/register` - Create new user
- `POST /api/v1/auth/login` - Authenticate and get token
- `GET /api/v1/auth/verify-email?token=...` - Email verification
- `GET /api/v1/auth/me` - Get current user profile
- `POST /api/v1/auth/refresh` - Refresh JWT token (if implemented)

### Nutrition System

**Core Files**:
- **Models**: `Food.js` (nutrition database), `FoodLog.js` (user logs), `Meal.js`, `MealPlan.js`
- **Routes**: `foods.routes.js`, `foodLog.routes.js`, `meals.routes.js`, `plans.routes.js`
- **Services**: `visionAnalysisService.js` (AI image analysis), `mealPlannerService.js` (plan generation)

#### Key Features

1. **Food Scanning (Vision Analysis)**
   - User uploads food photo
   - System calls Gemini 2.5 Flash → Gemini Flash-Lite → OpenRouter fallback
   - Returns: Calories, Macros (protein/carbs/fats), Confidence score
   - User reviews and saves to FoodLog

2. **Meal Plan Generation**
   - Based on user: BMR, activity level, goal (fat loss/gain/maintenance)
   - Algorithm filters foods matching macro targets
   - Applies soft constraints for variety (recently used foods penalized but not excluded)
   - Returns 7-day plan with breakfast/lunch/dinner/snacks

3. **Food Database**
   - Pre-seeded with 20+ foods and their nutritional data per 100g
   - Searchable by category and dietary tags

### Workout System

**Core Files**:
- **Models**: `Workout.js` (exercise sessions)
- **Controllers**: `workoutController.js`, `workoutPlanController.js`, `exerciseController.js`
- **Routes**: `workout.routes.js`, `workoutPlans.routes.js`, `exercises.routes.js`

#### Key Features

1. **Workout Logging**
   - Log completed exercises with sets, reps, weight
   - Stores exercise form feedback and timestamps

2. **Workout Plans**
   - AI-generated personalized plans from Python microservice
   - Based on user goals and experience level

3. **Exercise Database**
   - Pre-defined exercises with body part targets
   - Linked to workout sessions

### Pose Correction

**Files**: `pose.routes.js`, `poseService.js`

- **Real-time WebSocket** communication with Python pose service
- Sends video frames and receives live feedback
- Tracks joint angles and exercise form quality

### Profile Management

**Files**: `profile.routes.js`, `UserProfile.js`

Stores user physical data:
- Height, Weight, Age, Gender
- Body Fat %, Goal (fat loss/muscle gain/maintenance)
- Dietary preferences (vegetarian/vegan/high-protein, etc.)
- Activity level

---

## Frontend Components

### Navigation Architecture

```
Home (IndexedStack)
├── Dashboard (home)
│   ├── Nutrition Summary
│   └── Workout Summary
├── Nutrition Tab
│   ├── Food Scanner
│   ├── Food Log History
│   └── Meal Plans
├── Workouts Tab
│   ├── Active Workout
│   ├── Pose Correction
│   └── Workout History
└── Analytics Tab
    ├── Nutrition Charts
    └── Workout Charts
```

### State Management (Provider Pattern)

**Providers** manage app state:
- `AuthProvider` - User authentication & session
- `FoodProvider` - Food data & food logs
- `MealProvider` - Meal plans
- `WorkoutProvider` - Workouts & exercises
- `UIProvider` - Navigation & UI state

Each provider handles:
- Data fetching from API
- Local state caching
- Error handling
- Notify listeners on state changes

### Key Pages

1. **Dashboard** (`dashboard_page.dart`)
   - Nutrition progress rings (calories, macros)
   - Daily workout summary
   - Quick action buttons

2. **Analytics** (`analytics_page.dart`)
   - Tabbed interface with fl_chart
   - Historical nutrition trends
   - Exercise volume charts

3. **Food Scanner** (`food_scanner_page.dart`)
   - Camera integration
   - AI-powered nutrition extraction
   - User verification & editing

4. **Meal Plans** (`meal_plan_page.dart`)
   - Display generated 7-day plans
   - Swap meals between days
   - Save favorite combinations

5. **Workout** (`workout_page.dart`)
   - Display current exercise
   - Log sets/reps/weight
   - Real-time pose feedback overlay

---

## API Documentation

### Base URL
```
Production: https://api.nutripal.app/api/v1
Development: http://localhost:4000/api/v1
```

### Authentication

All protected endpoints require:
```
Header: Authorization: Bearer <JWT_TOKEN>
```

### Core Endpoints

#### Authentication (`/auth`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| POST | `/register` | ❌ | `{email, password, name}` | `{token, user}` |
| POST | `/login` | ❌ | `{email, password}` | `{token, user}` |
| GET | `/me` | ✅ | - | `{user profile}` |
| GET | `/verify-email?token=...` | ❌ | Query token | `{success, message}` |

#### Profile (`/profile`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| GET | `/` | ✅ | - | `{profile object}` |
| PUT | `/` | ✅ | `{height, weight, goal, ...}` | `{updated profile}` |

#### Foods (`/foods`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| GET | `/` | ✅ | Query: `?category=...&tags=...` | `{foods: [...]}` |
| POST | `/` | ✅ | `{name, calories, ...}` | `{new food}` |
| GET | `/:id` | ✅ | - | `{food object}` |

#### Food Logs (`/food-log`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| POST | `/analyze` | ✅ | `{image: base64}` | `{calories, macros, confidence}` |
| POST | `/` | ✅ | `{foodId, servingSize, mealType}` | `{new log entry}` |
| GET | `/` | ✅ | Query: `?date=...` | `{logs: [...]}` |
| DELETE | `/:logId` | ✅ | - | `{success}` |

#### Meals (`/meals`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| GET | `/` | ✅ | - | `{meals: [...]}` |
| POST | `/` | ✅ | `{mealType, foods: [...]}` | `{new meal}` |

#### Meal Plans (`/plans`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| POST | `/generate` | ✅ | `{days: 7, goal, preferences}` | `{generated plan}` |
| GET | `/` | ✅ | - | `{plans: [...]}` |
| GET | `/:planId` | ✅ | - | `{plan details}` |
| PUT | `/:planId` | ✅ | `{updates}` | `{updated plan}` |
| DELETE | `/:planId` | ✅ | - | `{success}` |

#### Workouts (`/workouts`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| POST | `/` | ✅ | `{exercises: [...]}` | `{new workout}` |
| GET | `/` | ✅ | Query: `?date=...&limit=10` | `{workouts: [...]}` |
| GET | `/:workoutId` | ✅ | - | `{workout details}` |
| PUT | `/:workoutId` | ✅ | `{updates}` | `{updated workout}` |
| DELETE | `/:workoutId` | ✅ | - | `{success}` |

#### Workout Plans (`/workout-plans`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| POST | `/generate` | ✅ | `{goal, experience, preferences}` | `{generated plan}` |
| GET | `/` | ✅ | - | `{plans: [...]}` |

#### Exercises (`/exercises`)

| Method | Endpoint | Auth | Request | Response |
|--------|----------|------|---------|----------|
| GET | `/` | ✅ | Query: `?bodyPart=...` | `{exercises: [...]}` |

#### Pose Analysis (`/pose`)

| Method | Endpoint | Type | Purpose |
|--------|----------|------|---------|
| WS | `/ws` | WebSocket | Upgrade connection for real-time pose feedback |

**WebSocket Protocol**:
```json
// Client sends frame:
{"type": "frame", "image": "base64..."}

// Server responds:
{"type": "feedback", "angle": 90, "form": "Good", "message": "Keep steady"}
```

---

## Setup & Installation

### Prerequisites

- **Node.js** 18+ LTS
- **MongoDB** (Atlas cloud or local instance)
- **Python** 3.9+
- **Flutter** 3.9.2+
- **Git**

### Backend Setup

1. **Navigate to backend**:
   ```bash
   cd integration/backend
   ```

2. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

3. **Create `.env` file**:
   ```
   # Database
   MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/nutripal
   
   # Server
   NODE_ENV=development
   PORT=4000
   CORS_ORIGIN=http://localhost:3000
   
   # JWT
   JWT_SECRET=your_super_secret_key_change_in_production
   JWT_EXPIRY=7d
   
   # AI Services
   GOOGLE_API_KEY=your_gemini_api_key
   OPENROUTER_API_KEY=your_openrouter_key
   
   # Email
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASSWORD=your_app_password
   
   # AI Microservices
   AI_PLANNER_URL=http://localhost:8000
   POSE_CORRECTOR_URL=http://localhost:8001
   ```

4. **Create Python virtual environments**:
   ```bash
   # AI Planner
   python -m venv venv-ai
   
   # Pose Corrector
   python -m venv venv-pose
   ```

5. **Install Python dependencies**:
   ```bash
   # Activate and install for AI Planner
   .\venv-ai\Scripts\activate  # Windows
   # or: source venv-ai/bin/activate  # Unix
   cd ai-planner
   pip install -r requirements.txt
   cd ..
   
   # Activate and install for Pose Corrector
   .\venv-pose\Scripts\activate  # Windows
   # or: source venv-pose/bin/activate  # Unix
   cd pose-corrector
   pip install -r requirements.txt
   cd ..
   ```

6. **Seed the food database**:
   ```bash
   npm run seed:foods
   ```

### Frontend Setup

1. **Navigate to frontend**:
   ```bash
   cd integration/frontend
   ```

2. **Get Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update API configuration** (`lib/config/app_config.dart`):
   ```dart
   static const String API_BASE_URL = 'http://localhost:4000/api/v1';
   static const String WEBSOCKET_URL = 'ws://localhost:8001';
   ```

---

## Running the Project

### Quick Start (All Services)

Use the provided PowerShell script:

```bash
cd integration
.\START_ALL_SERVICES.ps1
```

This starts:
- ✅ Node.js backend (:4000)
- ✅ Python AI Planner (:8000)
- ✅ Python Pose Corrector (:8001)
- ✅ Flutter frontend

### Manual Service Start

**Terminal 1 - Node.js Backend**:
```bash
cd integration/backend
npm run dev
# Runs on http://localhost:4000
```

**Terminal 2 - AI Planner**:
```bash
cd integration/backend/ai-planner
.\..\..\venv-ai\Scripts\activate  # Windows
python api_server.py
# Runs on http://localhost:8000
```

**Terminal 3 - Pose Corrector**:
```bash
cd integration/backend/pose-corrector
.\..\..\venv-pose\Scripts\activate  # Windows
python pose_corrector_api.py
# Runs on http://localhost:8001
```

**Terminal 4 - Flutter App**:
```bash
cd integration/frontend

# Run on Android emulator
flutter run -d emulator-5554

# Run on iOS simulator
flutter run -d iPhone

# Run on Web
flutter run -d chrome
```

### Health Check

Verify all services are running:

```bash
# Backend health
curl http://localhost:4000/health

# Response:
# {
#   "status": "OK",
#   "timestamp": "2024-05-01T10:00:00Z",
#   "services": {
#     "database": "connected",
#     "aiPlanner": "available",
#     "poseCorrector": "available"
#   }
# }
```

---

## System Features

### 1. AI-Powered Food Scanning

**Flow**:
1. User opens Food Scanner page
2. Captures photo via camera
3. Image sent to Node backend
4. Backend tries Gemini 2.5 Flash:
   - Success → Return nutrition data
   - Rate limited → Try Gemini Flash-Lite
   - Still failed → Try OpenRouter Gemma 3
5. Frontend displays: Calories, Macros, Confidence
6. User confirms or manually adjusts
7. Data saved to FoodLog

**Benefits**:
- ✅ Automatic calorie tracking
- ✅ Fallback system for reliability
- ✅ User verification before saving

### 2. Smart Meal Planning

**Algorithm**:
1. Get user profile (goals, constraints, preferences)
2. Calculate TDEE using Mifflin-St Jeor equation:
   ```
   Men: 10W + 6.25H - 5A + 5
   Women: 10W + 6.25H - 5A - 161
   Then multiply by activity level (1.2-1.9)
   ```
3. Calculate macro targets based on goal:
   - Fat Loss: 35% protein, 40% carbs, 25% fats
   - Muscle Gain: 30% protein, 50% carbs, 20% fats
   - Maintenance: 30% protein, 45% carbs, 25% fats
4. For each meal slot (breakfast/lunch/dinner/snacks):
   - Filter foods matching constraints (vegetarian, etc.)
   - Score foods by macro fit
   - Penalize recently-used foods (soft constraint)
   - Pick top food for meal
5. Return 7-day plan

**Example Output**:
```json
{
  "day": 1,
  "meals": {
    "breakfast": {
      "name": "Oatmeal with Berries",
      "calories": 350,
      "macros": {"protein": 10, "carbs": 60, "fats": 7}
    },
    "lunch": {...},
    "dinner": {...},
    "snack": {...}
  }
}
```

### 3. Real-Time Pose Correction

**Flow**:
1. User starts workout (e.g., Squats)
2. Phone camera feed captured
3. WebSocket connection opened to pose service
4. Frames sent to Python MediaPipe service
5. Service tracks:
   - Joint positions (knees, hips, shoulders)
   - Calculates angles
   - Compares against thresholds for exercise
6. Sends real-time feedback: "Go deeper!", "Form good!", "Adjust knees"
7. UI displays feedback overlay on video

**Exercises Supported**:
- Squats (knee angle, hip depth)
- Push-ups (shoulder alignment, elbow angle)
- Planks (body alignment, core engagement)
- And more...

### 4. Progress Analytics

**Dashboard** shows:
- Daily calorie intake vs. target
- Macro breakdown
- Workout volume (total sets × reps × weight)
- Exercise frequency

**Charts** include:
- Weekly calorie trends
- Monthly workout volume
- Body weight progression

---

## Data Flow & Workflows

### Workflow 1: User Registration & Onboarding

```
User
  ↓
[Register Page] inputs email/password
  ↓
POST /api/v1/auth/register
  ↓
[Node Backend] hashes password, creates User
  ↓
Sends verification email
  ↓
User clicks link → GET /api/v1/auth/verify-email?token=...
  ↓
[Node Backend] marks email verified
  ↓
[Get Started Page] collects height/weight/age/gender
  ↓
POST /api/v1/profile
  ↓
[Goal Selection] user picks fat loss/gain/maintenance + preferences
  ↓
POST /api/v1/profile (update goals)
  ↓
[Dashboard] user ready to start
```

### Workflow 2: Food Scanning & Logging

```
User captures food photo
  ↓
POST /api/v1/food-log/analyze (image as base64)
  ↓
[Node Backend]
  ├→ Try: Gemini 2.5 Flash
  ├→ Try: Gemini 2.5 Flash-Lite
  └→ Try: OpenRouter Gemma 3
  ↓
[Response] {calories: 450, protein: 15, carbs: 60, fats: 12, confidence: 0.92}
  ↓
[Food Scanner Page] displays analysis
  ↓
User confirms or edits
  ↓
POST /api/v1/food-log (save to FoodLog collection)
  ↓
[Dashboard] reflects in daily totals
```

### Workflow 3: AI Meal Plan Generation

```
User clicks "Generate Plan"
  ↓
POST /api/v1/plans/generate {goal: "fat_loss", preferences: ["vegetarian"]}
  ↓
[Node Backend]
  ├→ Fetch user profile
  ├→ Calculate TDEE & macro targets
  ├→ Score foods by fit
  ├→ Generate 7-day plan
  └→ Save to MealPlan collection
  ↓
[Response] {day1: {...}, day2: {...}, ...}
  ↓
[Meal Plan Page] displays plan
  ↓
User can swap meals or save for later
```

### Workflow 4: Workout with Live Pose Feedback

```
User selects exercise (e.g., Squats)
  ↓
[Workout Page] loads exercise details
  ↓
User taps "Start Pose Correction"
  ↓
[Pose Feedback Page]
  ├→ Requests camera permission
  ├→ Opens camera stream
  └→ WebSocket connect to ws://localhost:8001
  ↓
[MediaPipe Processing Loop]
  ├→ Capture frame (30fps)
  ├→ Send to Python service
  ├→ Detect joints & calculate angles
  └→ Send feedback: "Perfect!", "Go deeper!", etc.
  ↓
[UI] displays real-time feedback overlay
  ↓
User completes set
  ↓
POST /api/v1/workouts {exercise: "squats", sets: 3, reps: 10, weight: 185}
  ↓
[Dashboard] updates workout summary
```

---

## Database Schema

### User Collection
```javascript
{
  _id: ObjectId,
  email: String (unique, lowercase),
  password: String (hashed with bcrypt),
  name: String,
  emailVerified: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### UserProfile Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  height: Number (cm),
  weight: Number (kg),
  age: Number,
  gender: String (male/female/other),
  bodyFat: Number (optional, %),
  goal: String (fat_loss/muscle_gain/maintenance),
  activityLevel: Number (1.2-1.9),
  dietaryPreferences: [String] (vegetarian, vegan, etc.),
  createdAt: Date,
  updatedAt: Date
}
```

### Food Collection
```javascript
{
  _id: ObjectId,
  name: String,
  caloriesPer100g: Number,
  proteinPer100g: Number,
  carbsPer100g: Number,
  fatsPer100g: Number,
  category: String (fruit, vegetable, protein, etc.),
  tags: [String] (vegetarian, vegan, high-protein, etc.),
  createdAt: Date
}
```

### FoodLog Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  foodId: ObjectId (ref: Food),
  servingSize: Number (grams),
  mealType: String (breakfast, lunch, dinner, snack),
  date: Date,
  confidence: Number (0-1, from AI analysis),
  aiAnalyzed: Boolean,
  createdAt: Date
}
```

### MealPlan Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  goal: String,
  constraints: [String],
  days: [
    {
      dayNumber: Number,
      meals: {
        breakfast: { foodId, servingSize, calories, macros },
        lunch: {...},
        dinner: {...},
        snack: {...}
      },
      totalCalories: Number,
      totalMacros: { protein, carbs, fats }
    }
  ],
  createdAt: Date
}
```

### Workout Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  date: Date,
  exercises: [
    {
      exerciseId: ObjectId (ref: Exercise),
      sets: Number,
      reps: Number,
      weight: Number,
      duration: Number (seconds),
      notes: String,
      formQuality: Number (0-100, from pose correction)
    }
  ],
  totalDuration: Number (minutes),
  createdAt: Date
}
```

---

## Development Guide

### Adding a New API Endpoint

1. **Create Controller** (`src/controllers/newFeature.js`):
   ```javascript
   exports.getFeature = async (req, res) => {
     try {
       // Logic here
       res.json({ success: true, data: result });
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   };
   ```

2. **Create Route** (`src/routes/feature.routes.js`):
   ```javascript
   const router = require('express').Router();
   const { getFeature } = require('../controllers/newFeature');
   const { requireUnifiedAuth } = require('../middleware/requireUnifiedAuth');

   router.get('/', requireUnifiedAuth, getFeature);

   module.exports = router;
   ```

3. **Mount Route** (`src/server.js`):
   ```javascript
   app.use('/api/v1/features', require('./routes/feature.routes'));
   ```

### Adding Flutter Pages

1. **Create Page File** (`lib/pages/feature_page.dart`):
   ```dart
   class FeaturePage extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('Feature')),
         body: Consumer<FeatureProvider>(
           builder: (context, featureProvider, _) {
             return ListView(...);
           },
         ),
       );
     }
   }
   ```

2. **Create Provider** (`lib/providers/feature_provider.dart`):
   ```dart
   class FeatureProvider with ChangeNotifier {
     Future<void> fetchFeature() async {
       // Call API service
       notifyListeners();
     }
   }
   ```

3. **Add to Navigation** (`lib/pages/home_page.dart`):
   ```dart
   pages: [
     DashboardPage(),
     FeaturePage(),  // New page
     AnalyticsPage(),
   ]
   ```

### Testing

**Backend Smoke Test**:
```bash
npm run test:smoke
```

**Run specific test**:
```bash
node src/scripts/smokeTest.js
```

---

## Troubleshooting

### Common Issues

#### 1. Backend won't start: "Cannot find module"
**Solution**:
```bash
rm -rf node_modules package-lock.json
npm install
```

#### 2. MongoDB connection timeout
**Solution**:
- Check MongoDB connection string in `.env`
- Verify MongoDB is running (local) or accessible (Atlas)
- Check firewall/network settings
- Verify IP whitelist in MongoDB Atlas

#### 3. Python service won't start
**Solution**:
```bash
# Activate correct virtual environment
.\venv-ai\Scripts\activate  # Windows
source venv-ai/bin/activate  # Unix

# Check Python version
python --version  # Should be 3.9+

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

#### 4. Flutter can't reach backend
**Solution**:
- Verify backend is running: `curl http://localhost:4000/health`
- Check API URL in `lib/config/app_config.dart`
- If on real device, use computer's IP instead of localhost
- Verify firewall isn't blocking port 4000

#### 5. JWT token rejected
**Solution**:
- Verify token hasn't expired (default 7 days)
- Check JWT_SECRET matches between services
- Ensure requireUnifiedAuth middleware is applied to protected routes

#### 6. Food image analysis returns empty
**Solution**:
- Verify GOOGLE_API_KEY and OPENROUTER_API_KEY in `.env`
- Check API keys have correct permissions
- Verify image is valid (not corrupted, proper format)
- Check API rate limits haven't been exceeded

#### 7. WebSocket connection refused
**Solution**:
- Verify pose corrector running on port 8001
- Check WebSocket URL in Flutter: `ws://localhost:8001`
- If on real device, use computer's IP: `ws://192.168.x.x:8001`
- Verify firewall allows WebSocket connections

### Debug Mode

**Backend**:
```bash
DEBUG=* npm run dev
```

**Flutter**:
```bash
flutter run --verbose
```

### Logs Location

- **Backend**: Console output (or implement file logging)
- **Flutter**: DevTools (in VS Code or Android Studio)
- **Python**: Standard output

---

## Performance Considerations

### Optimization Tips

1. **Database Indexing**
   ```javascript
   // In models, add indexes for frequently queried fields
   userSchema.index({ email: 1 });
   foodLogSchema.index({ userId: 1, date: 1 });
   ```

2. **API Response Caching**
   - Cache food database in frontend
   - Implement Redis for backend caching
   - Use ETags for conditional requests

3. **Image Optimization**
   - Compress images before sending to AI services
   - Resize to appropriate resolution
   - Consider WebP format

4. **WebSocket Optimization**
   - Adjust frame capture rate (30fps vs. 60fps)
   - Implement message batching
   - Graceful disconnection handling

5. **Frontend Performance**
   - Use `ListView.builder` for large lists
   - Implement pagination for food/workout history
   - Lazy load images

### Scalability

**For Production**:
- Deploy backend to cloud (AWS, GCP, Azure)
- Use managed MongoDB (Atlas)
- Implement CDN for static assets
- Use Redis for caching
- Deploy Python services independently
- Implement load balancing
- Set up monitoring & logging (Sentry, DataDog)

---

## Next Steps & Future Enhancements

1. **Mobile App Deployment**
   - Build and release to Google Play & App Store
   - Implement in-app purchases for premium features

2. **Advanced Analytics**
   - Machine learning for weight prediction
   - Recommendation engine for exercises
   - Nutritionist AI assistant

3. **Social Features**
   - Share meal plans and workouts
   - Community challenges
   - Leaderboards

4. **Integration with Wearables**
   - Apple Watch integration
   - Fitbit/Garmin data sync
   - Real-time heart rate feedback during workouts

5. **Offline Support**
   - Local caching with Hive
   - Sync when connection restored

---

## Support & Resources

**Documentation**:
- [COMPREHENSIVE_GUIDE.md](COMPREHENSIVE_GUIDE.md) - Detailed architecture
- [DOCUMENTATION.md](DOCUMENTATION.md) - Feature overview
- [Backend README](backend/README.md) - Backend setup
- [Frontend README](frontend/README.md) - Frontend setup

**External Resources**:
- [Express.js Docs](https://expressjs.com/)
- [Flutter Docs](https://flutter.dev/docs)
- [MongoDB Docs](https://docs.mongodb.com/)
- [MediaPipe Docs](https://developers.google.com/mediapipe)
- [Google Gemini API](https://ai.google.dev/)

**Contact & Issues**:
- Report bugs in GitHub Issues
- Check INTEGRATION_STATUS.md for current status
- Review phase completion tracking

---

**Last Updated**: May 4, 2026  
**Maintained By**: NutriPal Development Team  
**Version**: 1.0.0 (Fully Integrated)

