import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../models/user_profile.dart';
import '../auth/providers/auth_provider.dart';
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
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  int _step = 0;
  static const _totalSteps = 5;

  // Step data - initially empty / unselected
  DateTime? _dateOfBirth;
  Gender? _gender;
  ActivityLevel? _activity;
  Goal? _goal;
  GoalPace _goalPace = GoalPace.moderate;
  bool _savingProfile = false;

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty && _gender != null;
      case 1:
        return _dateOfBirth != null;
      case 2:
        final h = double.tryParse(_heightController.text.trim());
        final w = double.tryParse(_weightController.text.trim());
        return h != null && h > 0 && w != null && w > 0;
      case 3:
        return _activity != null;
      case 4:
        if (_goal == null) return false;
        if (_goal != Goal.maintainWeight) {
          final twText = _targetWeightController.text.trim();
          if (twText.isNotEmpty) {
            final tw = double.tryParse(twText);
            if (tw == null || tw <= 0) return false;
          }
        }
        return true;
      default:
        return false;
    }
  }

  void _next() async {
    if (!_canProceed) return;

    if (_step == _totalSteps - 1) {
      if (_savingProfile) return;

      setState(() => _savingProfile = true);

      final dob = _dateOfBirth!;
      final height = double.parse(_heightController.text.trim());
      final weight = double.parse(_weightController.text.trim());
      final gender = _gender!;
      final activity = _activity!;
      final goal = _goal!;
      double? targetWeight;
      if (goal != Goal.maintainWeight &&
          _targetWeightController.text.trim().isNotEmpty) {
        targetWeight = double.tryParse(_targetWeightController.text.trim());
      }

      final profile = UserProfile(
        name: _nameController.text.trim(),
        dateOfBirth: dob,
        gender: gender,
        heightCm: height,
        weightKg: weight,
        activityLevel: activity,
        goal: goal,
        targetWeightKg: targetWeight,
        goalPace: _goalPace,
      );
      ref.read(userProfileProvider.notifier).state = profile;

      // Save profile data to Supabase profiles table if authenticated
      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser != null) {
        try {
          await ref
              .read(profileServiceProvider)
              .saveProfile(
                userId: currentUser.id,
                profile: profile,
                dateOfBirth: dob,
              );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving profile: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _savingProfile = false);

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
    _nameController.text = '';
    _heightController.text = '';
    _weightController.text = '';
    _targetWeightController.text = '';
    _dateOfBirth = null;
    _gender = null;
    _activity = null;
    _goal = null;
    _goalPace = GoalPace.moderate;
    _nameController.addListener(() => setState(() {}));
    _heightController.addListener(() => setState(() {}));
    _weightController.addListener(() => setState(() {}));
    _targetWeightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
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
                  label: _step == _totalSteps - 1
                      ? 'onboarding.seeMyPlan'.tr()
                      : 'onboarding.continue'.tr(),
                  onPressed: (_canProceed && !_savingProfile) ? _next : null,
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
            decoration: InputDecoration(
              hintText: 'onboarding.fullNameHint'.tr(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _genderCard(
                'onboarding.male'.tr(),
                Icons.male_rounded,
                Gender.male,
              ),
              const SizedBox(width: AppSpacing.sm),
              _genderCard(
                'onboarding.female'.tr(),
                Icons.female_rounded,
                Gender.female,
              ),
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
                initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.accent,
                        onPrimary: const Color(0xFF0F1410),
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
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.lightSurfaceAlt,
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
                    _dateOfBirth != null
                        ? DateFormat('MMMM d, y').format(_dateOfBirth!)
                        : 'onboarding.selectDate'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _dateOfBirth == null
                              ? (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary)
                              : null,
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
        ? AppColors.fat
        : const Color(0xFFFF8DA1);

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
              Icon(icon, size: 28, color: iconColor),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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

  // ─── Step 4: Activity Level ─────────────────────────────────

  Widget _activityStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final options = const [
      _ActivityOptionData(
        level: ActivityLevel.sedentary,
        imagePath: 'assets/sedentary.png',
        titleKey: 'onboarding.activity.sedentary.title',
        subtitleKey: 'onboarding.activity.sedentary.subtitle',
      ),
      _ActivityOptionData(
        level: ActivityLevel.light,
        imagePath: 'assets/light.png',
        titleKey: 'onboarding.activity.light.title',
        subtitleKey: 'onboarding.activity.light.subtitle',
      ),
      _ActivityOptionData(
        level: ActivityLevel.moderate,
        imagePath: 'assets/moderately.png',
        titleKey: 'onboarding.activity.moderate.title',
        subtitleKey: 'onboarding.activity.moderate.subtitle',
      ),
      _ActivityOptionData(
        level: ActivityLevel.active,
        imagePath: 'assets/active.png',
        titleKey: 'onboarding.activity.active.title',
        subtitleKey: 'onboarding.activity.active.subtitle',
      ),
      _ActivityOptionData(
        level: ActivityLevel.veryActive,
        imagePath: 'assets/vactive.png',
        titleKey: 'onboarding.activity.veryActive.title',
        subtitleKey: 'onboarding.activity.veryActive.subtitle',
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'onboarding.activityTitle'.tr(),
            'onboarding.activitySubtitle'.tr(),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...options.map((opt) {
            final selected = _activity == opt.level;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _activityOptionTile(
                imagePath: opt.imagePath,
                title: opt.titleKey.tr(),
                subtitle: opt.subtitleKey.tr(),
                selected: selected,
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

  // ─── Step 5: Goal ───────────────────────────────────────────

  Widget _goalStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = {
      Goal.loseWeight: (
        'dashboard.goals.loseWeight'.tr(),
        'onboarding.goals.loseWeightSub'.tr(),
      ),
      Goal.maintainWeight: (
        'dashboard.goals.maintainWeight'.tr(),
        'onboarding.goals.maintainWeightSub'.tr(),
      ),
      Goal.gainWeight: (
        'dashboard.goals.gainWeight'.tr(),
        'onboarding.goals.gainWeightSub'.tr(),
      ),
    };

    final currentWeight = double.tryParse(_weightController.text.trim());
    final currentTargetWeight =
        double.tryParse(_targetWeightController.text.trim());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "onboarding.goalTitle".tr(),
            "onboarding.goalSubtitle".tr(),
          ),
          Center(
            child: Image.asset(
              'assets/onboarding4.png',
              height: 220,
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

          // Target Weight & Pace (only for Lose Weight or Gain Weight)
          if (_goal != null && _goal != Goal.maintainWeight) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'onboarding.targetWeightLabel'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _targetWeightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'onboarding.targetWeightHint'.tr(),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
              ),
            ),
            if (currentWeight != null &&
                currentWeight > 0 &&
                currentTargetWeight != null &&
                currentTargetWeight > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'onboarding.targetDifference'.tr(args: [
                    (currentTargetWeight - currentWeight) > 0
                        ? '+${(currentTargetWeight - currentWeight).toStringAsFixed(1)}'
                        : (currentTargetWeight - currentWeight)
                            .toStringAsFixed(1),
                  ]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'onboarding.preferredPace'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...GoalPace.values.map((pace) {
              final isSelected = _goalPace == pace;
              final paceTitle = pace == GoalPace.gentle
                  ? 'onboarding.paces.gentle'.tr()
                  : pace == GoalPace.moderate
                      ? 'onboarding.paces.moderate'.tr()
                      : 'onboarding.paces.faster'.tr();
              final paceSub = pace == GoalPace.gentle
                  ? 'onboarding.paces.gentleSub'.tr()
                  : pace == GoalPace.moderate
                      ? 'onboarding.paces.moderateSub'.tr()
                      : 'onboarding.paces.fasterSub'.tr();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () => setState(() => _goalPace = pace),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : (isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    paceTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (pace == GoalPace.moderate) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'onboarding.paces.recommendedBadge'
                                            .tr(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F1410),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                paceSub,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppColors.accent
                              : Theme.of(context).dividerColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.lightSurfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'onboarding.paceEstimateNote'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Shared Option Tiles ────────────────────────────────────

  Widget _activityOptionTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : (isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          children: [
            SizedBox(
              width: 125,
              height: 90,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.accent
                      : (isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFCCCCCC)),
                  width: selected ? 0 : 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check, size: 15, color: Color(0xFF111111))
                  : null,
            ),
          ],
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
              color: selected
                  ? AppColors.accent
                  : Theme.of(context).dividerColor,
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
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accent,
                  size: 22,
                )
              else
                Icon(
                  Icons.circle_rounded,
                  color: Theme.of(context).dividerColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityOptionData {
  final ActivityLevel level;
  final String imagePath;
  final String titleKey;
  final String subtitleKey;

  const _ActivityOptionData({
    required this.level,
    required this.imagePath,
    required this.titleKey,
    required this.subtitleKey,
  });
}
