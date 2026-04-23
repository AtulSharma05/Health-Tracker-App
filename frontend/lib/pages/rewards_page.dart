import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meal_service.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealService>().entries.length;
    final points = meals * 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text('Points: $points'),
              subtitle: Text('$meals meals logged'),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.emoji_events),
              title: Text('First 10 Meals'),
              subtitle: Text('Unlock when you log 10 meals'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.local_fire_department),
              title: Text('7-Day Nutrition Streak'),
              subtitle: Text('Log meals for 7 consecutive days'),
            ),
          ),
        ],
      ),
    );
  }
}
