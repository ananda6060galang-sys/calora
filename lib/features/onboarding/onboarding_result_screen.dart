import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../models/user_profile.dart';
import '../../routing/root_shell.dart';
import 'onboarding_screen.dart';

/// Post-onboarding summary showing the user's computed daily targets.
class OnboardingResultScreen extends StatelessWidget {
  const OnboardingResultScreen({super.key, required this.profile});

  final UserProfile profile;

  String get _firstName => profile.name.split(' ').first;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ─── Heading ────────────────────────────────────
              Text(
                'onboarding.youreAllSet'.tr(args: [_firstName]),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'onboarding.personalizedPlan'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Illustration (supporting, not the focal point) ──
              Image.asset(
                'assets/onboarding5.webp',
                width: double.infinity,
                height: 150,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Calorie Target Hero (the one focal point) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'onboarding.dailyCalories'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${profile.dailyCalorieTarget.round()}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                    Text('kcal', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Macro Targets Row ──────────────────────────
              Row(
                children: [
                  _macroCard(
                    context,
                    label: 'dashboard.protein'.tr(),
                    grams: profile.proteinTargetG,
                    color: AppColors.protein,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _macroCard(
                    context,
                    label: 'dashboard.carbs'.tr(),
                    grams: profile.carbsTargetG,
                    color: AppColors.carbs,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _macroCard(
                    context,
                    label: 'dashboard.fat'.tr(),
                    grams: profile.fatTargetG,
                    color: AppColors.fat,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Where the baselines & roadmap live ─────────
              // BMR, TDEE and the goal timeline have a permanent home in
              // Goals & Nutrition; pointing there keeps this screen a single
              // "you're ready" moment instead of a reference dump.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 15,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'onboarding.baselinesHint'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.section),

              // ─── Disclaimer ─────────────────────────────────
              Text(
                'onboarding.disclaimer'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── CTA ────────────────────────────────────────
              AppButton(
                label: 'onboarding.getStarted'.tr(),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                child: Text(
                  'onboarding.restartGuide'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroCard(
    BuildContext context, {
    required String label,
    required double grams,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${grams.round()}g',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
