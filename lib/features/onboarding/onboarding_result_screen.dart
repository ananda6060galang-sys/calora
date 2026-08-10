import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../models/user_profile.dart';
import '../../routing/root_shell.dart';

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
              const SizedBox(height: AppSpacing.xxxl),

              // ─── Celebration Icon ───────────────────────────
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 30,
                  color: Color(0xFF0E0F10),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Heading ────────────────────────────────────
              Text(
                "You're all set, $_firstName!",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Here's your personalized daily plan.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.section),

              // ─── Calorie Target Hero ────────────────────────
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
                      'Daily Calories',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${profile.dailyCalorieTarget.round()}',
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                    ),
                    Text(
                      'kcal',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Macro Targets Row ──────────────────────────
              Row(
                children: [
                  _macroCard(
                    context,
                    label: 'Protein',
                    grams: profile.proteinTargetG,
                    color: AppColors.protein,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _macroCard(
                    context,
                    label: 'Carbs',
                    grams: profile.carbsTargetG,
                    color: AppColors.carbs,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _macroCard(
                    context,
                    label: 'Fat',
                    grams: profile.fatTargetG,
                    color: AppColors.fat,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.section),

              // ─── Disclaimer ─────────────────────────────────
              Text(
                'These targets are calculated using the Mifflin-St Jeor equation based on your profile. They are for reference only, not medical advice.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── CTA ────────────────────────────────────────
              AppButton(
                label: 'Get Started',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RootShell()),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),
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
