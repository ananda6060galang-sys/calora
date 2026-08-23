import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  DateTime _dateOfBirth = DateTime(2000, 1, 1);
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal _goal = Goal.maintainWeight;

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return double.tryParse(_heightController.text.trim()) != null &&
               double.tryParse(_weightController.text.trim()) != null;
      default:
        return true;
    }
  }

  void _next() {
    if (_step == _totalSteps - 1) {
      final age = calculateAge(_dateOfBirth);
      final profile = UserProfile(
        name: _nameController.text.trim().isEmpty ? 'onboarding.defaultUser'.tr() : _nameController.text.trim(),
        age: age,
        gender: _gender,
        heightCm: double.tryParse(_heightController.text.trim()) ?? 170.0,
        weightKg: double.tryParse(_weightController.text.trim()) ?? 65.0,
        activityLevel: _activity,
        goal: _goal,
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
                  label: _step == _totalSteps - 1 ? 'onboarding.seeMyPlan'.tr() : 'onboarding.continue'.tr(),
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
            "onboarding.personalInfoTitle".tr(),
            "onboarding.personalInfoSubtitle".tr(),
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
            decoration: InputDecoration(hintText: 'onboarding.fullNameHint'.tr()),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _genderCard('onboarding.male'.tr(),
              Icons.male_rounded, Gender.male),
              const SizedBox(width: AppSpacing.sm),
              _genderCard('onboarding.female'.tr(), Icons.female_rounded, Gender.female),
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'onboarding.dobTitle'.tr(),
            'onboarding.dobSubtitle'.tr(),
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
                initialDate: _dateOfBirth,
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
                    DateFormat('MMMM d, y').format(_dateOfBirth),
                    style: Theme.of(context).textTheme.bodyLarge,
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
            'onboarding.bodyMetricsTitle'.tr(),
            'onboarding.bodyMetricsSubtitle'.tr(),
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
                  decoration: InputDecoration(
                    labelText: 'onboarding.heightLabel'.tr(),
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
                  decoration: InputDecoration(
                    labelText: 'onboarding.weightLabel'.tr(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final options = const [
      _ActivityOptionData(
        level: ActivityLevel.sedentary,
        icon: Icons.weekend_rounded,
        titleKey: 'onboarding.activity.sedentary.title',
        subtitleKey: 'onboarding.activity.sedentary.subtitle',
        gradientColors: [Color(0xFF64748B), Color(0xFF475569)],
      ),
      _ActivityOptionData(
        level: ActivityLevel.light,
        icon: Icons.directions_walk_rounded,
        titleKey: 'onboarding.activity.light.title',
        subtitleKey: 'onboarding.activity.light.subtitle',
        gradientColors: [AppColors.carbs, Color(0xFFFFD579)],
      ),
      _ActivityOptionData(
        level: ActivityLevel.moderate,
        icon: Icons.directions_run_rounded,
        titleKey: 'onboarding.activity.moderate.title',
        subtitleKey: 'onboarding.activity.moderate.subtitle',
        gradientColors: [AppColors.fat, Color(0xFFB3D4FF)],
      ),
      _ActivityOptionData(
        level: ActivityLevel.active,
        icon: Icons.fitness_center_rounded,
        titleKey: 'onboarding.activity.active.title',
        subtitleKey: 'onboarding.activity.active.subtitle',
        gradientColors: [AppColors.protein, AppColors.danger],
      ),
      _ActivityOptionData(
        level: ActivityLevel.veryActive,
        icon: Icons.local_fire_department_rounded,
        titleKey: 'onboarding.activity.veryActive.title',
        subtitleKey: 'onboarding.activity.veryActive.subtitle',
        gradientColors: [
          Color(0xFF00E5FF),
          AppColors.fat,
          AppColors.lavender,
        ],
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('onboarding.activityTitle'.tr(), 'onboarding.activitySubtitle'.tr()),
          const SizedBox(height: AppSpacing.sm),
          ...options.map((opt) {
            final selected = _activity == opt.level;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _activityOptionTile(
                icon: opt.icon,
                title: opt.titleKey.tr(),
                subtitle: opt.subtitleKey.tr(),
                selected: selected,
                gradientColors: opt.gradientColors,
                onTap: () => setState(() => _activity = opt.level),
                isDark: isDark,
                textSecondary: textSecondary,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 7: Goal ───────────────────────────────────────────

  Widget _goalStep() {
    final labels = {
      Goal.loseWeight: ('dashboard.goals.loseWeight'.tr(), 'onboarding.goals.loseWeightSub'.tr()),
      Goal.maintainWeight: ('dashboard.goals.maintainWeight'.tr(), 'onboarding.goals.maintainWeightSub'.tr()),
      Goal.gainMuscle: ('dashboard.goals.gainMuscle'.tr(), 'onboarding.goals.gainMuscleSub'.tr()),
      Goal.leanBulk: ('dashboard.goals.leanBulk'.tr(), 'onboarding.goals.leanBulkSub'.tr()),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("onboarding.goalTitle".tr(), "onboarding.goalSubtitle".tr()),
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

  Widget _activityOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isDark,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: selected
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl - 3.0),
            border: selected
                ? null
                : Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.0,
                  ),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl - 3.0),
            gradient: selected
                ? LinearGradient(
                    colors: gradientColors.map((c) => c.withValues(alpha: 0.12)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
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
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.accent
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: selected ? 0 : 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Color(0xFF0E0F10),
                        )
                      : null,
                ),
              ],
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
                Icon(Icons.circle_rounded,
                    color: Theme.of(context).dividerColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityOptionData {
  final ActivityLevel level;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final List<Color> gradientColors;

  const _ActivityOptionData({
    required this.level,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.gradientColors,
  });
}
