import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 – body metrics
  final _step1Key = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();

  // Step 2 – physical profile
  String _gender = 'male';
  String _activityLevel = 'moderate';

  // Step 3 – goal
  String _goalType = 'recomp';
  int _aggressiveness = 2;

  @override
  void dispose() {
    _pageController.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _bodyFatCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_currentPage == 0 && !_step1Key.currentState!.validate()) return;
    if (_currentPage < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      await _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _finish() async {
    final weightKg = double.tryParse(_weightCtrl.text.trim());
    final heightCm = double.tryParse(_heightCtrl.text.trim());
    final age = int.tryParse(_ageCtrl.text.trim());
    final bodyFatRaw = _bodyFatCtrl.text.trim();
    final bodyFatPercent = bodyFatRaw.isEmpty
        ? null
        : double.tryParse(bodyFatRaw);

    if (weightKg == null ||
        heightCm == null ||
        age == null ||
        (bodyFatRaw.isNotEmpty && bodyFatPercent == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid profile values before continuing.'),
        ),
      );
      return;
    }

    final profile = UserProfile(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      bodyFatPercent: bodyFatPercent,
      gender: _gender,
      activityLevel: _activityLevel,
      goalType: _goalType,
      aggressiveness: _aggressiveness,
    );

    try {
      await context.read<ProfileService>().saveProfile(profile);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save your profile: ${_friendlyError(e)}'),
        ),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException')) {
      return 'cannot reach backend. Make sure server is running.';
    }
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
            _buildNavButtons(profileService.isLoading),
          ],
        ),
      ),
    );
  }

  // ── Progress bar ────────────────────────────────────────────────────────────

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _currentPage
                        ? const Color(0xFF3D5A40)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentPage + 1} of 3',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Navigation buttons ─────────────────────────────────────────────────────

  Widget _buildNavButtons(bool loading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: loading ? null : _next,
              child: Text(_currentPage == 2 ? 'Get Started 🚀' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Body Metrics ────────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Let's get to know you",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Your body metrics help us calculate personalised nutrition targets.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _numField(
                    _weightCtrl,
                    'Weight (kg)',
                    minValue: 20,
                    maxValue: 300,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numField(
                    _heightCtrl,
                    'Height (cm)',
                    minValue: 100,
                    maxValue: 250,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numField(
                    _ageCtrl,
                    'Age',
                    integer: true,
                    minValue: 12,
                    maxValue: 100,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numField(
                    _bodyFatCtrl,
                    'Body fat % (opt)',
                    optional: true,
                    minValue: 3,
                    maxValue: 60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Gender + Activity ───────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'About you',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Helps us estimate your metabolic rate accurately.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderCard('male', Icons.male, 'Male'),
              const SizedBox(width: 12),
              _genderCard('female', Icons.female, 'Female'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Activity Level',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _activityOption('sedentary', 'Sedentary', '< 1 session/week'),
          _activityOption('light', 'Light', '1–3 sessions/week'),
          _activityOption('moderate', 'Moderate', '3–5 sessions/week'),
          _activityOption('very_active', 'Very Active', '6–7 sessions/week'),
          _activityOption('athlete', 'Athlete', '2× trainings/day'),
        ],
      ),
    );
  }

  // ── Step 3: Goal ────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    final showAgg = _goalType == 'fat_loss' || _goalType == 'muscle_gain';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            "What's your goal?",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll calculate your daily calorie and macro targets.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          _goalCard(
            'fat_loss',
            '🔥',
            'Fat Loss',
            'Calorie deficit to burn fat',
          ),
          const SizedBox(height: 10),
          _goalCard(
            'recomp',
            '🔄',
            'Recomposition',
            'Lose fat while preserving muscle',
          ),
          const SizedBox(height: 10),
          _goalCard(
            'muscle_gain',
            '💪',
            'Muscle Gain',
            'Calorie surplus to build muscle',
          ),
          const SizedBox(height: 10),
          _goalCard(
            'maintenance',
            '⚖️',
            'Maintenance',
            'Maintain current weight',
          ),
          if (showAgg) ...[
            const SizedBox(height: 20),
            const Text(
              'How aggressive?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
        ],
      ),
    );
  }

  // ── Reusable helper widgets ─────────────────────────────────────────────────

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    bool optional = false,
    bool integer = false,
    double? minValue,
    double? maxValue,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: integer
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final raw = v?.trim() ?? '';
        if (optional && raw.isEmpty) return null;
        if (raw.isEmpty) return 'Required';

        final numValue = integer
            ? int.tryParse(raw)?.toDouble()
            : double.tryParse(raw);
        if (numValue == null) {
          return integer ? 'Enter a whole number' : 'Invalid';
        }
        if (minValue != null && numValue < minValue) {
          return 'Min ${minValue.toStringAsFixed(minValue % 1 == 0 ? 0 : 1)}';
        }
        if (maxValue != null && numValue > maxValue) {
          return 'Max ${maxValue.toStringAsFixed(maxValue % 1 == 0 ? 0 : 1)}';
        }
        return null;
      },
    );
  }

  Widget _genderCard(String value, IconData icon, String label) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A40) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF3D5A40) : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade600,
                size: 30,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityOption(String value, String label, String subtitle) {
    final selected = _activityLevel == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _activityLevel = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3D5A40).withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF3D5A40) : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF3D5A40),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalCard(String value, String emoji, String label, String subtitle) {
    final selected = _goalType == value;
    return GestureDetector(
      onTap: () => setState(() => _goalType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3D5A40).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF3D5A40) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF3D5A40),
                size: 20,
              ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A40) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF3D5A40) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
