import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/providers/profile_provider.dart';
import '../diary/food_diary_screen.dart';
import '../diary/providers/diary_provider.dart';
import 'models/insights_state.dart';
import 'providers/insights_provider.dart';
import 'widgets/calorie_overview_card.dart';
import 'widgets/logging_consistency_card.dart';
import 'widgets/macro_breakdown_card.dart';
import 'widgets/nutrition_summary_card.dart';
import 'widgets/organic_aura.dart';
import 'widgets/smart_insights_section.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  /// 7 consecutive dates with [_selectedDate] centered at index 3.
  List<DateTime> get _sevenDays {
    return List.generate(7, (i) {
      return _selectedDate.add(Duration(days: i - 3));
    });
  }

  void _onPreviousWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    });
  }

  void _onNextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 7));
    });
  }

  void _onDateTap(DateTime date) {
    if (!DateUtils.isSameDay(date, _selectedDate)) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  String _getDailyInsight({
    required int consumed,
    required double target,
    required double proteinConsumed,
    required double proteinTarget,
  }) {
    if (consumed == 0) {
      return 'No meals logged for this day yet.';
    }
    if (consumed > target * 1.05) {
      return "You've exceeded your daily calorie target today.";
    }
    if (consumed >= target * 0.85 && consumed <= target * 1.05) {
      return "You're on track with your calorie target today. Keep it up!";
    }
    if (proteinConsumed < proteinTarget * 0.7) {
      return "Your protein intake is still below today's target.";
    }
    return "You're getting close to your calorie target today.";
  }

  void _openSmartInsightsSheet(
    BuildContext context,
    InsightsState insightsState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Color(0xFF0F1410),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Today's Smart Insights",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF131814),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...insightsState.smartInsights.take(3).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkElevated
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.eco_outlined,
                              size: 20,
                              color: Color(0xFF266E44),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF131814),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF6B7280),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    FoodDiaryScreen.openAddFoodSheet(context, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF0F1410),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    "Log a meal",
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F1410),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF101411) : const Color(0xFFFAF9F6);

    // Real Calora Data from Providers
    final profile = ref.watch(userProfileProvider);
    final diaryTotals = ref.watch(diaryTotalsForDateProvider(_selectedDate));
    final insightsState = ref.watch(insightsProvider);

    final consumedCalories = diaryTotals.calories;
    final targetCalories = profile.dailyCalorieTarget;

    final carbsConsumed = diaryTotals.carbsG;
    final carbsTarget = profile.carbsTargetG;

    final proteinConsumed = diaryTotals.proteinG;
    final proteinTarget = profile.proteinTargetG;

    final fatConsumed = diaryTotals.fatG;
    final fatTarget = profile.fatTargetG;

    final dailyInsight = _getDailyInsight(
      consumed: consumedCalories,
      target: targetCalories,
      proteinConsumed: proteinConsumed,
      proteinTarget: proteinTarget,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── 1. GREEN GRADIENT HEADER (Calora Botanical Canopy) ────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScreenBackgroundMesh(
              isDark: isDark,
              height: 460,
            ),
          ),

          // ── 2. SCROLLABLE SCREEN CONTENT ─────────────────────────────
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 2. TOP PROFILE ROW ───────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Existing Calora User Avatar + Name Capsule
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.08,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0].toUpperCase()
                                        : 'C',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F1410),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name.isNotEmpty
                                          ? profile.name
                                          : 'Calora User',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : const Color(0xFF131814),
                                        height: 1.15,
                                      ),
                                    ),
                                    Text(
                                      'Premium User',
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
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),

                          // Right: Notification Icon with badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.08,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  size: 22,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : const Color(0xFF131814),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 17,
                                  height: 17,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '2',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── 3. MONTH NAVIGATION (< September 2026 >) ───────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _onPreviousWeek,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 24,
                                  color: Colors.white.withValues(alpha: 0.90),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _onNextWeek,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 24,
                                  color: Colors.white.withValues(alpha: 0.90),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── 4. HORIZONTAL 7-DAY DATE CALENDAR ───────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(_sevenDays.length, (index) {
                          final date = _sevenDays[index];
                          final isSelected =
                              DateUtils.isSameDay(date, _selectedDate);
                          final dayName = DateFormat('E').format(date);
                          final dateNum = date.day.toString();

                          return GestureDetector(
                            onTap: () => _onDateTap(date),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 48 : 41,
                              height: isSelected ? 82 : 64,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkSurface
                                            .withValues(alpha: 0.50)
                                        : Colors.white
                                            .withValues(alpha: 0.58)),
                                borderRadius: BorderRadius.circular(
                                  isSelected ? 26 : 22,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white
                                          .withValues(alpha: 0.30),
                                  width: isSelected ? 1.0 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF17382B),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Text(
                                                dateNum,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  height: 1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                width: 3.5,
                                                height: 3.5,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          dayName,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF17382B),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayName,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors
                                                    .darkTextSecondary
                                                : const Color(0xFF354B3E),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          dateNum,
                                          style: GoogleFonts.inter(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors
                                                    .darkTextPrimary
                                                : const Color(0xFF1A2C21),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 26),
                    ],
                  ),
                ),

                // ── PART A: ONE DOMINANT WHITE NUTRITION SUMMARY SURFACE ─
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: NutritionSummaryCard(
                    consumedCalories: consumedCalories,
                    targetCalories: targetCalories,
                    carbsConsumed: carbsConsumed,
                    carbsTarget: carbsTarget,
                    proteinConsumed: proteinConsumed,
                    proteinTarget: proteinTarget,
                    fatConsumed: fatConsumed,
                    fatTarget: fatTarget,
                    insightMessage: dailyInsight,
                    ctaLabel: "See Today's Insights",
                    isDark: isDark,
                    onActionTap: () => _openSmartInsightsSheet(
                      context,
                      insightsState,
                    ),
                  ),
                ),

                // ── PART B: CALORA ANALYTICS DETAIL ─────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 14. 7-Day Calorie Intake
                      CalorieOverviewCard(
                        averageCalories: insightsState.averageCalories,
                        targetCalories: targetCalories,
                        history: insightsState.calorieHistory,
                        loggedDaysCount: insightsState.loggedDaysCount,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 36),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.5)
                            : const Color(0xFFEBECEF),
                      ),
                      const SizedBox(height: 32),

                      // 15. Macro Progress
                      MacroBreakdownCard(
                        protein: insightsState.protein,
                        carbs: insightsState.carbs,
                        fat: insightsState.fat,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 36),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.5)
                            : const Color(0xFFEBECEF),
                      ),
                      const SizedBox(height: 32),

                      // 16. Food Logging Consistency
                      LoggingConsistencyCard(
                        loggedDaysCount: insightsState.loggedDaysCount,
                        totalDaysCount: insightsState.totalDaysCount,
                        history: insightsState.calorieHistory,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 36),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.5)
                            : const Color(0xFFEBECEF),
                      ),
                      const SizedBox(height: 32),

                      // 17. Smart Insights
                      SmartInsightsSection(
                        items: insightsState.smartInsights,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
