import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import 'package:intl/intl.dart';

/// Workout History Page - Shows all workouts with filters
class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<Workout> _workouts = [];
  List<Workout> _filteredWorkouts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    
    try {
      final workoutService = context.read<WorkoutService>();
      final workouts = await workoutService.getWorkouts();
      setState(() {
        _workouts = workouts;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workouts: ${e.toString()}')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredWorkouts = List.from(_workouts);
    } else {
      _filteredWorkouts = _workouts.where((workout) {
        return workout.workoutType.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }
    
    // Sort by date (newest first)
    _filteredWorkouts.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _deleteWorkout(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final workoutService = context.read<WorkoutService>();
        await workoutService.deleteWorkout(id);
        _loadWorkouts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout deleted'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting workout: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Workout History',
          style: TextStyle(
            color: AppTheme.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Strength'),
                const SizedBox(width: 8),
                _buildFilterChip('Cardio'),
                const SizedBox(width: 8),
                _buildFilterChip('Flexibility'),
                const SizedBox(width: 8),
                _buildFilterChip('Sports'),
                const SizedBox(width: 8),
                _buildFilterChip('Other'),
              ],
            ),
          ),

          // Workout list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkouts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadWorkouts,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: _filteredWorkouts.length,
                          itemBuilder: (context, index) {
                            return _buildWorkoutCard(_filteredWorkouts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/log-workout');
          if (result == true) {
            _loadWorkouts();
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label.toLowerCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label.toLowerCase();
          _applyFilter();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.darkBrown : AppTheme.darkBrown.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
        width: 2,
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getWorkoutColor(workout).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getWorkoutColor(workout),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getWorkoutIcon(workout),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.exerciseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d, y \u2022 h:mm a').format(workout.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkBrown.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteWorkout(workout.id ?? ''),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.timer, '${workout.duration} min'),
                    _buildStatItem(Icons.local_fire_department, '${workout.caloriesBurned.toInt()} cal'),
                    _buildStatItem(Icons.speed, workout.intensityLevel),
                  ],
                ),
                
                // Strength training details if available
                if (workout.sets != null && workout.reps != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.fitness_center, '${workout.sets} sets'),
                      _buildStatItem(Icons.repeat, '${workout.reps} reps'),
                      if (workout.weight != null)
                        _buildStatItem(Icons.scale, '${workout.weight}kg'),
                    ],
                  ),
                ],
                
                // Notes if available
                if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkBrown.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBrown.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all' 
                ? 'Start logging your workouts!'
                : 'No ${_selectedFilter.toLowerCase()} workouts yet',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.darkBrown.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWorkoutColor(Workout workout) {
    switch (workout.workoutType.toLowerCase()) {
      case 'cardio':
        return Colors.orange;
      case 'strength':
        return AppTheme.primaryGreen;
      case 'flexibility':
        return Colors.purple;
      case 'sports':
        return Colors.blue;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getWorkoutIcon(Workout workout) {
    switch (workout.workoutType.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.self_improvement;
      case 'sports':
        return Icons.sports_tennis;
      default:
        return Icons.fitness_center;
    }
  }
}
