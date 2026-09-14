import 'package:flutter/material.dart';

enum InsightsPeriod { week, month }

class DailyCalorieData {
  const DailyCalorieData({
    required this.dayLabel,
    required this.dayNumber,
    required this.dayInitial,
    required this.calories,
    required this.targetCalories,
    this.date,
    this.isToday = false,
    this.isLogged = true,
  });

  final String dayLabel; // e.g. 'Mon'
  final int dayNumber; // e.g. 18
  final String dayInitial; // e.g. 'M'
  final double calories;
  final double targetCalories;
  final DateTime? date;
  final bool isToday;
  final bool isLogged;

  bool get isOnTarget =>
      calories >= (targetCalories * 0.9) && calories <= (targetCalories * 1.1);
  double get ratio => targetCalories <= 0 ? 0.0 : (calories / targetCalories);
}

class MacroInsightItem {
  const MacroInsightItem({
    required this.label,
    required this.currentG,
    required this.targetG,
    required this.color,
    this.statusLabel = 'Good',
  });

  final String label;
  final double currentG;
  final double targetG;
  final Color color;
  final String statusLabel; // e.g. 'Low', 'Good', 'On track'

  double get progress =>
      targetG <= 0 ? 0.0 : (currentG / targetG).clamp(0.0, 1.0);
  int get percentage => (progress * 100).round();
}

class MealDistributionItem {
  const MealDistributionItem({
    required this.mealType,
    required this.calories,
    required this.percentage,
    required this.color,
  });

  final String mealType;
  final int calories;
  final double percentage; // 0..100
  final Color color;
}

class SmartInsightItem {
  const SmartInsightItem({
    required this.icon,
    required this.title,
    required this.description,
    this.tag,
    this.recommendation,
    this.badgeColor,
  });

  final IconData icon;
  final String? tag; // e.g. 'PROTEIN INTAKE'
  final String title;
  final String description;
  final String? recommendation;
  final Color? badgeColor;
}

class InsightsState {
  const InsightsState({
    required this.period,
    required this.isEmpty,
    required this.averageCalories,
    required this.targetCalories,
    required this.calorieHistory,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.smartInsights,
    required this.loggedDaysCount,
    this.totalDaysCount = 7,
    this.isDemoMode = false,
  });

  final InsightsPeriod period;
  final bool isEmpty;
  final double averageCalories;
  final double targetCalories;
  final List<DailyCalorieData> calorieHistory;
  final MacroInsightItem protein;
  final MacroInsightItem carbs;
  final MacroInsightItem fat;
  final List<SmartInsightItem> smartInsights;
  final int loggedDaysCount;
  final int totalDaysCount;
  final bool isDemoMode;

  double get calorieDifference => averageCalories - targetCalories;
  bool get isBelowTarget => calorieDifference < -25;
  bool get isAboveTarget => calorieDifference > 25;
  bool get isOnTarget => !isBelowTarget && !isAboveTarget;

  double get calorieProgress =>
      targetCalories <= 0 ? 0.0 : (averageCalories / targetCalories);
  int get caloriePercentage => (calorieProgress * 100).round();

  InsightsState copyWith({
    InsightsPeriod? period,
    bool? isEmpty,
    double? averageCalories,
    double? targetCalories,
    List<DailyCalorieData>? calorieHistory,
    MacroInsightItem? protein,
    MacroInsightItem? carbs,
    MacroInsightItem? fat,
    List<SmartInsightItem>? smartInsights,
    int? loggedDaysCount,
    int? totalDaysCount,
    bool? isDemoMode,
  }) {
    return InsightsState(
      period: period ?? this.period,
      isEmpty: isEmpty ?? this.isEmpty,
      averageCalories: averageCalories ?? this.averageCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      calorieHistory: calorieHistory ?? this.calorieHistory,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      smartInsights: smartInsights ?? this.smartInsights,
      loggedDaysCount: loggedDaysCount ?? this.loggedDaysCount,
      totalDaysCount: totalDaysCount ?? this.totalDaysCount,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}
