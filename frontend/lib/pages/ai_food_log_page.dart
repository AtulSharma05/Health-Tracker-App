import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/food_log_service.dart';
import '../services/meal_service.dart';
import '../theme/app_theme.dart';

class AiFoodLogPage extends StatefulWidget {
  const AiFoodLogPage({super.key});

  @override
  State<AiFoodLogPage> createState() => _AiFoodLogPageState();
}

class _AiFoodLogPageState extends State<AiFoodLogPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late FoodLogService _foodLogService;

  // State
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  // Editable fields
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _fiberController = TextEditingController();
  String _mealType = 'Lunch';
  double _confidence = 0;
  String _servingSize = '';

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _foodLogService = FoodLogService(context.read<ApiService>());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  // ─── Image Picking ───
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
        _analysisResult = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  // ─── AI Analysis ───
  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await _foodLogService.analyzeImage(
        imageBytes: _imageBytes!,
        mimeType: _imageName?.endsWith('.png') == true
            ? 'image/png'
            : 'image/jpeg',
      );

      if (!mounted) return;

      setState(() {
        _analysisResult = result;
        _foodNameController.text = result['foodName'] ?? 'Unknown';
        _caloriesController.text = (result['calories'] ?? 0).toString();
        _proteinController.text = (result['protein'] ?? 0).toString();
        _carbsController.text = (result['carbs'] ?? 0).toString();
        _fatsController.text = (result['fats'] ?? 0).toString();
        _fiberController.text = (result['fiber'] ?? 0).toString();
        _confidence = (result['confidence'] ?? 0).toDouble();
        _servingSize = (result['servingSize'] ?? '').toString();
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Analysis failed: $e';
      });
    }
  }

  // ─── Save ───
  Future<void> _saveResult() async {
    if (_analysisResult == null) return;

    setState(() => _isSaving = true);

    try {
      await _foodLogService.saveAnalysis(
        foodName: _foodNameController.text.trim(),
        mealType: _mealType,
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fats: int.tryParse(_fatsController.text) ?? 0,
        fiber: int.tryParse(_fiberController.text) ?? 0,
        confidence: _confidence,
      );

      // Refresh meal list
      if (mounted) {
        context.read<MealService>().fetchMeals();
        context.read<MealService>().fetchStats();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Meal saved successfully!'),
          backgroundColor: AppTheme.avocado,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  // ─── Build ───
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Food Scanner'),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Re-analyze',
              onPressed: _isAnalyzing ? null : _analyzeImage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Step 1: Image Capture ──
            if (_imageBytes == null) _buildImagePicker(),
            if (_imageBytes != null) ...[
              _buildImagePreview(),
              const SizedBox(height: 16),
            ],

            // ── Error message ──
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Step 2: Analyzing Indicator ──
            if (_isAnalyzing) _buildAnalyzingIndicator(),

            // ── Step 3: Analysis Results + Edit ──
            if (_analysisResult != null && !_isAnalyzing) ...[
              _buildConfidenceBadge(),
              const SizedBox(height: 12),
              _buildNutrientCards(),
              const SizedBox(height: 16),
              _buildEditableForm(),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ─── UI Components ───

  Widget _buildImagePicker() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.avocado.withOpacity(0.08),
            AppTheme.mint.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.avocado.withOpacity(0.2),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.avocado.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 48,
              color: AppTheme.avocado,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan Your Food',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.avocado,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a photo or upload from gallery',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: AppTheme.avocado,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: AppTheme.berry,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            _imageBytes!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Top-right controls
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _MiniIconButton(
                icon: Icons.swap_horiz,
                tooltip: 'Change image',
                onTap: () => setState(() {
                  _imageBytes = null;
                  _analysisResult = null;
                }),
              ),
            ],
          ),
        ),
        // Analyze button overlay
        if (_analysisResult == null && !_isAnalyzing)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: ElevatedButton.icon(
              onPressed: _analyzeImage,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Analyze with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.avocado,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.avocado.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40,
                color: AppTheme.avocado,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Analyzing your food...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.avocado,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is identifying nutrients',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.avocado,
              backgroundColor: AppTheme.avocado.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final pct = (_confidence * 100).toInt();
    final color = pct >= 80
        ? Colors.green
        : pct >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            'AI Confidence: $pct%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness * 0.6).clamp(0.0, 1.0)).toColor(),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_servingSize.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _servingSize,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutrientCards() {
    return Row(
      children: [
        _NutrientCard(
          label: 'Calories',
          value: _caloriesController.text,
          unit: 'kcal',
          color: Colors.orange,
          icon: Icons.local_fire_department,
        ),
        const SizedBox(width: 8),
        _NutrientCard(
          label: 'Protein',
          value: _proteinController.text,
          unit: 'g',
          color: Colors.green,
          icon: Icons.egg_alt,
        ),
        const SizedBox(width: 8),
        _NutrientCard(
          label: 'Carbs',
          value: _carbsController.text,
          unit: 'g',
          color: Colors.blue,
          icon: Icons.grain,
        ),
        const SizedBox(width: 8),
        _NutrientCard(
          label: 'Fats',
          value: _fatsController.text,
          unit: 'g',
          color: Colors.pink,
          icon: Icons.water_drop,
        ),
      ],
    );
  }

  Widget _buildEditableForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, size: 20, color: AppTheme.avocado),
                const SizedBox(width: 6),
                const Text(
                  'Edit Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.avocado,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _foodNameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealType,
              items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _mealType = v ?? 'Lunch'),
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      suffixText: 'kcal',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fatsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fats',
                      suffixText: 'g',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fiberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fiber',
                suffixText: 'g',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _saveResult,
      icon: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(_isSaving ? 'Saving...' : 'Save Meal'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.avocado,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
    );
  }
}

// ─── Reusable Child Widgets ───

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _NutrientCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _NutrientCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

