import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/meal_service.dart';

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteMeal(String id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal'),
        content: const Text('Do you want to remove this meal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await context.read<MealService>().removeMeal(id);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealService>().fetchMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealService = context.watch<MealService>();
    final filtered = mealService.entries.where((meal) {
      final matchesType = _selectedType == 'All' || meal.mealType == _selectedType;
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty || meal.mealName.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: mealService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mealService.entries.isEmpty
              ? const Center(child: Text('No meals logged yet.'))
              : RefreshIndicator(
                  onRefresh: () => context.read<MealService>().fetchMeals(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search meal name',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (_) => setState(() => _selectedType = type),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No meals match current filters.')),
                        )
                      else
                        ...filtered.map((meal) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.local_dining),
                              title: Text(meal.mealName),
                              subtitle: Text(
                                '${meal.mealType} • ${DateFormat('MMM d, h:mm a').format(meal.createdAt)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${meal.calories} kcal'),
                                  IconButton(
                                    onPressed: () => _deleteMeal(meal.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
