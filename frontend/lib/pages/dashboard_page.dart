import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meal_service.dart';
import '../services/profile_service.dart';
import '../services/workout_service.dart';
import '../models/workout.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  final void Function(int)? onSwitchTab;

  const DashboardPage({super.key, this.onSwitchTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Workout> _recentWorkouts = [];
  int _todayWorkoutCount = 0;
  double _todayWorkoutCalories = 0;
  double _todayWorkoutMinutes = 0;
  bool _loadingWorkouts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkoutData());
  }

  Future<void> _loadWorkoutData() async {
    try {
      final workoutService = context.read<WorkoutService>();
      final workouts = await workoutService.getWorkouts();
      if (!mounted) return;

      final today = DateTime.now();
      final todayWorkouts = workouts.where((w) =>
          w.date.year == today.year &&
          w.date.month == today.month &&
          w.date.day == today.day);

      setState(() {
        _recentWorkouts = workouts.take(3).toList();
        _todayWorkoutCount = todayWorkouts.length;
        _todayWorkoutCalories =
            todayWorkouts.fold(0.0, (sum, w) => sum + w.caloriesBurned);
        _todayWorkoutMinutes =
            todayWorkouts.fold(0.0, (sum, w) => sum + w.duration);
        _loadingWorkouts = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingWorkouts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealService = context.watch<MealService>();
    final profileService = context.watch<ProfileService>();
    final calculations = profileService.calculations;
    final entries = mealService.entries;

    return Scaffold(
      appBar: AppBar(title: const Text('NutriPal Dashboard')),
      floatingActionButton: _buildFAB(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<MealService>().fetchMeals(),
            _loadWorkoutData(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Nutrition Summary ──
            _NutritionSummaryCard(
              calories: mealService.todayCalories,
              protein: mealService.todayProtein,
              carbs: mealService.todayCarbs,
              fats: mealService.todayFats,
              targetCalories: calculations?.targetCalories,
              targetProtein: calculations?.proteinG,
              targetCarbs: calculations?.carbsG,
              targetFats: calculations?.fatsG,
            ),
            const SizedBox(height: 12),

            // ── Workout Summary ──
            _WorkoutSummaryCard(
              todayCount: _todayWorkoutCount,
              todayCalories: _todayWorkoutCalories,
              todayMinutes: _todayWorkoutMinutes,
              loading: _loadingWorkouts,
            ),
            const SizedBox(height: 16),

            // ── Quick Actions ──
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.restaurant_menu,
                    label: 'Log Meal',
                    color: AppTheme.avocado,
                    onTap: () => Navigator.pushNamed(context, '/log-meal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.fitness_center,
                    label: 'Log Workout',
                    color: AppTheme.berry,
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, '/log-workout');
                      if (result == true) _loadWorkoutData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.auto_awesome,
                    label: 'Meal Plan',
                    color: Colors.orange.shade700,
                    outlined: true,
                    onTap: () =>
                        Navigator.pushNamed(context, '/create-nutrition-plan'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.auto_awesome_motion,
                    label: 'Workout Plan',
                    color: Colors.deepPurple,
                    outlined: true,
                    onTap: () =>
                        Navigator.pushNamed(context, '/create-workout-plan'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Recent Activity ──
            const Text('Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (entries.isEmpty && _recentWorkouts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'No activity yet. Log your first meal or workout to get started!'),
                ),
              )
            else ...[
              // Interleave recent meals and workouts by time
              ..._buildRecentActivityList(entries, _recentWorkouts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.restaurant, color: AppTheme.avocado),
                  title: const Text('Log Meal'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/log-meal');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.fitness_center, color: AppTheme.berry),
                  title: const Text('Log Workout'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/log-workout').then((result) {
                      if (result == true) _loadWorkoutData();
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }

  List<Widget> _buildRecentActivityList(
      List entries, List<Workout> workouts) {
    // Build combined list of recent items
    final List<Widget> items = [];

    // Add recent meals (max 3)
    for (final meal in entries.take(3)) {
      items.add(Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.mint,
            child: const Icon(Icons.local_dining, color: AppTheme.avocado, size: 20),
          ),
          title: Text(meal.mealName),
          subtitle: Text('${meal.mealType} • ${meal.calories} kcal'),
          trailing: Text('P${meal.protein} C${meal.carbs} F${meal.fats}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ));
    }

    // Add recent workouts (max 3)
    for (final w in workouts.take(3)) {
      items.add(Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF3E5F5),
            child: const Icon(Icons.fitness_center, color: AppTheme.berry, size: 20),
          ),
          title: Text(w.exerciseName),
          subtitle: Text(
              '${w.workoutType[0].toUpperCase()}${w.workoutType.substring(1)} • ${w.duration} min'),
          trailing: Text('${w.caloriesBurned.toInt()} kcal',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ));
    }

    return items;
  }
}

// ── Nutrition Summary Card ──

class _NutritionSummaryCard extends StatelessWidget {
  final int calories, protein, carbs, fats;
  final int? targetCalories, targetProtein, targetCarbs, targetFats;

  const _NutritionSummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFats,
  });

  @override
  Widget build(BuildContext context) {
    final hasTargets = targetCalories != null &&
        targetProtein != null &&
        targetCarbs != null &&
        targetFats != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, size: 18, color: AppTheme.avocado),
                const SizedBox(width: 6),
                const Text('Nutrition Today',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasTargets)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$calories kcal • P${protein}g C${carbs}g F${fats}g'),
                  const SizedBox(height: 4),
                  Text('Complete onboarding for goal tracking.',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ProgressRing(
                      label: 'Kcal',
                      current: calories.toDouble(),
                      target: targetCalories!.toDouble(),
                      color: Colors.orange),
                  _ProgressRing(
                      label: 'P',
                      current: protein.toDouble(),
                      target: targetProtein!.toDouble(),
                      color: Colors.green),
                  _ProgressRing(
                      label: 'C',
                      current: carbs.toDouble(),
                      target: targetCarbs!.toDouble(),
                      color: Colors.blue),
                  _ProgressRing(
                      label: 'F',
                      current: fats.toDouble(),
                      target: targetFats!.toDouble(),
                      color: Colors.pink),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Workout Summary Card ──

class _WorkoutSummaryCard extends StatelessWidget {
  final int todayCount;
  final double todayCalories;
  final double todayMinutes;
  final bool loading;

  const _WorkoutSummaryCard({
    required this.todayCount,
    required this.todayCalories,
    required this.todayMinutes,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    size: 18, color: AppTheme.berry),
                const SizedBox(width: 6),
                const Text('Workout Today',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else if (todayCount == 0)
              Text('No workouts yet today. Time to move!',
                  style: TextStyle(color: Colors.grey.shade600))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                      icon: Icons.repeat,
                      value: '$todayCount',
                      label: 'Workouts'),
                  _StatChip(
                      icon: Icons.timer,
                      value: '${todayMinutes.toInt()}',
                      label: 'Minutes'),
                  _StatChip(
                      icon: Icons.local_fire_department,
                      value: '${todayCalories.toInt()}',
                      label: 'Calories'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.berry),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _ProgressRing({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = target <= 0 ? 1 : target;
    final progress = (current / safeTarget).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                color: color,
                backgroundColor: color.withOpacity(0.18),
              ),
              Center(
                child: Text('$percent%',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('$label ${current.toInt()}/${safeTarget.toInt()}',
            style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
