import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/calora_avatar.dart';
import '../dashboard/providers/profile_provider.dart';
import '../diary/providers/diary_provider.dart';
import 'insights_detail_screen.dart';
import 'widgets/nutrition_summary_card.dart';
import 'widgets/organic_aura.dart';

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
      return 'insights.noMealsLogged'.tr();
    }
    if (consumed > target * 1.05) {
      return 'insights.exceededTarget'.tr();
    }
    if (consumed >= target * 0.85 && consumed <= target * 1.05) {
      return 'insights.onTrackToday'.tr();
    }
    if (proteinConsumed < proteinTarget * 0.7) {
      return 'insights.proteinBelowTarget'.tr();
    }
    return 'insights.closeToTarget'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF101411) : const Color(0xFFFAF9F6);

    // Real Calora Data from Providers
    final profile = ref.watch(userProfileProvider);
    final diaryTotals = ref.watch(diaryTotalsForDateProvider(_selectedDate));

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
                                CaloraAvatar(
                                  avatarUrl: profile.avatarUrl,
                                  displayName: profile.name,
                                  size: 34,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name.isNotEmpty
                                          ? profile.name
                                          : 'onboarding.defaultUser'.tr(),
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
                                      'insights.premiumUser'.tr(),
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
                              DateFormat.yMMMM(context.locale.languageCode).format(_selectedDate),
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
                          final dayName = DateFormat.E(context.locale.languageCode).format(date);
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
                                    ? (isDark ? AppColors.darkSurface : Colors.white)
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
                                      ? (isDark ? AppColors.accent : Colors.white)
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : Colors.white.withValues(alpha: 0.30)),
                                  width: isSelected ? 1.2 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: isDark ? 0.35 : 0.15),
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
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.accent
                                                : const Color(0xFF17382B),
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
                                                  color: isDark
                                                      ? const Color(0xFF0F1410)
                                                      : Colors.white,
                                                  height: 1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                width: 3.5,
                                                height: 3.5,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF0F1410)
                                                      : Colors.white,
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
                                            color: isDark
                                                ? AppColors.accent
                                                : const Color(0xFF17382B),
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

                // ── ONE DOMINANT WHITE NUTRITION SUMMARY SURFACE ─────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
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
                    ctaLabel: 'insights.seeTodaysInsights'.tr(),
                    isDark: isDark,
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InsightsDetailScreen(),
                      ),
                    ),
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
