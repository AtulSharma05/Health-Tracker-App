import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _bodyFatController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goalType = 'recomp';
  int _aggressiveness = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileService = context.read<ProfileService>();
      await profileService.fetchProfile();
      final profile = profileService.profile;
      if (profile == null || !mounted) return;
      setState(() {
        _weightController.text = profile.weightKg.toStringAsFixed(1);
        _heightController.text = profile.heightCm.toStringAsFixed(1);
        _ageController.text = profile.age.toString();
        _bodyFatController.text = profile.bodyFatPercent?.toStringAsFixed(1) ?? '';
        _gender = profile.gender;
        _activityLevel = profile.activityLevel;
        _goalType = profile.goalType;
        _aggressiveness = profile.aggressiveness;
      });
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      weightKg: double.parse(_weightController.text.trim()),
      heightCm: double.parse(_heightController.text.trim()),
      age: int.parse(_ageController.text.trim()),
      bodyFatPercent: _bodyFatController.text.trim().isEmpty
          ? null
          : double.parse(_bodyFatController.text.trim()),
      gender: _gender,
      activityLevel: _activityLevel,
      goalType: _goalType,
      aggressiveness: _aggressiveness,
    );

    await context.read<ProfileService>().saveProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile and nutrition targets updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final profileService = context.watch<ProfileService>();
    final calculations = profileService.calculations;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
            const SizedBox(height: 10),
            Text(auth.userEmail, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _numberField(_weightController, 'Weight (kg)')),
                      const SizedBox(width: 10),
                      Expanded(child: _numberField(_heightController, 'Height (cm)')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _numberField(_ageController, 'Age')),
                      const SizedBox(width: 10),
                      Expanded(child: _numberField(_bodyFatController, 'Body fat % (opt)')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'male'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    decoration: const InputDecoration(labelText: 'Activity level'),
                    items: const [
                      DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'very_active', child: Text('Very active')),
                      DropdownMenuItem(value: 'athlete', child: Text('Athlete')),
                    ],
                    onChanged: (v) => setState(() => _activityLevel = v ?? 'moderate'),
                  ),
                  const SizedBox(height: 10),
                  // Goal presets
                  const Text('Goal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _goalChip('maintenance', '⚖️', 'Maintain'),
                      _goalChip('recomp', '🔄', 'Recomp'),
                      _goalChip('fat_loss', '🔥', 'Fat Loss'),
                      _goalChip('muscle_gain', '💪', 'Muscle'),
                    ],
                  ),
                  if (_goalType == 'fat_loss' || _goalType == 'muscle_gain') ...[
                    const SizedBox(height: 10),
                    const Text('Aggressiveness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _aggChip(1, 'Mild'),
                        const SizedBox(width: 8),
                        _aggChip(2, 'Moderate'),
                        const SizedBox(width: 8),
                        _aggChip(3, 'Aggressive'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: profileService.isLoading ? null : _saveProfile,
                    icon: const Icon(Icons.calculate),
                    label: Text(profileService.isLoading ? 'Calculating...' : 'Save & Calculate Targets'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (calculations != null) ...[
              _buildCalculationsSection(calculations),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calculations display ────────────────────────────────────────────────────

  Widget _buildCalculationsSection(MacroCalculations c) {
    final goalColor = _goalColor(_goalType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Your Targets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (c.goalLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: goalColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.goalLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: goalColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Target calories hero tile ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: goalColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Column(
                children: [
                  Text(
                    '${c.targetCalories}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'kcal / day',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Macro tiles ───────────────────────────────────────────────────────
        Row(
          children: [
            _macroTile('Protein', '${c.proteinG}g', '${c.proteinCalories} kcal', Colors.green.shade600, Icons.fitness_center),
            const SizedBox(width: 8),
            _macroTile('Carbs', '${c.carbsG}g', '${c.carbCalories} kcal', Colors.orange.shade600, Icons.grain),
            const SizedBox(width: 8),
            _macroTile('Fats', '${c.fatsG}g', '${c.fatCalories} kcal', Colors.pink.shade400, Icons.water_drop),
          ],
        ),
        const SizedBox(height: 12),

        // ── Step-by-step breakdown (expandable) ───────────────────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: const Icon(Icons.calculate_outlined, size: 20),
            title: const Text(
              'How was this calculated?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            children: [
              _breakdownRow('Basal Metabolic Rate (BMR)', '${c.bmr} kcal', null),
              _breakdownRow('Maintenance Calories', '${c.maintenanceCalories} kcal', 'BMR × activity factor'),
              _breakdownRow('Target Calories', '${c.targetCalories} kcal', c.goalLabel),
              const Divider(height: 18),
              _breakdownRow('Protein', '${c.proteinG} g', '${c.proteinCalories} kcal'),
              _breakdownRow('Carbohydrates', '${c.carbsG} g', '${c.carbCalories} kcal'),
              _breakdownRow('Fats', '${c.fatsG} g', '${c.fatCalories} kcal'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Formulas (expandable) ─────────────────────────────────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: const Icon(Icons.science_outlined, size: 20),
            title: const Text(
              'Science & Formulas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            children: c.formulas.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.fromLTRB(0, 6, 8, 0),
                      decoration: BoxDecoration(
                        color: goalColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _macroTile(String label, String amount, String kcal, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              amount,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              kcal,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, String? sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                if (sub != null && sub.isNotEmpty)
                  Text(sub,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _goalColor(String goalType) {
    switch (goalType) {
      case 'fat_loss':    return Colors.orange.shade600;
      case 'muscle_gain': return Colors.blue.shade600;
      case 'maintenance': return const Color(0xFF3D5A40);
      default:            return Colors.purple.shade500; // recomp
    }
  }

  Widget _goalChip(String value, String emoji, String label) {
    final selected = _goalType == value;
    return GestureDetector(
      onTap: () => setState(() => _goalType = value),
      child: Chip(
        backgroundColor: selected ? const Color(0xFF3D5A40) : null,
        label: Text(
          '$emoji $label',
          style: TextStyle(color: selected ? Colors.white : null, fontSize: 13),
        ),
      ),
    );
  }

  Widget _aggChip(int value, String label) {
    final selected = _aggressiveness == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _aggressiveness = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A40) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF3D5A40) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final raw = value?.trim() ?? '';
        if (label.contains('opt') && raw.isEmpty) return null;
        if (raw.isEmpty) return 'Required';
        if (double.tryParse(raw) == null) return 'Invalid number';
        return null;
      },
    );
  }
}
