import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_entry.dart';
import '../models/food.dart';
import '../services/meal_service.dart';
import '../services/food_service.dart';
import '../services/api_service.dart';
import '../utils/serving_unit_converter.dart';

class LogMealPage extends StatefulWidget {
  const LogMealPage({super.key});

  @override
  State<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends State<LogMealPage> {
  final _foodSearchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  late FoodService _foodService;
  
  List<Food> _searchResults = [];
  Food? _selectedFood;
  String _mealType = 'Breakfast';
  String _selectedUnit = 'g'; // Selected unit for quantity
  bool _isSearching = false;
  bool _saving = false;
  
  Map<String, double> _calculatedNutrition = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fats': 0,
    'fiber': 0,
  };

  @override
  void initState() {
    super.initState();
    _foodService = FoodService(context.read<ApiService>());
    _foodSearchController.addListener(_onSearchChanged);
    _quantityController.addListener(_updateNutrition);
  }

  @override
  void dispose() {
    _foodSearchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _foodSearchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _foodService.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching foods: $e')),
        );
      }
    }
  }

  void _selectFood(Food food) {
    setState(() {
      _selectedFood = food;
      _foodSearchController.text = food.name;
      _searchResults = [];
      // Reset unit to first available for this food
      final units = food.getAvailableUnits();
      _selectedUnit = units.isNotEmpty ? units.first : 'g';
      // Set suggested quantity for the selected unit
      _quantityController.text = food.suggestServingQuantity(_selectedUnit).toString();
    });
    _updateNutrition();
  }

  void _updateNutrition() {
    if (_selectedFood == null) {
      setState(() => _calculatedNutrition = {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
        'fiber': 0,
      });
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      setState(() => _calculatedNutrition = {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
        'fiber': 0,
      });
      return;
    }

    setState(() {
      _calculatedNutrition = _selectedFood!.calculateNutritionByUnit(quantity, _selectedUnit);
    });
  }

  Future<void> _saveMeal() async {
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food item')),
      );
      return;
    }

    if (_calculatedNutrition['calories'] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _saving = true);

    // Convert to grams for display
    final gramsTotal = ServingUnitConverter.convertToGrams(
      _selectedFood!.name,
      double.parse(_quantityController.text),
      _selectedUnit,
    );

    final mealName = '${_selectedFood!.name} (${_quantityController.text} ${_selectedUnit == 'g' ? 'g' : ServingUnitConverter.formatUnit(_selectedUnit)})';

    final meal = MealEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealName: mealName,
      mealType: _mealType,
      calories: _calculatedNutrition['calories']?.toInt() ?? 0,
      protein: _calculatedNutrition['protein']?.toInt() ?? 0,
      carbs: _calculatedNutrition['carbs']?.toInt() ?? 0,
      fats: _calculatedNutrition['fats']?.toInt() ?? 0,
      createdAt: DateTime.now(),
    );

    try {
      await context.read<MealService>().addMeal(meal);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving meal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal with Food Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Meal Type Selector
          DropdownButtonFormField<String>(
            value: _mealType,
            items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _mealType = v ?? 'Breakfast'),
            decoration: const InputDecoration(labelText: 'Meal Type'),
          ),
          const SizedBox(height: 20),

          // 2. Food Search with Autocomplete
          TextField(
            controller: _foodSearchController,
            decoration: InputDecoration(
              labelText: 'Search Food (e.g., "paneer", "rice")',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _foodSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _foodSearchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
          // 3. Autocomplete Dropdown Suggestions
          if (_searchResults.isNotEmpty && _foodSearchController.text.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final food = _searchResults[index];
                  return ListTile(
                    dense: true,
                    title: Text(food.name),
                    subtitle: Text('${food.caloriesPer100g} cal/100g • ${food.category}'),
                    onTap: () => _selectFood(food),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // 4. Selected Food Display
          if (_selectedFood != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFood!.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${_selectedFood!.category}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Base: ${_selectedFood!.caloriesPer100g.toStringAsFixed(1)} cal/100g',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 5. Quantity Input with Unit Selector ✨ NEW
          if (_selectedFood != null) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: _selectedFood!.getAvailableUnits().map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (unit) {
                      if (unit != null) {
                        setState(() => _selectedUnit = unit);
                        _updateNutrition();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Unit conversion info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                '${_quantityController.text} ${ServingUnitConverter.formatUnit(_selectedUnit)} ≈ ${ServingUnitConverter.convertToGrams(_selectedFood!.name, double.tryParse(_quantityController.text) ?? 0, _selectedUnit).toStringAsFixed(0)}g',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity (grams)',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 6. Calculated Nutrition Display
          if (_selectedFood != null)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculated Nutrition',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _nutritionBox(
                          'Calories',
                          _calculatedNutrition['calories']?.toStringAsFixed(0) ?? '0',
                          'kcal',
                        ),
                        _nutritionBox(
                          'Protein',
                          _calculatedNutrition['protein']?.toStringAsFixed(1) ?? '0',
                          'g',
                        ),
                        _nutritionBox(
                          'Carbs',
                          _calculatedNutrition['carbs']?.toStringAsFixed(1) ?? '0',
                          'g',
                        ),
                        _nutritionBox(
                          'Fats',
                          _calculatedNutrition['fats']?.toStringAsFixed(1) ?? '0',
                          'g',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // 7. Save Button
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveMeal,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Saving...' : 'Save Meal'),
          ),
        ],
      ),
    );
  }

  Widget _nutritionBox(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
