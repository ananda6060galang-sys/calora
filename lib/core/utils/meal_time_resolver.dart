import 'package:flutter/material.dart';

/// Calora Smart Meal Time Resolver
///
/// Determines the appropriate meal category (Breakfast, Lunch, Dinner, Snack)
/// based on the local system time or preserves an explicitly requested meal.
class MealTimeResolver {
  const MealTimeResolver._();

  static const List<String> standardMeals = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  /// Resolves the meal category. If [requestedMeal] is provided and valid,
  /// it is preserved. Otherwise, it calculates the meal based on [time] (or [DateTime.now()]).
  static String resolveCurrentMeal({
    String? requestedMeal,
    DateTime? time,
  }) {
    if (requestedMeal != null && requestedMeal.trim().isNotEmpty) {
      final trimmed = requestedMeal.trim().toLowerCase();
      for (final m in standardMeals) {
        if (m.toLowerCase() == trimmed) {
          return m;
        }
      }
    }

    final targetTime = time ?? DateTime.now();
    final hour = targetTime.hour;

    // 04:00 - 10:59: Breakfast
    if (hour >= 4 && hour < 11) {
      return 'Breakfast';
    }
    // 11:00 - 15:59: Lunch
    if (hour >= 11 && hour < 16) {
      return 'Lunch';
    }
    // 16:00 - 17:59: Afternoon Snack
    if (hour >= 16 && hour < 18) {
      return 'Snack';
    }
    // 18:00 - 23:59: Dinner
    if (hour >= 18 && hour <= 23) {
      return 'Dinner';
    }
    // 00:00 - 03:59: Late Night Snack
    return 'Snack';
  }

  /// Returns the corresponding localization key for the meal.
  static String getMealLocalizationKey(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return 'diary.breakfast';
      case 'lunch':
        return 'diary.lunch';
      case 'dinner':
        return 'diary.dinner';
      case 'snack':
      default:
        return 'diary.snack';
    }
  }

  /// Returns the appropriate icon for the meal category.
  static IconData getMealIcon(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.light_mode_outlined;
      case 'dinner':
        return Icons.nightlight_round_outlined;
      case 'snack':
      default:
        return Icons.cookie_outlined;
    }
  }

  /// Returns a short time-of-day greeting/label in Indonesian or English.
  static String getMealSubtitle(String meal, {bool isIndonesian = true}) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return isIndonesian ? '04:00 - 11:00 WIB' : '4:00 AM - 11:00 AM';
      case 'lunch':
        return isIndonesian ? '11:00 - 16:00 WIB' : '11:00 AM - 4:00 PM';
      case 'dinner':
        return isIndonesian ? '18:00 - 23:59 WIB' : '6:00 PM - 11:59 PM';
      case 'snack':
      default:
        return isIndonesian ? 'Camilan Sehat' : 'Healthy Snacks';
    }
  }
}
