import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nutrition_plan_service.dart';

class CreateNutritionPlanPage extends StatefulWidget {
  const CreateNutritionPlanPage({super.key});

  @override
  State<CreateNutritionPlanPage> createState() => _CreateNutritionPlanPageState();
}

class _CreateNutritionPlanPageState extends State<CreateNutritionPlanPage> {
  // 🎯 Macro preference toggles
  bool _highProtein = false;
  bool _lowCarb = false;

  // 🍽️ Dietary restrictions
  bool _vegetarian = false;
  bool _vegan = false;
  bool _dairyFree = false;
  bool _glutenFree = false;
  bool _indianOnly = true;

  // 📊 Calorie range control
  double _minCalories = 1800;
  double _maxCalories = 2400;

  bool _loading = false;
  String? _error;
  GeneratedPlan? _plan;

  Future<void> _generate() async {
    // Can't select both at once - they conflict
    if (_highProtein && _lowCarb) {
      setState(() {
        _error = 'Select either High-Protein or Low-Carb, not both';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await context.read<NutritionPlanService>().generatePlan(
            vegetarian: _vegetarian,
            vegan: _vegan,
            dairyFree: _dairyFree,
            glutenFree: _glutenFree,
            indianOnly: _indianOnly,
            // ✨ NEW: Pass macro preferences
            highProtein: _highProtein,
            lowCarb: _lowCarb,
            calorieMin: _minCalories.toInt(),
            calorieMax: _maxCalories.toInt(),
          );

      if (!mounted) return;
      setState(() {
        _plan = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Map<DateTime, List<PlannedMeal>> _groupMealsByDay(List<PlannedMeal> meals) {
    final grouped = <DateTime, List<PlannedMeal>>{};
    for (final meal in meals) {
      final key = DateTime(meal.date.year, meal.date.month, meal.date.day);
      grouped.putIfAbsent(key, () => []).add(meal);
    }
    return grouped;
  }

  Widget _buildMacroPreferenceCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Macro Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              dense: true,
              title: const Text('🥩 High-Protein (30% calories)'),
              subtitle: const Text('Great for muscle building'),
              value: _highProtein,
              onChanged: (v) {
                setState(() {
                  _highProtein = v ?? false;
                  if (_highProtein) _lowCarb = false; // Clear conflicting option
                });
              },
            ),
            CheckboxListTile(
              dense: true,
              title: const Text('🥬 Low-Carb (20-30% calories)'),
              subtitle: const Text('Great for energy management'),
              value: _lowCarb,
              onChanged: (v) {
                setState(() {
                  _lowCarb = v ?? false;
                  if (_lowCarb) _highProtein = false; // Clear conflicting option
                });
              },
            ),
            const SizedBox(height: 12),
            const Text('Calorie Range (daily):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(_minCalories.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _minCalories,
                        min: 1000,
                        max: 3000,
                        divisions: 20,
                        onChanged: (v) {
                          setState(() {
                            _minCalories = v;
                            if (_minCalories > _maxCalories) _maxCalories = _minCalories;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(_maxCalories.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _maxCalories,
                        min: 1500,
                        max: 5000,
                        divisions: 35,
                        onChanged: (v) {
                          setState(() {
                            _maxCalories = v;
                            if (_maxCalories < _minCalories) _minCalories = _maxCalories;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryRestrictionsCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Dietary Restrictions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              dense: true,
              title: const Text('Vegetarian'),
              value: _vegetarian,
              onChanged: (v) => setState(() => _vegetarian = v),
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Vegan'),
              value: _vegan,
              onChanged: (v) => setState(() => _vegan = v),
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Dairy free'),
              value: _dairyFree,
              onChanged: (v) => setState(() => _dairyFree = v),
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Gluten free'),
              value: _glutenFree,
              onChanged: (v) => setState(() => _glutenFree = v),
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Indian meals only'),
              value: _indianOnly,
              onChanged: (v) => setState(() => _indianOnly = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary() {
    if (_plan == null) return const SizedBox.shrink();

    final planDesc = _plan!.planDescription ?? 'Custom Meal Plan';

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    planDesc,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text('Daily Targets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutrientColumn('Calories', _plan!.targetCalories.toStringAsFixed(0), 'kcal'),
                      _buildNutrientColumn('Protein', _plan!.targetProtein.toStringAsFixed(0), 'g'),
                      _buildNutrientColumn('Carbs', _plan!.targetCarbs.toStringAsFixed(0), 'g'),
                      _buildNutrientColumn('Fats', _plan!.targetFats.toStringAsFixed(0), 'g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text('7-Day Plan Totals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutrientColumn('Calories', (_plan!.planTotalCalories / 7).toStringAsFixed(0), 'kcal/day'),
                      _buildNutrientColumn('Protein', (_plan!.planTotalProtein / 7).toStringAsFixed(0), 'g/day'),
                      _buildNutrientColumn('Carbs', (_plan!.planTotalCarbs / 7).toStringAsFixed(0), 'g/day'),
                      _buildNutrientColumn('Fats', (_plan!.planTotalFats / 7).toStringAsFixed(0), 'g/day'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientColumn(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Nutrition Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          const Text(
            'AI-Powered Meal Planning',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose your preferences and generate a personalized 7-day plan',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Macro preferences
          _buildMacroPreferenceCard(),
          const SizedBox(height: 16),

          // Dietary restrictions
          _buildDietaryRestrictionsCard(),
          const SizedBox(height: 16),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 12),

          // Generate button
          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Generating...' : 'Generate 7-Day Plan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Plan display
          if (_plan != null) ...[
            _buildPlanSummary(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Day-by-Day Meals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._groupMealsByDay(_plan!.meals).entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(entry.key),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map(
                            (meal) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${meal.mealType} • ${meal.calories.toStringAsFixed(0)} kcal | '
                                      'P ${meal.protein.toStringAsFixed(0)}g | '
                                      'C ${meal.carbs.toStringAsFixed(0)}g | '
                                      'F ${meal.fats.toStringAsFixed(0)}g',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...meal.items.map((item) => Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                                        child: Text(
                                          '• ${item.foodName} (${item.servings.toStringAsFixed(1)} serving, ${item.grams.toStringAsFixed(0)}g)',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[date.weekday - 1]}, ${date.month}/${date.day}';
  }
}
