import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/input_validators.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import '../onboarding/onboarding_screen.dart';
import 'providers/weight_log_provider.dart';
import 'widgets/weight_journey_chart.dart';

/// CALORA — GOALS & NUTRITION SCREEN
///
/// Editorial, calm personal nutrition plan & progress overview screen.
/// - Overview First: Shows active plan, weight progress, and daily nutrition targets clearly.
/// - Honest Progress: Weight history strictly reflects actual recorded logs (with clean empty state).
/// - High Contrast: Strictly adheres to Calora design tokens and dark-text-on-accent rules.
/// - Actionable: Non-intrusive modal bottom sheets for "Adjust Plan" and "Log Weight".
class GoalsAndNutritionScreen extends ConsumerWidget {
  const GoalsAndNutritionScreen({super.key});

  String _goalLabel(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'dashboard.goals.loseWeight'.tr();
      case Goal.maintainWeight:
        return 'dashboard.goals.maintainWeight'.tr();
      case Goal.gainWeight:
        return 'dashboard.goals.gainWeight'.tr();
    }
  }

  String _paceLabel(GoalPace pace) {
    switch (pace) {
      case GoalPace.gentle:
        return '${'onboarding.paces.gentle'.tr()} · ±0.25 kg';
      case GoalPace.moderate:
        return '${'onboarding.paces.moderate'.tr()} · ±0.5 kg';
      case GoalPace.faster:
        return '${'onboarding.paces.faster'.tr()} · ±0.75 kg';
    }
  }

  void _openAdjustPlanSheet(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AdjustPlanSheet(profile: profile),
    );
  }

  void _openLogWeightSheet(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LogWeightSheet(profile: profile),
    );
  }

  void _confirmRestartSetup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'profile.confirmResetTitle'.tr(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'profile.confirmResetMessage'.tr(),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'profile.cancel'.tr(),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.accent : const Color(0xFF1B3D22),
              foregroundColor: isDark ? const Color(0xFF0F1410) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'profile.continueAction'.tr(),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLog(
      BuildContext context, WidgetRef ref, WeightLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'profile.deleteWeightConfirmTitle'.tr(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'profile.deleteWeightConfirmMessage'.tr(args: [
            log.weightKg.toStringAsFixed(1),
            DateFormat('d MMMM yyyy').format(log.loggedDate),
          ]),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'profile.cancel'.tr(),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(weightLogProvider.notifier).deleteWeightLog(log.id);
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('profile.weightDeletedSuccess'.tr()),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'profile.delete'.tr(),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final weightLogs = ref.watch(weightLogProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    final plan = NutritionCalculator.calculateGoalRoadmap(profile);
    final isCustom = profile.isCustomTarget;

    // Weight calculations
    final startWeight =
        weightLogs.isNotEmpty ? weightLogs.first.weightKg : profile.weightKg;
    final currentWeight = profile.weightKg;
    final targetWeight = profile.targetWeightKg ?? profile.weightKg;
    final remainingDelta = (targetWeight - currentWeight).abs();
    final isGoalReached = remainingDelta < 0.2;

    // Progress percentage
    final totalDelta = (targetWeight - startWeight).abs();
    final progress = totalDelta > 0.05
        ? ((startWeight - currentWeight).abs() / totalDelta).clamp(0.0, 1.0)
        : 1.0;

    // Daily Calorie & Macro calculations
    final calculatedCalories = profile.dailyCalorieTarget.round();
    final bmr = profile.bmr.round();
    final tdee = profile.tdee.round();
    final isBmrClamped =
        calculatedCalories <= bmr && profile.goal == Goal.loseWeight;

    final pG = profile.proteinTargetG.round();
    final cG = profile.carbsTargetG.round();
    final fG = profile.fatTargetG.round();
    final pKcal = pG * 4;
    final cKcal = cG * 4;
    final fKcal = fG * 9;
    final totalMacroKcal = pKcal + cKcal + fKcal;
    final pPct =
        totalMacroKcal > 0 ? (pKcal / totalMacroKcal * 100).round() : 30;
    final cPct =
        totalMacroKcal > 0 ? (cKcal / totalMacroKcal * 100).round() : 45;
    final fPct =
        totalMacroKcal > 0 ? (fKcal / totalMacroKcal * 100).round() : 25;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: dividerColor, width: 0.8),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: textPrimary,
            ),
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'profile.goalsAndNutrition'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 48),
        children: [
          // ── SECTION 1: ACTIVE PLAN & WEIGHT PROGRESS CARD ──────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Pills: Goal & Pace
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Goal Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: dividerColor, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            plan.isWeightLoss
                                ? Icons.trending_down_rounded
                                : (plan.isWeightGain
                                    ? Icons.trending_up_rounded
                                    : Icons.balance_rounded),
                            size: 14,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _goalLabel(profile.goal),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E6319),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!plan.isMaintenance)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: dividerColor, width: 0.8),
                        ),
                        child: Text(
                          _paceLabel(profile.goalPace),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                // Weight 3-Points: Start -> Current -> Target
                Row(
                  children: [
                    // Start
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.start'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${startWeight.toStringAsFixed(1)} kg',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            weightLogs.isNotEmpty
                                ? DateFormat('d MMM')
                                    .format(weightLogs.first.loggedDate)
                                : 'profile.start'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: textTertiary.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),

                    // Current
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.current'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${currentWeight.toStringAsFixed(1)} kg',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'profile.today'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: textTertiary.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),

                    // Target
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.target'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${targetWeight.toStringAsFixed(1)} kg',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.accent
                                    : const Color(0xFF2E6319),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.isMaintenance
                                ? 'profile.trendStable'.tr()
                                : '${remainingDelta.toStringAsFixed(1)} kg',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E6319),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (!plan.isMaintenance) ...[
                  const SizedBox(height: 18),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      height: 7,
                      width: double.infinity,
                      color: surfaceAlt,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Progress Bottom Info
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        isGoalReached
                            ? 'profile.weightGoalReached'.tr()
                            : 'profile.targetWeightRemaining'.tr(
                                args: [remainingDelta.toStringAsFixed(1)],
                              ),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isGoalReached
                              ? (isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E6319))
                              : textSecondary,
                        ),
                      ),
                      if (plan.estimatedWeeks > 0)
                        Text(
                          '~${plan.estimatedWeeks} ${'profile.goalRoadmap.weeksCount'.tr(args: ['']).trim()}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 2: WEIGHT PROGRESS / HISTORY ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.weightProgress'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openLogWeightSheet(context, ref, profile),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                label: Text(
                  'profile.logWeight'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? AppColors.accent : const Color(0xFF2E6319),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(44, 34),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // If logs exist: render chart & history list. Else: empty state.
          if (weightLogs.isNotEmpty) ...[
            WeightJourneyChart(
              logs: weightLogs,
              profile: profile,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Recent Entries List
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dividerColor, width: 0.8),
                boxShadow: AppShadows.card(isDark),
              ),
              child: Column(
                children: [
                  for (int i = weightLogs.length - 1;
                      i >= math.max(0, weightLogs.length - 4);
                      i--) ...[
                    _WeightHistoryRow(
                      log: weightLogs[i],
                      previousLog: i > 0 ? weightLogs[i - 1] : null,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      onDelete: () =>
                          _confirmDeleteLog(context, ref, weightLogs[i]),
                    ),
                    if (i > math.max(0, weightLogs.length - 4))
                      Divider(height: 1, thickness: 0.6, color: dividerColor),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Dedicated Honest Empty State Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: dividerColor, width: 0.8),
                boxShadow: AppShadows.card(isDark),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      shape: BoxShape.circle,
                      border: Border.all(color: dividerColor, width: 0.8),
                    ),
                    child: Icon(
                      Icons.monitor_weight_outlined,
                      size: 26,
                      color: isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'profile.emptyWeightTitle'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'profile.emptyWeightSubtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openLogWeightSheet(context, ref, profile),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'profile.logWeight'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.accent : const Color(0xFF1B3D22),
                      foregroundColor:
                          isDark ? const Color(0xFF0F1410) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── SECTION 3: DAILY NUTRITION TARGETS ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.dailyNutritionTarget'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'profile.macroDistribution'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily Calorie Target Big Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'profile.targetCalories'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBmrClamped
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isBmrClamped
                            ? 'profile.bmrFloorBadge'.tr()
                            : (isCustom
                                ? 'profile.customBadge'.tr()
                                : 'profile.autoBadge'.tr()),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isBmrClamped
                              ? AppColors.warning
                              : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      calculatedCalories.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'profile.kcalPerDayUnit'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, thickness: 0.6, color: dividerColor),
                const SizedBox(height: 10),

                // Transparency: BMR & TDEE
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'BMR: $bmr kcal  ·  TDEE: $tdee kcal',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      'Mifflin-St Jeor',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),

                if (isBmrClamped) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 13, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'profile.bmrFloorExplanation'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3 Supporting Macro Cards (Protein, Carbs, Fat)
          Row(
            children: [
              // Protein
              Expanded(
                child: _MacroCard(
                  name: 'Protein',
                  grams: pG,
                  percentage: pPct,
                  kcal: pKcal,
                  color: AppColors.protein,
                  icon: Icons.fitness_center_rounded,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  dividerColor: dividerColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              // Carbs
              Expanded(
                child: _MacroCard(
                  name: 'Carbs',
                  grams: cG,
                  percentage: cPct,
                  kcal: cKcal,
                  color: AppColors.carbs,
                  icon: Icons.grain_rounded,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  dividerColor: dividerColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              // Fat (Avocado / Leaf icon - NEVER water droplet)
              Expanded(
                child: _MacroCard(
                  name: 'Fat',
                  grams: fG,
                  percentage: fPct,
                  kcal: fKcal,
                  color: AppColors.fat,
                  icon: Icons.eco_rounded,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  dividerColor: dividerColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── SECTION 4: PLAN MANAGEMENT ACTIONS ─────────────────────
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openAdjustPlanSheet(context, ref, profile),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : const Color(0xFFE8F8D0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.accent
                              : const Color(0xFF2E6319),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'profile.adjustPlan'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'profile.adjustPlanSubtitle'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Restart Setup Link
          Center(
            child: TextButton(
              onPressed: () => _confirmRestartSetup(context),
              style: TextButton.styleFrom(
                foregroundColor: textTertiary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                'profile.restartSetup'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MACRO CARD COMPONENT ──────────────────────────────────────────────
class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.name,
    required this.grams,
    required this.percentage,
    required this.kcal,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String name;
  final int grams;
  final int percentage;
  final int kcal;
  final Color color;
  final IconData icon;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor, width: 0.8),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 11, color: color),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${grams}g',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$percentage% · $kcal kcal',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── WEIGHT HISTORY ROW COMPONENT ──────────────────────────────────────
class _WeightHistoryRow extends StatelessWidget {
  const _WeightHistoryRow({
    required this.log,
    required this.previousLog,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onDelete,
  });

  final WeightLog log;
  final WeightLog? previousLog;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final double? delta =
        previousLog != null ? log.weightKg - previousLog!.weightKg : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM yyyy').format(log.loggedDate),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.notes!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.weightKg.toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(height: 1),
                Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: delta.abs() < 0.1
                        ? textTertiary
                        : (delta < 0
                            ? (isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319))
                            : Colors.orange),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            color: textTertiary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

// ── SUB-SHEET 1: ADJUST PLAN & TARGETS ────────────────────────────────
class _AdjustPlanSheet extends ConsumerStatefulWidget {
  const _AdjustPlanSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_AdjustPlanSheet> createState() => _AdjustPlanSheetState();
}

class _AdjustPlanSheetState extends ConsumerState<_AdjustPlanSheet> {
  late Goal _goal;
  late GoalPace _pace;
  late double _targetWeight;
  late bool _isCustomCalorie;
  late final TextEditingController _customCalorieCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.profile.goal;
    _pace = widget.profile.goalPace;
    _targetWeight = widget.profile.targetWeightKg ?? widget.profile.weightKg;
    _isCustomCalorie = widget.profile.isCustomTarget;
    _customCalorieCtrl = TextEditingController(
      text: widget.profile.customCalorieTarget != null
          ? widget.profile.customCalorieTarget!.round().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _customCalorieCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final customVal = double.tryParse(_customCalorieCtrl.text.trim());

    // BMR floor safety validation
    if (_isCustomCalorie &&
        (customVal == null || customVal < widget.profile.bmr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target kalori minimal adalah BMR (${widget.profile.bmr.round()} kcal) demi keamanan metabolisme.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedProfile = widget.profile.copyWith(
      goal: _goal,
      goalPace: _pace,
      targetWeightKg:
          _goal == Goal.maintainWeight ? widget.profile.weightKg : _targetWeight,
      customCalorieTarget: _isCustomCalorie ? customVal : null,
      clearCustomCalorieTarget: !_isCustomCalorie,
    );

    ref.read(userProfileProvider.notifier).state = updatedProfile;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        await ref.read(profileServiceProvider).saveProfile(
              userId: currentUser.id,
              profile: updatedProfile,
            );
      } catch (_) {
        // Fallback: local Riverpod state is already updated
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.planSavedSuccess'.tr()),
        backgroundColor: const Color(0xFF1B2A18),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final bmr = widget.profile.bmr.round();

    return RepaintBoundary(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'profile.adjustPlan'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.6, color: dividerColor),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Selector
                    Text(
                      'profile.nutritionGoal'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _GoalRadioCard(
                            label: 'dashboard.goals.loseWeight'.tr(),
                            icon: Icons.trending_down_rounded,
                            isSelected: _goal == Goal.loseWeight,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                            onTap: () => setState(() {
                              _goal = Goal.loseWeight;
                              if (_targetWeight >= widget.profile.weightKg) {
                                _targetWeight = math.max(
                                    25.0, widget.profile.weightKg - 3.0);
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GoalRadioCard(
                            label: 'dashboard.goals.maintainWeight'.tr(),
                            icon: Icons.balance_rounded,
                            isSelected: _goal == Goal.maintainWeight,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                            onTap: () => setState(() {
                              _goal = Goal.maintainWeight;
                              _targetWeight = widget.profile.weightKg;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GoalRadioCard(
                            label: 'dashboard.goals.gainWeight'.tr(),
                            icon: Icons.trending_up_rounded,
                            isSelected: _goal == Goal.gainWeight,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                            onTap: () => setState(() {
                              _goal = Goal.gainWeight;
                              if (_targetWeight <= widget.profile.weightKg) {
                                _targetWeight = widget.profile.weightKg + 3.0;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),

                    // Target Weight (if not maintain)
                    if (_goal != Goal.maintainWeight) ...[
                      const SizedBox(height: 20),
                      Text(
                        'profile.targetWeightSection'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: dividerColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_targetWeight.toStringAsFixed(1)} kg',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.accent
                                    : const Color(0xFF2E6319),
                              ),
                            ),
                            Row(
                              children: [
                                _StepperSquareButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_targetWeight > 25.0) {
                                      setState(() => _targetWeight -= 0.5);
                                    }
                                  },
                                  isDark: isDark,
                                  dividerColor: dividerColor,
                                  textPrimary: textPrimary,
                                ),
                                const SizedBox(width: 8),
                                _StepperSquareButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    if (_targetWeight < 300.0) {
                                      setState(() => _targetWeight += 0.5);
                                    }
                                  },
                                  isDark: isDark,
                                  dividerColor: dividerColor,
                                  textPrimary: textPrimary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Pace Selector (if not maintain)
                    if (_goal != Goal.maintainWeight) ...[
                      const SizedBox(height: 20),
                      Text(
                        'profile.progressPaceSection'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          _PaceRadioRow(
                            title: 'onboarding.paces.gentle'.tr(),
                            subtitle: 'onboarding.paces.gentleSub'.tr(),
                            offset: 'profile.offsetPerDay'.tr(args: ['250']),
                            isSelected: _pace == GoalPace.gentle,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => setState(() => _pace = GoalPace.gentle),
                          ),
                          const SizedBox(height: 6),
                          _PaceRadioRow(
                            title: 'onboarding.paces.moderate'.tr(),
                            subtitle: 'onboarding.paces.moderateSub'.tr(),
                            offset: 'profile.offsetPerDay'.tr(args: ['500']),
                            isRecommended: true,
                            isSelected: _pace == GoalPace.moderate,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => setState(() => _pace = GoalPace.moderate),
                          ),
                          const SizedBox(height: 6),
                          _PaceRadioRow(
                            title: 'onboarding.paces.faster'.tr(),
                            subtitle: 'onboarding.paces.fasterSub'.tr(),
                            offset: 'profile.offsetPerDay'.tr(args: ['750']),
                            isSelected: _pace == GoalPace.faster,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => setState(() => _pace = GoalPace.faster),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Custom Calorie Target
                    GestureDetector(
                      onTap: () => setState(() {
                        _isCustomCalorie = !_isCustomCalorie;
                        if (!_isCustomCalorie) {
                          _customCalorieCtrl.clear();
                        } else if (_customCalorieCtrl.text.isEmpty) {
                          _customCalorieCtrl.text =
                              widget.profile.dailyCalorieTarget.round().toString();
                        }
                      }),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            _isCustomCalorie
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: _isCustomCalorie
                                ? (isDark
                                    ? AppColors.accent
                                    : const Color(0xFF2E6319))
                                : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'profile.customCalorieToggle'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isCustomCalorie) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customCalorieCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [InputValidators.integerFormatter],
                        scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'profile.customCaloriesLabel'.tr(),
                          hintText: 'profile.customCaloriesHint'.tr(args: [bmr.toString()]),
                          suffixText: 'kcal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'profile.customCaloriesBmrDisclaimer'.tr(args: [bmr.toString()]),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.accent
                              : const Color(0xFF1B3D22),
                          foregroundColor:
                              isDark ? const Color(0xFF0F1410) : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'profile.savePlan'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SUB-SHEET 2: LOG WEIGHT ───────────────────────────────────────────
class _LogWeightSheet extends ConsumerStatefulWidget {
  const _LogWeightSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends ConsumerState<_LogWeightSheet> {
  late double _weight;
  late DateTime _selectedDate;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _weightCtrl;
  late final FocusNode _weightFocusNode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weight = widget.profile.weightKg;
    _selectedDate = DateTime.now();
    _noteCtrl = TextEditingController();
    _weightCtrl = TextEditingController(text: _weight.toStringAsFixed(1));
    _weightFocusNode = FocusNode();
    _weightFocusNode.addListener(() {
      setState(() {});
      if (!_weightFocusNode.hasFocus) {
        final parsed = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
        if (parsed != null && parsed >= 20.0 && parsed <= 350.0) {
          _weight = parsed;
          _weightCtrl.text = _weight.toStringAsFixed(1);
        } else {
          _weightCtrl.text = _weight.toStringAsFixed(1);
        }
      }
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _weightFocusNode.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _saveWeight() async {
    final clean = _weightCtrl.text.replaceAll(',', '.');
    final parsed = double.tryParse(clean);
    if (parsed != null && parsed >= 20.0 && parsed <= 350.0) {
      _weight = parsed;
    }

    setState(() => _isSaving = true);

    ref.read(weightLogProvider.notifier).addWeightLog(
          _weight,
          date: _selectedDate,
          notes: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'profile.weightLoggedSuccess'.tr(args: [_weight.toStringAsFixed(1)]),
        ),
        backgroundColor: const Color(0xFF1B2A18),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return RepaintBoundary(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'profile.logWeight'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.6, color: dividerColor),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  children: [
                    // Big Weight Stepper Display
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _weightFocusNode.hasFocus
                              ? (isDark
                                  ? AppColors.accent.withValues(alpha: 0.6)
                                  : const Color(0xFF1B3D22)
                                      .withValues(alpha: 0.4))
                              : dividerColor,
                          width: _weightFocusNode.hasFocus ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StepperSquareButton(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              _weightFocusNode.unfocus();
                              if (_weight > 25.0) {
                                setState(() {
                                  _weight = double.parse(
                                      (_weight - 0.1).toStringAsFixed(1));
                                  _weightCtrl.text = _weight.toStringAsFixed(1);
                                });
                              }
                            },
                            isDark: isDark,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                          ),
                          const SizedBox(width: 18),
                          IntrinsicWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 100,
                                    maxWidth: 160,
                                  ),
                                  child: TextField(
                                    controller: _weightCtrl,
                                    focusNode: _weightFocusNode,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    textAlign: TextAlign.center,
                                    cursorColor: isDark
                                        ? AppColors.accent
                                        : const Color(0xFF1B3D22),
                                    style: GoogleFonts.inter(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                      letterSpacing: -1.0,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                    ),
                                    onChanged: (val) {
                                      final clean = val.replaceAll(',', '.');
                                      final parsed = double.tryParse(clean);
                                      if (parsed != null && parsed > 0) {
                                        _weight = parsed;
                                      }
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'kg',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 12,
                                      color: textSecondary.withValues(
                                          alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          _StepperSquareButton(
                            icon: Icons.add_rounded,
                            onTap: () {
                              _weightFocusNode.unfocus();
                              if (_weight < 300.0) {
                                setState(() {
                                  _weight = double.parse(
                                      (_weight + 0.1).toStringAsFixed(1));
                                  _weightCtrl.text = _weight.toStringAsFixed(1);
                                });
                              }
                            },
                            isDark: isDark,
                            dividerColor: dividerColor,
                            textPrimary: textPrimary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date Row
                    GestureDetector(
                      onTap: _pickDate,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: dividerColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 16, color: textSecondary),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('d MMMM yyyy')
                                      .format(_selectedDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.edit_calendar_rounded,
                                size: 16, color: textSecondary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Note Input
                    TextField(
                      controller: _noteCtrl,
                      scrollPadding: const EdgeInsets.only(bottom: 80, top: 20),
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'profile.weightNotePlaceholder'.tr(),
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: textSecondary.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: dividerColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: dividerColor, width: 0.8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.accent
                              : const Color(0xFF1B3D22),
                          foregroundColor:
                              isDark ? const Color(0xFF0F1410) : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'profile.logWeightNow'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RADIO CARD HELPERS ────────────────────────────────────────────────
class _GoalRadioCard extends StatelessWidget {
  const _GoalRadioCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : const Color(0xFFE8F8D0))
              : surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.accent : const Color(0xFF2E6319))
                : dividerColor,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.accent : const Color(0xFF2E6319))
                  : textPrimary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.accent : const Color(0xFF2E6319))
                      : textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceRadioRow extends StatelessWidget {
  const _PaceRadioRow({
    required this.title,
    required this.subtitle,
    required this.offset,
    this.isRecommended = false,
    required this.isSelected,
    required this.isDark,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String offset;
  final bool isRecommended;
  final bool isSelected;
  final bool isDark;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : const Color(0xFFE8F8D0))
              : surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.accent : const Color(0xFF2E6319))
                : dividerColor,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected
                  ? (isDark ? AppColors.accent : const Color(0xFF2E6319))
                  : textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'profile.recommendedBadge'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF0F1410)
                                  : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              offset,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperSquareButton extends StatelessWidget {
  const _StepperSquareButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.dividerColor,
    required this.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color dividerColor;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: textPrimary),
        ),
      ),
    );
  }
}
