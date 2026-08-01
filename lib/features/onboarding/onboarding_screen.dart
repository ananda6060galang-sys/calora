import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../models/user_profile.dart';
import '../dashboard/providers/profile_provider.dart';
import '../../routing/root_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;
  static const totalSteps = 4;

  Gender _gender = Gender.male;
  double _age = 24;
  double _heightCm = 174;
  double _weightKg = 71;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal? _goal;

  void _next() {
    if (_step == totalSteps - 1) {
      final profile = UserProfile(
        name: 'Alex Pratama',
        age: _age.round(),
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        activityLevel: _activity,
        goal: _goal ?? Goal.maintainWeight,
      );
      ref.read(userProfileProvider.notifier).state = profile;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
      return;
    }
    setState(() => _step++);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _step != 3 || _goal != null;

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
              Row(
                children: List.generate(totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(
                          right: i == totalSteps - 1 ? 0 : AppSpacing.sm),
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
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _basicsStep(),
                    _measurementsStep(),
                    _activityStep(),
                    _goalStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: AppButton(
                  label: _step == totalSteps - 1 ? 'Finish Setup' : 'Continue',
                  onPressed: canProceed ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _basicsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Tell us about you', 'This helps us personalize your targets.'),
          Text('Gender', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _choiceChip('Male', _gender == Gender.male,
                  () => setState(() => _gender = Gender.male)),
              const SizedBox(width: AppSpacing.sm),
              _choiceChip('Female', _gender == Gender.female,
                  () => setState(() => _gender = Gender.female)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _sliderField('Age', _age, 14, 80, 'yrs', (v) => setState(() => _age = v)),
        ],
      ),
    );
  }

  Widget _measurementsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Your measurements', 'Used to calculate your calorie needs.'),
          _sliderField('Height', _heightCm, 130, 220, 'cm',
              (v) => setState(() => _heightCm = v)),
          const SizedBox(height: AppSpacing.xl),
          _sliderField('Weight', _weightKg, 35, 160, 'kg',
              (v) => setState(() => _weightKg = v)),
        ],
      ),
    );
  }

  Widget _activityStep() {
    final labels = {
      ActivityLevel.sedentary: ('Sedentary', 'Little to no exercise'),
      ActivityLevel.light: ('Lightly active', '1–3 workouts / week'),
      ActivityLevel.moderate: ('Moderately active', '3–5 workouts / week'),
      ActivityLevel.active: ('Active', '6–7 workouts / week'),
      ActivityLevel.veryActive: ('Very active', 'Daily intense training'),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Activity level', 'How much do you move on a typical week?'),
          ...labels.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _optionTile(
                  title: e.value.$1,
                  subtitle: e.value.$2,
                  selected: _activity == e.key,
                  onTap: () => setState(() => _activity = e.key),
                ),
              )),
        ],
      ),
    );
  }

  Widget _goalStep() {
    final labels = {
      Goal.loseWeight: ('Lose weight', 'Calorie deficit for fat loss'),
      Goal.maintainWeight: ('Maintain weight', 'Stay around your current weight'),
      Goal.gainMuscle: ('Gain muscle', 'Modest surplus to build lean mass'),
      Goal.leanBulk: ('Lean bulk', 'Slightly higher surplus, faster gains'),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('What\'s your goal?', 'We\'ll tailor your daily targets around this.'),
          ...labels.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _optionTile(
                  title: e.value.$1,
                  subtitle: e.value.$2,
                  selected: _goal == e.key,
                  onTap: () => setState(() => _goal = e.key),
                ),
              )),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.16)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }

  Widget _sliderField(String label, double value, double min, double max,
      String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(width: 8),
            Text('${value.round()} $unit',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.accent)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            inactiveTrackColor: Theme.of(context).dividerColor,
            overlayColor: AppColors.accent.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
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
          ? AppColors.accent.withValues(alpha: 0.14)
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
              color: selected ? AppColors.accent : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
