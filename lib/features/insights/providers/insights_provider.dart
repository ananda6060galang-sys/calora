import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/food.dart';
import '../../../models/user_profile.dart';
import '../../dashboard/providers/profile_provider.dart';
import '../../diary/providers/diary_provider.dart';
import '../models/insights_state.dart';

final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  final profile = ref.watch(userProfileProvider);
  final diaryEntries = ref.watch(diaryProvider);
  return InsightsNotifier(
    profile: profile,
    diaryEntries: diaryEntries,
  );
});

class InsightsNotifier extends StateNotifier<InsightsState> {
  InsightsNotifier({
    required UserProfile profile,
    required List<DiaryEntry> diaryEntries,
  })  : _profile = profile,
        _diaryEntries = diaryEntries,
        super(_calculateState(
          profile: profile,
          diaryEntries: diaryEntries,
          isDemoMode: false,
          forceEmpty: false,
        ));

  final UserProfile _profile;
  final List<DiaryEntry> _diaryEntries;

  void toggleDemoMode() {
    state = _calculateState(
      profile: _profile,
      diaryEntries: _diaryEntries,
      isDemoMode: !state.isDemoMode,
      forceEmpty: false,
    );
  }

  void toggleEmptyState() {
    if (state.isEmpty) {
      // Toggle to populated demo mode to inspect populated UI
      state = _calculateState(
        profile: _profile,
        diaryEntries: _diaryEntries,
        isDemoMode: true,
        forceEmpty: false,
      );
    } else {
      // Toggle to empty state
      state = _calculateState(
        profile: _profile,
        diaryEntries: _diaryEntries,
        isDemoMode: false,
        forceEmpty: true,
      );
    }
  }

  static InsightsState _calculateState({
    required UserProfile profile,
    required List<DiaryEntry> diaryEntries,
    required bool isDemoMode,
    required bool forceEmpty,
  }) {
    final targetCal = profile.dailyCalorieTarget > 0
        ? profile.dailyCalorieTarget
        : 2000.0;
    final targetProtein =
        profile.proteinTargetG > 0 ? profile.proteinTargetG : 120.0;
    final targetCarbs =
        profile.carbsTargetG > 0 ? profile.carbsTargetG : 250.0;
    final targetFat = profile.fatTargetG > 0 ? profile.fatTargetG : 65.0;

    if (forceEmpty) {
      return _buildEmptyState(
        targetCal,
        targetProtein,
        targetCarbs,
        targetFat,
      );
    }

    if (isDemoMode) {
      return _buildDemoState(
        targetCal,
        targetProtein,
        targetCarbs,
        targetFat,
      );
    }

    // REAL DATA CALCULATION FROM DIARY ENTRIES
    final now = DateTime.now();
    final List<DailyCalorieData> days = [];
    int loggedCount = 0;
    double totalCaloriesLogged = 0;
    double totalProteinLogged = 0;
    double totalCarbsLogged = 0;
    double totalFatLogged = 0;

    const dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayEntries = diaryEntries.where(
        (e) => DateUtils.isSameDay(e.date, date),
      );

      final dayCalories = dayEntries.fold<int>(0, (sum, e) => sum + e.calories);
      final dayProtein =
          dayEntries.fold<double>(0, (sum, e) => sum + e.proteinG);
      final dayCarbs = dayEntries.fold<double>(0, (sum, e) => sum + e.carbsG);
      final dayFat = dayEntries.fold<double>(0, (sum, e) => sum + e.fatG);

      final isLogged = dayCalories > 0;
      if (isLogged) {
        loggedCount++;
        totalCaloriesLogged += dayCalories;
        totalProteinLogged += dayProtein;
        totalCarbsLogged += dayCarbs;
        totalFatLogged += dayFat;
      }

      final weekdayIndex = date.weekday - 1; // 0 = Mon, 6 = Sun
      days.add(
        DailyCalorieData(
          dayLabel: dayNames[weekdayIndex],
          dayNumber: date.day,
          dayInitial: dayInitials[weekdayIndex],
          calories: dayCalories.toDouble(),
          targetCalories: targetCal,
          date: date,
          isToday: i == 6,
          isLogged: isLogged,
        ),
      );
    }

    // If 0 days are logged, return empty state
    if (loggedCount == 0) {
      return _buildEmptyState(
        targetCal,
        targetProtein,
        targetCarbs,
        targetFat,
      );
    }

    final avgCalories = totalCaloriesLogged / loggedCount;
    final avgProtein = totalProteinLogged / loggedCount;
    final avgCarbs = totalCarbsLogged / loggedCount;
    final avgFat = totalFatLogged / loggedCount;

    // Macro status labels
    String proteinStatus = 'Good';
    if (avgProtein < targetProtein * 0.8) {
      proteinStatus = 'Low';
    } else if (avgProtein >= targetProtein * 0.95) {
      proteinStatus = 'Target hit';
    }

    String carbsStatus = 'Good';
    if (avgCarbs > targetCarbs * 1.15) {
      carbsStatus = 'High';
    } else if (avgCarbs < targetCarbs * 0.75) {
      carbsStatus = 'Low';
    } else {
      carbsStatus = 'On track';
    }

    String fatStatus = 'On track';
    if (avgFat > targetFat * 1.2) {
      fatStatus = 'High';
    } else if (avgFat < targetFat * 0.75) {
      fatStatus = 'Low';
    }

    // Dynamic Smart Insights
    final smartInsights = <SmartInsightItem>[];

    // 1. Protein Insight
    if (avgProtein < targetProtein * 0.85) {
      smartInsights.add(
        const SmartInsightItem(
          icon: Icons.fitness_center_rounded,
          tag: 'PROTEIN INTAKE',
          title: 'Protein is slightly low',
          description:
              'Your average protein intake is below your daily target this week.',
          recommendation:
              'Try adding eggs, tofu, Greek yogurt, or another protein source.',
          badgeColor: AppColors.protein,
        ),
      );
    } else {
      smartInsights.add(
        const SmartInsightItem(
          icon: Icons.verified_rounded,
          tag: 'PROTEIN INTAKE',
          title: 'Protein on target',
          description:
              'You hit your protein goal consistently over your logged days.',
          recommendation: 'Keep maintaining this balance for optimal recovery.',
          badgeColor: AppColors.protein,
        ),
      );
    }

    // 2. Calorie Insight
    final diff = avgCalories - targetCal;
    if (diff.abs() <= targetCal * 0.08) {
      smartInsights.add(
        const SmartInsightItem(
          icon: Icons.track_changes_rounded,
          tag: 'CALORIE BALANCE',
          title: 'Calories are on track',
          description:
              'Your average intake stayed close to your daily target this week.',
          recommendation: 'Steady energy levels support consistent progress.',
          badgeColor: AppColors.accent,
        ),
      );
    } else if (diff < 0) {
      smartInsights.add(
        SmartInsightItem(
          icon: Icons.trending_down_rounded,
          tag: 'CALORIE BALANCE',
          title: 'Below calorie target',
          description:
              'You averaged ${diff.abs().round()} kcal below target across logged days.',
          recommendation: 'Ensure you are fueling enough for your daily activity.',
          badgeColor: AppColors.accent,
        ),
      );
    } else {
      smartInsights.add(
        SmartInsightItem(
          icon: Icons.trending_up_rounded,
          tag: 'CALORIE BALANCE',
          title: 'Slight surplus intake',
          description:
              'Your average intake is ${diff.round()} kcal above target this week.',
          recommendation: 'Check portion sizes on carb or fat-heavy meals.',
          badgeColor: AppColors.warning,
        ),
      );
    }

    // 3. Consistency Insight
    if (loggedCount >= 5) {
      smartInsights.add(
        SmartInsightItem(
          icon: Icons.calendar_today_rounded,
          tag: 'HABIT',
          title: 'Strong logging consistency',
          description: 'You logged meals on $loggedCount of the last 7 days.',
          recommendation:
              'Consistent tracking provides the clearest picture of your health.',
          badgeColor: const Color(0xFF67B26F),
        ),
      );
    } else {
      smartInsights.add(
        SmartInsightItem(
          icon: Icons.edit_calendar_rounded,
          tag: 'HABIT',
          title: 'Build daily logging',
          description: 'You logged $loggedCount of 7 days this week.',
          recommendation: 'Try logging meals right after eating to capture portions.',
          badgeColor: const Color(0xFF67B26F),
        ),
      );
    }

    return InsightsState(
      period: InsightsPeriod.week,
      isEmpty: false,
      averageCalories: avgCalories,
      targetCalories: targetCal,
      calorieHistory: days,
      protein: MacroInsightItem(
        label: 'dashboard.protein'.tr(),
        currentG: avgProtein,
        targetG: targetProtein,
        color: AppColors.protein,
        statusLabel: proteinStatus,
      ),
      carbs: MacroInsightItem(
        label: 'dashboard.carbs'.tr(),
        currentG: avgCarbs,
        targetG: targetCarbs,
        color: AppColors.carbs,
        statusLabel: carbsStatus,
      ),
      fat: MacroInsightItem(
        label: 'dashboard.fat'.tr(),
        currentG: avgFat,
        targetG: targetFat,
        color: AppColors.fat,
        statusLabel: fatStatus,
      ),
      smartInsights: smartInsights,
      loggedDaysCount: loggedCount,
      totalDaysCount: 7,
      isDemoMode: false,
    );
  }

  static InsightsState _buildDemoState(
    double targetCal,
    double targetProtein,
    double targetCarbs,
    double targetFat,
  ) {
    final now = DateTime.now();
    const dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const demoValues = [1820.0, 1950.0, 1780.0, 1890.0, 2020.0, 0.0, 1842.0];

    final List<DailyCalorieData> days = [];
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final val = demoValues[i];
      final weekdayIndex = date.weekday - 1;
      days.add(
        DailyCalorieData(
          dayLabel: dayNames[weekdayIndex],
          dayNumber: date.day,
          dayInitial: dayInitials[weekdayIndex],
          calories: val,
          targetCalories: targetCal,
          date: date,
          isToday: i == 6,
          isLogged: val > 0,
        ),
      );
    }

    return InsightsState(
      period: InsightsPeriod.week,
      isEmpty: false,
      averageCalories: 1842,
      targetCalories: targetCal,
      calorieHistory: days,
      protein: MacroInsightItem(
        label: 'dashboard.protein'.tr(),
        currentG: 78,
        targetG: targetProtein,
        color: AppColors.protein,
        statusLabel: 'Low',
      ),
      carbs: MacroInsightItem(
        label: 'dashboard.carbs'.tr(),
        currentG: 210,
        targetG: targetCarbs,
        color: AppColors.carbs,
        statusLabel: 'Good',
      ),
      fat: MacroInsightItem(
        label: 'dashboard.fat'.tr(),
        currentG: 58,
        targetG: targetFat,
        color: AppColors.fat,
        statusLabel: 'On track',
      ),
      smartInsights: const [
        SmartInsightItem(
          icon: Icons.fitness_center_rounded,
          tag: 'PROTEIN INTAKE',
          title: 'Protein is slightly low',
          description:
              'Your average protein intake is below your daily target this week.',
          recommendation:
              'Try adding eggs, tofu, Greek yogurt, or another protein source.',
          badgeColor: AppColors.protein,
        ),
        SmartInsightItem(
          icon: Icons.track_changes_rounded,
          tag: 'CALORIE BALANCE',
          title: 'Calories are on track',
          description:
              'Your average intake stayed close to your daily target this week.',
          recommendation: 'Steady energy levels support consistent progress.',
          badgeColor: AppColors.accent,
        ),
        SmartInsightItem(
          icon: Icons.calendar_today_rounded,
          tag: 'HABIT',
          title: 'Strong logging consistency',
          description: 'You logged meals on 6 of the last 7 days.',
          recommendation:
              'Consistent tracking provides the clearest picture of your health.',
          badgeColor: Color(0xFF67B26F),
        ),
      ],
      loggedDaysCount: 6,
      totalDaysCount: 7,
      isDemoMode: true,
    );
  }

  static InsightsState _buildEmptyState(
    double targetCal,
    double targetProtein,
    double targetCarbs,
    double targetFat,
  ) {
    final now = DateTime.now();
    const dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final List<DailyCalorieData> days = [];
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final weekdayIndex = date.weekday - 1;
      days.add(
        DailyCalorieData(
          dayLabel: dayNames[weekdayIndex],
          dayNumber: date.day,
          dayInitial: dayInitials[weekdayIndex],
          calories: 0,
          targetCalories: targetCal,
          date: date,
          isToday: i == 6,
          isLogged: false,
        ),
      );
    }

    return InsightsState(
      period: InsightsPeriod.week,
      isEmpty: true,
      averageCalories: 0,
      targetCalories: targetCal,
      calorieHistory: days,
      protein: MacroInsightItem(
        label: 'dashboard.protein'.tr(),
        currentG: 0,
        targetG: targetProtein,
        color: AppColors.protein,
        statusLabel: 'No data',
      ),
      carbs: MacroInsightItem(
        label: 'dashboard.carbs'.tr(),
        currentG: 0,
        targetG: targetCarbs,
        color: AppColors.carbs,
        statusLabel: 'No data',
      ),
      fat: MacroInsightItem(
        label: 'dashboard.fat'.tr(),
        currentG: 0,
        targetG: targetFat,
        color: AppColors.fat,
        statusLabel: 'No data',
      ),
      smartInsights: const [],
      loggedDaysCount: 0,
      totalDaysCount: 7,
      isDemoMode: false,
    );
  }
}
