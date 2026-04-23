import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Exercise Selection Page
/// Displays all available exercises for pose detection with search functionality
class ExerciseSelectionPage extends StatefulWidget {
  const ExerciseSelectionPage({super.key});

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Comprehensive list of exercises available for pose detection
  final List<Map<String, dynamic>> _allExercises = [
    // Upper Body - Arms
    {'name': 'Bicep Curl', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Hammer Curl', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Concentration Curl', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Preacher Curl', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Triceps Extension', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Overhead Tricep Extension', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Tricep Dips', 'category': 'Arms', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    
    // Upper Body - Chest
    {'name': 'Push-up', 'category': 'Chest', 'icon': Icons.self_improvement, 'difficulty': 'Beginner'},
    {'name': 'Incline Push-up', 'category': 'Chest', 'icon': Icons.self_improvement, 'difficulty': 'Beginner'},
    {'name': 'Decline Push-up', 'category': 'Chest', 'icon': Icons.self_improvement, 'difficulty': 'Intermediate'},
    {'name': 'Wide Push-up', 'category': 'Chest', 'icon': Icons.self_improvement, 'difficulty': 'Beginner'},
    {'name': 'Bench Press', 'category': 'Chest', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Incline Bench Press', 'category': 'Chest', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    
    // Upper Body - Shoulders
    {'name': 'Shoulder Press', 'category': 'Shoulders', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Lateral Raise', 'category': 'Shoulders', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Front Raise', 'category': 'Shoulders', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Rear Delt Raise', 'category': 'Shoulders', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Upright Row', 'category': 'Shoulders', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Arnold Press', 'category': 'Shoulders', 'icon': Icons.fitness_center, 'difficulty': 'Advanced'},
    
    // Upper Body - Back
    {'name': 'Pull-up', 'category': 'Back', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Chin-up', 'category': 'Back', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Bent Over Row', 'category': 'Back', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Lat Pulldown', 'category': 'Back', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Seated Cable Row', 'category': 'Back', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    
    // Lower Body - Legs
    {'name': 'Squat', 'category': 'Legs', 'icon': Icons.airline_seat_recline_extra, 'difficulty': 'Beginner'},
    {'name': 'Front Squat', 'category': 'Legs', 'icon': Icons.airline_seat_recline_extra, 'difficulty': 'Intermediate'},
    {'name': 'Bulgarian Split Squat', 'category': 'Legs', 'icon': Icons.airline_seat_recline_extra, 'difficulty': 'Intermediate'},
    {'name': 'Goblet Squat', 'category': 'Legs', 'icon': Icons.airline_seat_recline_extra, 'difficulty': 'Beginner'},
    {'name': 'Lunge', 'category': 'Legs', 'icon': Icons.directions_walk, 'difficulty': 'Beginner'},
    {'name': 'Reverse Lunge', 'category': 'Legs', 'icon': Icons.directions_walk, 'difficulty': 'Beginner'},
    {'name': 'Walking Lunge', 'category': 'Legs', 'icon': Icons.directions_walk, 'difficulty': 'Intermediate'},
    {'name': 'Leg Press', 'category': 'Legs', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Leg Extension', 'category': 'Legs', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Leg Curl', 'category': 'Legs', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    {'name': 'Calf Raise', 'category': 'Legs', 'icon': Icons.fitness_center, 'difficulty': 'Beginner'},
    
    // Core
    {'name': 'Plank', 'category': 'Core', 'icon': Icons.align_horizontal_left, 'difficulty': 'Beginner'},
    {'name': 'Side Plank', 'category': 'Core', 'icon': Icons.align_horizontal_left, 'difficulty': 'Intermediate'},
    {'name': 'Sit-up', 'category': 'Core', 'icon': Icons.airline_seat_recline_normal, 'difficulty': 'Beginner'},
    {'name': 'Crunch', 'category': 'Core', 'icon': Icons.airline_seat_recline_normal, 'difficulty': 'Beginner'},
    {'name': 'Russian Twist', 'category': 'Core', 'icon': Icons.rotate_90_degrees_ccw, 'difficulty': 'Intermediate'},
    {'name': 'Bicycle Crunch', 'category': 'Core', 'icon': Icons.pedal_bike, 'difficulty': 'Intermediate'},
    {'name': 'Leg Raise', 'category': 'Core', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Mountain Climber', 'category': 'Core', 'icon': Icons.landscape, 'difficulty': 'Intermediate'},
    
    // Cardio
    {'name': 'Jumping Jack', 'category': 'Cardio', 'icon': Icons.accessibility_new, 'difficulty': 'Beginner'},
    {'name': 'Burpee', 'category': 'Cardio', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'High Knees', 'category': 'Cardio', 'icon': Icons.directions_run, 'difficulty': 'Beginner'},
    {'name': 'Butt Kicks', 'category': 'Cardio', 'icon': Icons.directions_run, 'difficulty': 'Beginner'},
    {'name': 'Jump Squat', 'category': 'Cardio', 'icon': Icons.airline_seat_recline_extra, 'difficulty': 'Intermediate'},
    {'name': 'Box Jump', 'category': 'Cardio', 'icon': Icons.stairs, 'difficulty': 'Advanced'},
    
    // Full Body
    {'name': 'Deadlift', 'category': 'Full Body', 'icon': Icons.fitness_center, 'difficulty': 'Intermediate'},
    {'name': 'Clean and Press', 'category': 'Full Body', 'icon': Icons.fitness_center, 'difficulty': 'Advanced'},
    {'name': 'Thruster', 'category': 'Full Body', 'icon': Icons.fitness_center, 'difficulty': 'Advanced'},
    {'name': 'Turkish Get-up', 'category': 'Full Body', 'icon': Icons.fitness_center, 'difficulty': 'Advanced'},
  ];

  final List<String> _categories = [
    'All',
    'Arms',
    'Chest',
    'Shoulders',
    'Back',
    'Legs',
    'Core',
    'Cardio',
    'Full Body',
  ];

  List<Map<String, dynamic>> get _filteredExercises {
    return _allExercises.where((exercise) {
      final matchesSearch = exercise['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || exercise['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _filteredExercises;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text(
          'Select Exercise',
          style: TextStyle(
            color: AppTheme.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkBrown),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.darkBrown : AppTheme.darkBrown.withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredExercises.length} exercises found',
                  style: TextStyle(
                    color: AppTheme.darkBrown.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.darkBrown.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to start',
                  style: TextStyle(
                    color: AppTheme.darkBrown.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Exercise List
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.darkBrown.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.darkBrown.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or category',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkBrown.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return _ExerciseCard(
                        exercise: exercise,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/pose-analysis',
                            arguments: {
                              'exerciseName': exercise['name'].toString().toLowerCase()
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  exercise['icon'] as IconData,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Exercise Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise['category'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkBrown.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(exercise['difficulty'] as String)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise['difficulty'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDifficultyColor(exercise['difficulty'] as String),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.darkBrown.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
