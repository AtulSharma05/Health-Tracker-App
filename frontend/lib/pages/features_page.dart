import 'package:flutter/material.dart';
import 'rewards_page.dart';

class FeaturesPage extends StatelessWidget {
  final void Function(int)? onSwitchTab;

  const FeaturesPage({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NutriPal Features')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _FeatureTile(
            title: 'Log Workout',
            icon: Icons.fitness_center,
            onTap: () => Navigator.pushNamed(context, '/log-workout'),
          ),
          _FeatureTile(
            title: 'Workout History',
            icon: Icons.history_toggle_off,
            onTap: () => Navigator.pushNamed(context, '/workout-history'),
          ),
          _FeatureTile(
            title: 'Workout Planner',
            icon: Icons.auto_awesome_motion,
            onTap: () => Navigator.pushNamed(context, '/create-workout-plan'),
          ),
          _FeatureTile(
            title: 'Log Meal',
            icon: Icons.add_circle,
            onTap: () => Navigator.pushNamed(context, '/log-meal'),
          ),
          _FeatureTile(
            title: 'Meal History',
            icon: Icons.history,
            onTap: () => Navigator.pushNamed(context, '/meal-history'),
          ),
          _FeatureTile(
            title: 'Meal Planner',
            icon: Icons.auto_awesome,
            onTap: () => Navigator.pushNamed(context, '/create-nutrition-plan'),
          ),
          _FeatureTile(
            title: 'Rewards',
            icon: Icons.emoji_events,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
