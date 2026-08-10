import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/widgets/app_button.dart';
import '../../models/user_profile.dart';
import '../dashboard/providers/profile_provider.dart';
import 'onboarding_result_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '65');
  int _step = 0;
  static const _totalSteps = 5;

  // Step data
  DateTime? _dateOfBirth;
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal? _goal;

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _dateOfBirth != null;
      case 2:
        return double.tryParse(_heightController.text.trim()) != null &&
               double.tryParse(_weightController.text.trim()) != null;
      case 4:
        return _goal != null;
      default:
        return true;
    }
  }

  void _next() {
    if (_step == _totalSteps - 1) {
      final age = calculateAge(_dateOfBirth!);
      final profile = UserProfile(
        name: _nameController.text.trim(),
        age: age,
        gender: _gender,
        heightCm: double.tryParse(_heightController.text.trim()) ?? 170.0,
        weightKg: double.tryParse(_weightController.text.trim()) ?? 65.0,
        activityLevel: _activity,
        goal: _goal!,
      );
      ref.read(userProfileProvider.notifier).state = profile;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingResultScreen(profile: profile),
        ),
      );
      return;
    }
    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: i == _totalSteps - 1 ? 0 : AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? AppColors.accent
                            : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _nameAndGenderStep(),
                    _dobStep(),
                    _heightAndWeightStep(),
                    _activityStep(),
                    _goalStep(),
                  ],
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: AppButton(
                  label: _step == _totalSteps - 1 ? 'See my plan' : 'Continue',
                  onPressed: _canProceed ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared ─────────────────────────────────────────────────

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ─── Step 1: Name & Gender ──────────────────────────────────

  Widget _nameAndGenderStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Personal Information",
            "Please provide your name and gender to personalize your experience.",
          ),
          Center(
            child: Image.asset(
              'assets/onboarding.png',
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(hintText: 'Full name'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _genderCard('Male', //ganti warna biru 
              Icons.male_rounded, Gender.male),
              const SizedBox(width: AppSpacing.sm),
              _genderCard('Female', Icons.female_rounded, Gender.female),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ─── Step 2: Date of Birth ──────────────────────────────────

  Widget _dobStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDate = _dateOfBirth != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Date of Birth',
            'This information is used to calculate your daily nutritional targets.',
          ),
          Center(
            child: Image.asset(
              'assets/onboarding2.png',
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(1940),
                lastDate: DateTime.now().subtract(const Duration(days: 3650)),
                initialDate: _dateOfBirth ?? DateTime(2002, 1, 1),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.accent,
                            onPrimary: const Color(0xFF0E0F10),
                          ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    hasDate
                        ? DateFormat('MMMM d, y').format(_dateOfBirth!)
                        : 'Select date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: hasDate
                              ? null
                              : (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Gender Card ─────────────────────────────────────

  Widget _genderCard(String label, IconData icon, Gender gender) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _gender == gender;
    final iconColor = gender == Gender.male
        ? AppColors.fat // Soft Blue
        : const Color(0xFFFF8DA1); // Soft Pink

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected
                          ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 3: Height & Weight ────────────────────────────────

  Widget _heightAndWeightStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Body Metrics',
            'Please enter your height and weight to establish your baseline.',
          ),
          Center(
            child: Image.asset(
              'assets/onboarding3.png',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    suffixText: 'kg',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ─── Step 6: Activity Level ─────────────────────────────────

  Widget _activityStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('How active are you?', 'On a typical week.'),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _imageOptionTile(
              imagePath: 'assets/sedentary.png',
              selected: _activity == ActivityLevel.sedentary,
              onTap: () => setState(() => _activity = ActivityLevel.sedentary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _imageOptionTile(
              imagePath: 'assets/light.png',
              selected: _activity == ActivityLevel.light,
              onTap: () => setState(() => _activity = ActivityLevel.light),
              gradientColors: const [AppColors.carbs, Color(0xFFFFD579)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _imageOptionTile(
              imagePath: 'assets/moderate.png',
              selected: _activity == ActivityLevel.moderate,
              onTap: () => setState(() => _activity = ActivityLevel.moderate),
              gradientColors: const [AppColors.fat, Color(0xFFB3D4FF)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _imageOptionTile(
              imagePath: 'assets/active.png',
              selected: _activity == ActivityLevel.active,
              onTap: () => setState(() => _activity = ActivityLevel.active),
              gradientColors: const [AppColors.protein, AppColors.danger],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _imageOptionTile(
              imagePath: 'assets/vactive.png',
              selected: _activity == ActivityLevel.veryActive,
              onTap: () => setState(() => _activity = ActivityLevel.veryActive),
              gradientColors: const [
                Color(0xFF00E5FF), // Cyan/Turquoise
                AppColors.fat,     // Soft Blue
                AppColors.lavender,// Soft Purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 7: Goal ───────────────────────────────────────────

  Widget _goalStep() {
    const labels = {
      Goal.loseWeight: ('Lose weight', 'Calorie deficit for fat loss'),
      Goal.maintainWeight: ('Maintain weight', 'Stay at your current weight'),
      Goal.gainMuscle: ('Gain muscle', 'Modest surplus for lean mass'),
      Goal.leanBulk: ('Lean bulk', 'Higher surplus, faster gains'),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("What's your goal?", "We'll tailor your daily targets."),
          Center(
            child: Image.asset(
              'assets/onboarding4.png',
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...labels.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _optionTile(
                title: e.value.$1,
                subtitle: e.value.$2,
                selected: _goal == e.key,
                onTap: () => setState(() => _goal = e.key),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────

  Widget _imageOptionTile({
    required String imagePath,
    required bool selected,
    required VoidCallback onTap,
    List<Color>? gradientColors,
  }) {
    final colors = gradientColors ?? [AppColors.accent, AppColors.accentSoft];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(3.0), // Gradient border width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: selected
              ? LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.xl - 3.0),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl - 3.0),
            gradient: selected
                ? LinearGradient(
                    colors: colors.map((c) => c.withValues(alpha: 0.2)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl - 3.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color:
                  selected ? AppColors.accent : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.accent, size: 22)
              else
                Icon(Icons.circle_outlined,
                    color: Theme.of(context).dividerColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
