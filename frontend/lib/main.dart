import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/meal_service.dart';
import 'services/nutrition_plan_service.dart';
import 'services/profile_service.dart';
import 'services/food_service.dart';
import 'services/food_log_service.dart';
import 'services/workout_service.dart';
import 'services/workout_plan_service.dart';
import 'services/exercise_database_service.dart';
import 'theme/app_theme.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/log_meal_page.dart';
import 'pages/meal_history_page.dart';
import 'pages/create_nutrition_plan_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/verify_email_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/log_workout_page.dart';
import 'pages/workout_history_page.dart';
import 'pages/create_workout_plan_page.dart';
import 'pages/exercise_selection_page.dart';
import 'pages/pose_analysis_page.dart';
import 'pages/ai_food_log_page.dart';
import 'services/pose_analysis_service.dart';
void main() {
  runApp(const NutriPalApp());
}

class NutriPalApp extends StatelessWidget {
  const NutriPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<AuthService>(
          create: (context) => AuthService(context.read<ApiService>()),
        ),
        ChangeNotifierProvider<MealService>(
          create: (context) => MealService(context.read<ApiService>()),
        ),
        ChangeNotifierProvider<ProfileService>(
          create: (context) => ProfileService(context.read<ApiService>()),
        ),
        Provider<NutritionPlanService>(
          create: (context) => NutritionPlanService(context.read<ApiService>()),
        ),
        Provider<FoodService>(
          create: (context) => FoodService(context.read<ApiService>()),
        ),
        Provider<FoodLogService>(
          create: (context) => FoodLogService(context.read<ApiService>()),
        ),
        Provider<WorkoutService>(
          create: (context) => WorkoutService(context.read<ApiService>()),
        ),
        Provider<WorkoutPlanService>(
          create: (context) => WorkoutPlanService(context.read<ApiService>()),
        ),
        Provider<ExerciseDatabaseService>(
          create: (context) => ExerciseDatabaseService(context.read<ApiService>()),
        ),
        Provider<PoseAnalysisService>(
          create: (context) => PoseAnalysisService(),
          dispose: (context, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'NutriPal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const WelcomePage(),
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/home': (_) => const HomePage(),
          '/log-meal': (_) => const LogMealPage(),
          '/ai-food-log': (_) => const AiFoodLogPage(),
          '/meal-history': (_) => const MealHistoryPage(),
          '/create-nutrition-plan': (_) => const CreateNutritionPlanPage(),
          '/log-workout': (_) => const LogWorkoutPage(),
          '/workout-history': (_) => const WorkoutHistoryPage(),
          '/create-workout-plan': (_) => const CreateWorkoutPlanPage(),
          '/onboarding': (_) => const OnboardingPage(),
          '/forgot-password': (_) => const ForgotPasswordPage(),
          '/verify-email': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;

            if (args is Map<String, dynamic>) {
              final email = (args['email'] ?? '').toString();
              final devVerificationToken = (args['devVerificationToken'] ?? '')
                  .toString();

              return VerifyEmailPage(
                email: email,
                initialToken: devVerificationToken.isEmpty
                    ? null
                    : devVerificationToken,
              );
            }

            final email = args is String ? args : '';
            return VerifyEmailPage(email: email);
          },
          '/exercise-selection': (_) => const ExerciseSelectionPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/pose-analysis') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => PoseAnalysisPage(
                exerciseName: args?['exerciseName'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
