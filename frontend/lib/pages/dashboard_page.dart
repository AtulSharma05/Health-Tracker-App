import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meal_service.dart';
import '../services/profile_service.dart';

class DashboardPage extends StatelessWidget {
  final void Function(int)? onSwitchTab;

  const DashboardPage({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final mealService = context.watch<MealService>();
    final profileService = context.watch<ProfileService>();
    final calculations = profileService.calculations;
    final entries = mealService.entries;

    return Scaffold(
      appBar: AppBar(title: const Text('NutriPal Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/log-meal'),
        label: const Text('Log Meal'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            calories: mealService.todayCalories,
            protein: mealService.todayProtein,
            carbs: mealService.todayCarbs,
            fats: mealService.todayFats,
            targetCalories: calculations?.targetCalories,
            targetProtein: calculations?.proteinG,
            targetCarbs: calculations?.carbsG,
            targetFats: calculations?.fatsG,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/create-nutrition-plan'),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Nutrition Plan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/meal-history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Meal History'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Recent Meals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No meals yet. Start by logging breakfast, lunch, or dinner.'),
              ),
            )
          else
            ...entries.take(4).map(
              (meal) => Card(
                child: ListTile(
                  leading: const Icon(Icons.local_dining),
                  title: Text(meal.mealName),
                  subtitle: Text('${meal.mealType} • ${meal.calories} kcal'),
                  trailing: Text('P${meal.protein} C${meal.carbs} F${meal.fats}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int? targetCalories;
  final int? targetProtein;
  final int? targetCarbs;
  final int? targetFats;

  const _SummaryCard({
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
    final hasTargets = targetCalories != null && targetProtein != null && targetCarbs != null && targetFats != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Calories: $calories kcal'),
            Text('Protein: $protein g'),
            Text('Carbs: $carbs g'),
            Text('Fats: $fats g'),
            const SizedBox(height: 14),
            if (!hasTargets)
              const Text(
                'Set your profile and goals to see progress rings.',
                style: TextStyle(color: Colors.black54),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal Progress', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProgressRing(
                        label: 'Kcal',
                        current: calories.toDouble(),
                        target: targetCalories!.toDouble(),
                        color: Colors.orange,
                      ),
                      _ProgressRing(
                        label: 'P',
                        current: protein.toDouble(),
                        target: targetProtein!.toDouble(),
                        color: Colors.green,
                      ),
                      _ProgressRing(
                        label: 'C',
                        current: carbs.toDouble(),
                        target: targetCarbs!.toDouble(),
                        color: Colors.blue,
                      ),
                      _ProgressRing(
                        label: 'F',
                        current: fats.toDouble(),
                        target: targetFats!.toDouble(),
                        color: Colors.pink,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
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
          width: 64,
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                color: color,
                backgroundColor: color.withOpacity(0.18),
              ),
              Center(
                child: Text(
                  '$percent%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('$label ${current.toInt()}/${safeTarget.toInt()}', style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
