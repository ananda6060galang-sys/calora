import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/calora_avatar.dart';
import '../dashboard/providers/profile_provider.dart';
import '../diary/providers/diary_provider.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/providers/notifications_provider.dart';
import 'insights_detail_screen.dart';
import 'providers/insights_provider.dart';
import 'widgets/ai_coach_spotlight_card.dart';
import 'widgets/nutrition_summary_card.dart';
import 'widgets/organic_aura.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late DateTime _selectedDate;
  late final PageController _pageController;

  static const int _totalDays = 2000;
  static const int _initialPage = 1000;

  DateTime get _baseDate => DateUtils.dateOnly(DateTime.now());

  DateTime _dateForIndex(int page) =>
      _baseDate.add(Duration(days: page - _initialPage));

  int _pageForDate(DateTime date) =>
      _initialPage +
      DateUtils.dateOnly(date).difference(_baseDate).inDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 1.0 / 7.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _previousMonth(DateTime date) {
    final prevMonth = DateTime(date.year, date.month - 1, 1);
    final daysInPrevMonth =
        DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    final newDay = date.day.clamp(1, daysInPrevMonth);
    return DateTime(prevMonth.year, prevMonth.month, newDay);
  }

  DateTime _nextMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final daysInNextMonth =
        DateUtils.getDaysInMonth(nextMonth.year, nextMonth.month);
    final newDay = date.day.clamp(1, daysInNextMonth);
    return DateTime(nextMonth.year, nextMonth.month, newDay);
  }

  void _onPreviousMonth() {
    _selectDate(_previousMonth(_selectedDate));
  }

  void _onNextMonth() {
    _selectDate(_nextMonth(_selectedDate));
  }

  void _onDateTap(DateTime date) {
    _selectDate(date, animate: true);
  }

  void _selectDate(DateTime date, {bool animate = true}) {
    if (!DateUtils.isSameDay(date, _selectedDate)) {
      setState(() {
        _selectedDate = date;
      });
    }
    final page = _pageForDate(date);
    if (_pageController.hasClients) {
      if (animate) {
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _pageController.jumpToPage(page);
      }
    }
  }

  void _onPageChanged(int page) {
    final newDate = _dateForIndex(page);
    if (!DateUtils.isSameDay(newDate, _selectedDate)) {
      setState(() {
        _selectedDate = newDate;
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
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);
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
              physics: const ClampingScrollPhysics(),
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
                          Flexible(
                            child: Container(
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
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.name.isNotEmpty
                                              ? profile.name
                                              : 'onboarding.defaultUser'.tr(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right: Notification Icon with badge
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                            child: Container(
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
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 22,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : const Color(0xFF131814),
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8.5,
                                        height: 8.5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53935),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkSurface
                                                : Colors.white,
                                            width: 1.5,
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

                      const SizedBox(height: 22),

                      // ── 3. MONTH NAVIGATION (< September 2026 >) ───────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _onPreviousMonth,
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
                              onTap: _onNextMonth,
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

                      // ── 4. HORIZONTAL 7-DAY DATE CALENDAR (ANIMATED & SATISFYING) ──
                      SizedBox(
                        height: 96,
                        child: PageView.builder(
                          controller: _pageController,
                          clipBehavior: Clip.none,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _totalDays,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final date = _dateForIndex(index);
                            final isSelected =
                                DateUtils.isSameDay(date, _selectedDate);
                            final dayName = DateFormat.E(
                                    context.locale.languageCode)
                                .format(date);
                            final dateNum = date.day.toString();

                            return Center(
                              child: GestureDetector(
                                onTap: () => _onDateTap(date),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  width: isSelected ? 44 : 38,
                                  height: isSelected ? 78 : 62,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 2),
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.darkSurface
                                            : Colors.white)
                                        : (isDark
                                            ? AppColors.darkSurface
                                                .withValues(alpha: 0.50)
                                            : Colors.white.withValues(
                                                alpha: 0.58)),
                                    borderRadius: BorderRadius.circular(
                                      isSelected ? 24 : 20,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.accent
                                              : Colors.white)
                                          : (isDark
                                              ? AppColors.darkBorder
                                              : Colors.white.withValues(
                                                  alpha: 0.30)),
                                      width: isSelected ? 1.2 : 0.8,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: isDark ? 0.35 : 0.15,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 6),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: isSelected
                                          ? Column(
                                              key: const ValueKey('selected'),
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppColors.accent
                                                        : const Color(
                                                            0xFF17382B),
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
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF0F1410)
                                                              : Colors.white,
                                                          height: 1.0,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Container(
                                                        width: 3.5,
                                                        height: 3.5,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF0F1410)
                                                              : Colors.white,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
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
                                              key: const ValueKey('unselected'),
                                              mainAxisSize: MainAxisSize.min,
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
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 26),
                    ],
                  ),
                ),

                // ── ONE DOMINANT WHITE NUTRITION SUMMARY SURFACE ─────
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

                // ── AI NUTRITION COACH SPOTLIGHT CARD ────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  child: AiCoachSpotlightCard(
                    report: insightsState.aiReport,
                    isLoading: insightsState.isLoadingAiReport,
                    isDark: isDark,
                    onTap: () => Navigator.push(
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
