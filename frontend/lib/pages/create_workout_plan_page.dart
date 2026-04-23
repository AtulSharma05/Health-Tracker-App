import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../services/workout_plan_service.dart';
import '../services/exercise_database_service.dart';
import '../widgets/exercise_details_dialog.dart';

class CreateWorkoutPlanPage extends StatefulWidget {
  const CreateWorkoutPlanPage({super.key});

  @override
  State<CreateWorkoutPlanPage> createState() => _CreateWorkoutPlanPageState();
}

class _CreateWorkoutPlanPageState extends State<CreateWorkoutPlanPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String _selectedGoal = 'muscle_gain';
  String _selectedExperience = 'intermediate';
  int _daysPerWeek = 3;
  int _duration = 60;
  
  // Equipment options
  final Map<String, bool> _equipment = {
    'Barbell': false,
    'Dumbbell': false,
    'Machine': false,
    'Bodyweight': true,
    'Cable': false,
    'Resistance Band': false,
  };
  
  // Target muscles
  final Map<String, bool> _targetMuscles = {
    'Chest': false,
    'Back': false,
    'Shoulders': false,
    'Arms': false,
    'Legs': false,
    'Core': false,
  };
  
  bool _isLoading = false;
  bool _serviceAvailable = true;
  WorkoutPlan? _generatedPlan;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final service = Provider.of<WorkoutPlanService>(context, listen: false);
    final status = await service.getServiceStatus();
    setState(() {
      _serviceAvailable = status['status'] == 'online';
    });
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _generatedPlan = null;
    });

    try {
      final service = Provider.of<WorkoutPlanService>(context, listen: false);
      
      final selectedEquipment = _equipment.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      
      final selectedMuscles = _targetMuscles.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final plan = await service.generatePlan(
        goal: _selectedGoal,
        experience: _selectedExperience,
        daysPerWeek: _daysPerWeek,
        equipment: selectedEquipment.isEmpty ? null : selectedEquipment,
        targetMuscles: selectedMuscles.isEmpty ? null : selectedMuscles,
        duration: _duration,
      );

      setState(() {
        _generatedPlan = plan;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Workout Planner'),
        actions: [
          IconButton(
            icon: Icon(
              _serviceAvailable ? Icons.cloud_done : Icons.cloud_off,
              color: _serviceAvailable ? Colors.green : Colors.red,
            ),
            onPressed: _checkServiceStatus,
            tooltip: _serviceAvailable ? 'AI Service Online' : 'AI Service Offline',
          ),
        ],
      ),
      body: _generatedPlan == null
          ? _buildForm()
          : _buildPlanView(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_serviceAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI service is currently offline. Please ensure the backend server is running.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Goal Selection
            const Text(
              'Fitness Goal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'muscle_gain',
                  label: Text('Build Muscle'),
                  icon: Icon(Icons.fitness_center),
                ),
                ButtonSegment(
                  value: 'weight_loss',
                  label: Text('Lose Weight'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: 'general_fitness',
                  label: Text('General Fitness'),
                  icon: Icon(Icons.favorite),
                ),
              ],
              selected: {_selectedGoal},
              onSelectionChanged: (Set<String> value) {
                setState(() {
                  _selectedGoal = value.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Experience Level
            const Text(
              'Experience Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'beginner', label: Text('Beginner')),
                ButtonSegment(value: 'intermediate', label: Text('Intermediate')),
                ButtonSegment(value: 'advanced', label: Text('Advanced')),
              ],
              selected: {_selectedExperience},
              onSelectionChanged: (Set<String> value) {
                setState(() {
                  _selectedExperience = value.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Days per Week
            const Text(
              'Workout Days per Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _daysPerWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: _daysPerWeek.toString(),
                    onChanged: (value) {
                      setState(() {
                        _daysPerWeek = value.toInt();
                      });
                    },
                  ),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '$_daysPerWeek days',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration
            const Text(
              'Workout Duration (minutes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 30,
                    max: 120,
                    divisions: 9,
                    label: _duration.toString(),
                    onChanged: (value) {
                      setState(() {
                        _duration = value.toInt();
                      });
                    },
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    '$_duration min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Equipment
            const Text(
              'Available Equipment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipment.keys.map((equipment) {
                return FilterChip(
                  label: Text(equipment),
                  selected: _equipment[equipment]!,
                  onSelected: (selected) {
                    setState(() {
                      _equipment[equipment] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Target Muscles
            const Text(
              'Target Muscle Groups (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _targetMuscles.keys.map((muscle) {
                return FilterChip(
                  label: Text(muscle),
                  selected: _targetMuscles[muscle]!,
                  onSelected: (selected) {
                    setState(() {
                      _targetMuscles[muscle] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || !_serviceAvailable ? null : _generatePlan,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Generating...' : 'Generate AI Workout Plan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView() {
    if (_generatedPlan == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Personalized Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _generatedPlan = null;
                          });
                        },
                        tooltip: 'Create New Plan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Goal', _capitalizeWords(_generatedPlan!.goal)),
                  _buildInfoRow('Experience', _capitalizeWords(_generatedPlan!.experience)),
                  _buildInfoRow('Days/Week', '${_generatedPlan!.daysPerWeek}'),
                  _buildInfoRow('Duration', '${_generatedPlan!.duration} min'),
                  if (_generatedPlan!.equipment.isNotEmpty)
                    _buildInfoRow('Equipment', _generatedPlan!.equipment.join(', ')),
                  if (_generatedPlan!.targetMuscles.isNotEmpty)
                    _buildInfoRow('Target Muscles', _generatedPlan!.targetMuscles.join(', ')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Workout Days
          const Text(
            'Workout Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Show text plan if available and no structured days
          if (_generatedPlan!.plan != null && _generatedPlan!.days.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _generatedPlan!.plan!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            )
          else if (_generatedPlan!.days.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedPlan!.days.length,
              itemBuilder: (context, index) {
                final day = _generatedPlan!.days[index];
                return _buildDayCard(day);
              },
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No workout schedule available. Please try generating a new plan.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCard(WorkoutDay day) {
    final isRestDay = day.exercises.isEmpty || day.focus.toLowerCase() == 'rest';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'Day ${day.dayNumber} - ${day.focus}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isRestDay 
            ? 'Recovery day' 
            : '${day.estimatedDuration} min • ${day.exercises.length} exercises'
        ),
        children: [
          if (isRestDay)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.spa, size: 48, color: Colors.green.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Rest & Recovery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take this day to let your muscles recover and grow stronger.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: day.exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return _buildExerciseItem(exercise, index + 1);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise, int number) {
    return InkWell(
      onTap: () => _showExerciseDetails(exercise.name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(Icons.play_circle_outline, size: 18, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.fitness_center, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${exercise.sets} sets × ${exercise.reps} reps',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (exercise.restSeconds != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.restSeconds}s rest',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (exercise.equipment != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          exercise.equipment!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExerciseDetails(String exerciseName) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final exerciseService = Provider.of<ExerciseDatabaseService>(context, listen: false);
      final details = await exerciseService.getExerciseDetails(exerciseName);
      
      // Close loading indicator
      if (mounted) Navigator.pop(context);
      
      if (details != null && mounted) {
        // Show exercise details dialog with GIF
        showDialog(
          context: context,
          builder: (context) => ExerciseDetailsDialog(exerciseDetails: details),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find details for "$exerciseName"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercise: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _capitalizeWords(String text) {
    return text.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
