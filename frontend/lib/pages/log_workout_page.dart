import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_service.dart';

/// Log Workout Page - Form to add new workouts
class LogWorkoutPage extends StatefulWidget {
  final String? initialWorkoutType;
  
  const LogWorkoutPage({super.key, this.initialWorkoutType});

  @override
  State<LogWorkoutPage> createState() => _LogWorkoutPageState();
}

class _LogWorkoutPageState extends State<LogWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _exerciseNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _workoutType = 'strength';
  String _intensityLevel = 'moderate';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set initial workout type if provided
    if (widget.initialWorkoutType != null) {
      _workoutType = widget.initialWorkoutType!;
    }
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final workoutService = context.read<WorkoutService>();
      
      // Parse values with error handling
      final duration = int.tryParse(_durationController.text.trim()) ?? 0;
      final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
      final sets = _setsController.text.trim().isNotEmpty 
          ? int.tryParse(_setsController.text.trim()) 
          : null;
      final reps = _repsController.text.trim().isNotEmpty 
          ? int.tryParse(_repsController.text.trim()) 
          : null;
      final weight = _weightController.text.trim().isNotEmpty 
          ? double.tryParse(_weightController.text.trim()) 
          : null;
      
      await workoutService.createWorkoutFromParams(
        exerciseName: _exerciseNameController.text.trim(),
        workoutType: _workoutType,
        duration: duration,
        caloriesBurned: calories,
        date: DateTime.now(),
        sets: sets,
        reps: reps,
        weight: weight,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        intensityLevel: _intensityLevel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout logged successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          icon: const Icon(Icons.close, color: AppTheme.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Log Workout',
          style: TextStyle(
            color: AppTheme.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveWorkout,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('Workout Details'),
            const SizedBox(height: 16),
            
            // Exercise Name
            _buildTextField(
              controller: _exerciseNameController,
              label: 'Exercise Name',
              hint: 'e.g., Bench Press, Running',
              validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Workout Type Dropdown
            _buildDropdownField(
              value: _workoutType,
              label: 'Workout Type',
              items: const ['strength', 'cardio', 'flexibility', 'sports', 'other'],
              onChanged: (value) => setState(() => _workoutType = value!),
            ),
            const SizedBox(height: 16),
            
            // Duration and Calories Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _durationController,
                    label: 'Duration (min)',
                    hint: '30',
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _caloriesController,
                    label: 'Calories',
                    hint: '250',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Strength Training (Optional)'),
            const SizedBox(height: 16),
            
            // Sets, Reps, Weight Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _setsController,
                    label: 'Sets',
                    hint: '3',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _repsController,
                    label: 'Reps',
                    hint: '12',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    hint: '50',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Intensity Level
            _buildDropdownField(
              value: _intensityLevel,
              label: 'Intensity Level',
              items: const ['low', 'moderate', 'high', 'extreme'],
              onChanged: (value) => setState(() => _intensityLevel = value!),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'How did it feel?',
              maxLines: 3,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkBrown,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }
  
  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item[0].toUpperCase() + item.substring(1)),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
