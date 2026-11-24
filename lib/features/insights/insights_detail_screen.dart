import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/providers/profile_provider.dart';
import '../diary/food_diary_screen.dart';
import 'models/insights_state.dart';
import 'providers/insights_provider.dart';
import 'widgets/ai_coach_report_section.dart';
import 'widgets/calorie_overview_card.dart';

/// CALORA — DETAIL INSIGHTS
///
/// A calm, premium, editorial nutrition report designed around
/// Apple Health clarity, Calora's fresh botanical green identity,
/// full bilingual support (ID & EN), and deep black mode integration.
///
/// STRUCTURE:
/// - CHAPTER 01: "Your Week" (How am I doing? + What happened?)
/// - CHAPTER 02: "Nutrition" (Macros + Calorie Consistency + Food Logging)
/// - CHAPTER 03: "Your Patterns" (What does it mean?)
/// - CHAPTER 04: "Smart Insights" (Actionable Takeaways)
/// - FINAL ACTION: "Next Step" (What should I do?)
class InsightsDetailScreen extends ConsumerWidget {
  const InsightsDetailScreen({super.key});

  String _formatWithComma(num value) {
    return value.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getDateRange(BuildContext context, List<DailyCalorieData> history) {
    final locale = context.locale.languageCode;
    if (history.isEmpty) {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 6));
      return '${DateFormat.MMMd(locale).format(start)} — ${DateFormat.MMMd(locale).format(now)}';
    }
    final start =
        history.first.date ?? DateTime.now().subtract(const Duration(days: 6));
    final end = history.last.date ?? DateTime.now();
    return '${DateFormat.MMMd(locale).format(start)} — ${DateFormat.MMMd(locale).format(end)}';
  }

  String _getStrongestDayName(BuildContext context, List<DailyCalorieData> history, double target) {
    final locale = context.locale.languageCode;
    final loggedDays = history.where((d) => d.isLogged).toList();
    if (loggedDays.isEmpty) {
      return DateFormat.EEEE(locale).format(DateTime.now());
    }
    loggedDays.sort((a, b) =>
        (a.calories - target).abs().compareTo((b.calories - target).abs()));
    final bestDate = loggedDays.first.date ?? DateTime.now();
    return DateFormat.EEEE(locale).format(bestDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;

    // Deep Black Mode & Light Mode surfaces
    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFFAF9F6);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF131814);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    final profile = ref.watch(userProfileProvider);
    final insightsState = ref.watch(insightsProvider);
    final targetCalories = profile.dailyCalorieTarget;
    final history = insightsState.calorieHistory;

    final daysWithinTarget =
        history.where((d) => d.isLogged && d.isOnTarget).length;
    final dateRange = _getDateRange(context, history);
    final strongestDayName = _getStrongestDayName(context, history, targetCalories);

    // Dynamic macro room-to-improve interpretation (Bilingual)
    final proteinRatio = insightsState.protein.progress;
    final carbsRatio = insightsState.carbs.progress;
    final fatRatio = insightsState.fat.progress;
    String macroInterpretation = 'insights.proteinRoomToImprove'.tr();
    if (proteinRatio >= 0.85 && carbsRatio <= 1.10 && fatRatio <= 1.10) {
      macroInterpretation = 'insights.macrosBalanced'.tr();
    } else if (carbsRatio > 1.15) {
      macroInterpretation = 'insights.carbsHigherThanTarget'.tr();
    } else if (fatRatio > 1.15) {
      macroInterpretation = 'insights.fatAboveTarget'.tr();
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textPrimary,
          ),
        ),
        title: Text(
          'insights.title'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dateRange,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textTertiary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
        children: [
          // ══════════════════════════════════════════════════════════════
          // CHAPTER 01 — YOUR WEEK
          // Purpose: Answer "How did I do this week?"
          // ══════════════════════════════════════════════════════════════
          Text(
            'insights.weeklyInsights'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textTertiary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // One Dominant Summary (Hero Metric — Level 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatWithComma(insightsState.averageCalories)} kcal',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'insights.averageDailyIntake'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${'insights.targetLabel'.tr()} ',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: '${_formatWithComma(targetCalories)} kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(color: textTertiary, fontSize: 13),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${insightsState.loggedDaysCount} / 7 ',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'insights.loggedLabel'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 44),

          // 7-Day Calorie Intake (Visually belongs to Weekly section)
          Text(
            'insights.sevenDayCalorieIntake'.tr(),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'insights.dailyIntakeCompared'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          CalorieOverviewCard(
            showHeader: false,
            averageCalories: insightsState.averageCalories,
            targetCalories: targetCalories,
            history: history,
            loggedDaysCount: insightsState.loggedDaysCount,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Text(
            daysWithinTarget >= 4
                ? 'insights.intakeCloseToTarget'.tr()
                : 'insights.trackingConsistentlyTip'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),

          // ── GENEROUS CHAPTER TRANSITION WHITESPACE (68px) ─────────────
          const SizedBox(height: 68),

          // ══════════════════════════════════════════════════════════════
          // CHAPTER 02 — NUTRITION
          // Purpose: "How your macros are tracking against daily targets."
          // ══════════════════════════════════════════════════════════════
          Text(
            'insights.nutrition'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'insights.macrosTrackingAgainstTargets'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Three Clean Vertical Rhythm Rows (No cards, no giant icons)
          _buildMacroRow(
            label: 'dashboard.protein'.tr().toUpperCase(),
            currentG: insightsState.protein.currentG.round(),
            targetG: insightsState.protein.targetG.round(),
            color: AppColors.protein,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildMacroRow(
            label: 'dashboard.carbs'.tr().toUpperCase(),
            currentG: insightsState.carbs.currentG.round(),
            targetG: insightsState.carbs.targetG.round(),
            color: AppColors.carbs,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildMacroRow(
            label: 'dashboard.fat'.tr().toUpperCase(),
            currentG: insightsState.fat.currentG.round(),
            targetG: insightsState.fat.targetG.round(),
            color: AppColors.fat,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Text(
            macroInterpretation,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 48),

          // Secondary Subsection: CALORIE CONSISTENCY (Kept inside Chapter 02)
          Text(
            'insights.calorieConsistency'.tr(),
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${'insights.daysWithinTarget'.tr(args: [daysWithinTarget.toString()])} ',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: 'insights.withinTarget'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Clean Mon-Sun Dot Row (● ● ● ○ ● ● ○)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(history.length, (index) {
              final item = history[index];
              final isOnTarget = item.isLogged && item.isOnTarget;
              final dayLabel = item.date != null
                  ? DateFormat.E(locale).format(item.date!)
                  : item.dayLabel;

              return Column(
                children: [
                  Text(
                    dayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnTarget
                          ? (isDark
                              ? AppColors.accent
                              : const Color(0xFF2E7548))
                          : Colors.transparent,
                      border: isOnTarget
                          ? null
                          : Border.all(
                              color: item.isLogged
                                  ? (isDark
                                      ? AppColors.darkBorder
                                      : const Color(0xFFB0B7B1))
                                  : (isDark
                                      ? const Color(0xFF242C25)
                                      : const Color(0xFFE2E4E1)),
                              width: 1.3,
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'insights.mostDaysWithinRange'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 40),

          // Secondary Subsection: FOOD LOGGING (Kept inside Chapter 02)
          Text(
            'insights.foodLogging'.tr(),
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${insightsState.loggedDaysCount} / 7 ',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: 'insights.loggedLabel'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'insights.daysWithEntry'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          // Clean M T W T F S S Checkmark/Dash Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(history.length, (index) {
              final item = history[index];
              final isLogged = item.isLogged;
              final dayInitial = item.date != null
                  ? DateFormat.E(locale).format(item.date!).substring(0, 1).toUpperCase()
                  : item.dayInitial;

              return Column(
                children: [
                  Text(
                    dayInitial,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 18,
                    child: Center(
                      child: isLogged
                          ? Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E7548),
                            )
                          : Text(
                              '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: textTertiary,
                                height: 1.0,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),

          // ── GENEROUS CHAPTER TRANSITION WHITESPACE (68px) ─────────────
          const SizedBox(height: 68),

          // ══════════════════════════════════════════════════════════════
          // CHAPTER 03 — YOUR PATTERNS
          // Purpose: Data to Interpretation (What does it mean?)
          // ══════════════════════════════════════════════════════════════
          Text(
            'insights.yourPatterns'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'insights.patternsSubtitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Editorial Text Blocks (NO cards for every pattern!)
          _buildEditorialPattern(
            label: 'insights.strongestDayLabel'.tr(),
            explanation:
                'insights.strongestDayDesc'.tr(args: [strongestDayName]),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
          ),
          const SizedBox(height: 32),
          _buildEditorialPattern(
            label: 'insights.proteinPatternLabel'.tr(),
            explanation: proteinRatio < 0.85
                ? 'insights.proteinPatternLow'.tr()
                : 'insights.proteinPatternGood'.tr(),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
          ),
          const SizedBox(height: 32),
          _buildEditorialPattern(
            label: 'insights.loggingPatternLabel'.tr(),
            explanation: insightsState.loggedDaysCount >= 5
                ? 'insights.loggingPatternGood'.tr()
                : 'insights.loggingPatternLow'.tr(),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
          ),

          // Optional Goal Progress Snapshot (Extremely simple, no historical claims)
          if (profile.targetWeightKg != null) ...[
            const SizedBox(height: 40),
            Text(
              'insights.goalProgress'.tr(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${profile.weightKg.toStringAsFixed(1)} kg',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'insights.currentWeight'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${profile.targetWeightKg!.toStringAsFixed(1)} kg',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'insights.goalWeight'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${(profile.weightKg - profile.targetWeightKg!).abs().toStringAsFixed(1)} kg',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E7548),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'insights.toGoal'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // ── GENEROUS CHAPTER TRANSITION WHITESPACE (68px) ─────────────
          const SizedBox(height: 68),

          // ══════════════════════════════════════════════════════════════
          // CHAPTER 04 — AI NUTRITION COACH
          // Purpose: "Deep clinical nutrition evaluation & food swaps"
          // ══════════════════════════════════════════════════════════════
          AiCoachReportSection(
            report: insightsState.aiReport,
            isLoading: insightsState.isLoadingAiReport,
            isDark: isDark,
            onRefresh: () => ref.read(insightsProvider.notifier).fetchAiReport(
                  forceRefresh: true,
                  locale: context.locale.languageCode,
                ),
          ),

          // ── VISUAL PAUSE BEFORE FINAL ACTION (56px) ───────────────────
          const SizedBox(height: 56),

          // ══════════════════════════════════════════════════════════════
          // FINAL ACTION — NEXT STEP
          // Purpose: One simple natural conclusion CTA
          // ══════════════════════════════════════════════════════════════
          Text(
            'insights.nextStep'.tr(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'insights.nextStepDesc'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                FoodDiaryScreen.openAddFoodSheet(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent
                    : const Color(0xFF17382B),
                foregroundColor: isDark
                    ? const Color(0xFF0F1410)
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'insights.logFood'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFF0F1410)
                      : Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS (EDITORIAL & CLEAN) ──────────────────────────────

  Widget _buildMacroRow({
    required String label,
    required int currentG,
    required int targetG,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final ratio = targetG > 0 ? (currentG / targetG).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$currentG / $targetG g',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          height: 4.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222B22) : const Color(0xFFEBECEF),
            borderRadius: BorderRadius.circular(2.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorialPattern({
    required String label,
    required String explanation,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textTertiary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          explanation,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }


}
