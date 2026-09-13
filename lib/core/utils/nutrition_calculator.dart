import 'dart:math' as math;
import '../../models/user_profile.dart';

/// Immutable model representing computed macro targets in grams.
class MacroTargets {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

/// Pure domain calculator for Calora's nutrition and metabolic calculations.
///
/// Follows the Mifflin-St Jeor equation and guarantees:
/// 1. Age is derived dynamically from date of birth.
/// 2. Daily calorie target NEVER drops below BMR (clamped).
/// 3. Controlled pace tiers (gentle, moderate, faster) are used instead of arbitrary deficits.
/// 4. Macros are mathematically consistent with daily calorie targets.
class NutritionCalculator {
  NutritionCalculator._();

  /// Mifflin-St Jeor equation for Basal Metabolic Rate (BMR):
  /// - Men: 10 * weight (kg) + 6.25 * height (cm) - 5 * age + 5
  /// - Women: 10 * weight (kg) + 6.25 * height (cm) - 5 * age - 161
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;

    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return gender == Gender.male ? (base + 5.0) : (base - 161.0);
  }

  /// Total Daily Energy Expenditure (TDEE) based on activity multipliers:
  /// - Sedentary: 1.2
  /// - Light: 1.375
  /// - Moderate: 1.55
  /// - Active: 1.725
  /// - Very Active: 1.9
  static double calculateTdee({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    if (bmr <= 0) return 0.0;

    const factors = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.light: 1.375,
      ActivityLevel.moderate: 1.55,
      ActivityLevel.active: 1.725,
      ActivityLevel.veryActive: 1.9,
    };

    final factor = factors[activityLevel] ?? 1.2;
    return bmr * factor;
  }

  /// Daily calorie target computed from TDEE, Goal, and Goal Pace.
  ///
  /// CRITICAL RULE:
  /// The returned daily calorie target must NEVER drop below BMR.
  /// Conceptually: `max(calculatedTarget, BMR)`.
  /// Custom targets are also clamped to at least BMR.
  static double calculateDailyCalorieTarget({
    required double tdee,
    required double bmr,
    required Goal goal,
    GoalPace goalPace = GoalPace.moderate,
    double? customCalorieTarget,
  }) {
    if (bmr <= 0) return 0.0;

    // 1. Custom calorie target strategy (clamped to >= BMR)
    if (customCalorieTarget != null && customCalorieTarget > 0) {
      return math.max(customCalorieTarget, bmr);
    }

    // 2. Automated pace offsets:
    // Gentle: ~250 kcal (estimated ~0.25 kg/week)
    // Moderate: ~500 kcal (estimated ~0.50 kg/week) - Recommended
    // Faster: ~750 kcal (estimated ~0.75 kg/week)
    final double paceOffset;
    switch (goalPace) {
      case GoalPace.gentle:
        paceOffset = 250.0;
        break;
      case GoalPace.moderate:
        paceOffset = 500.0;
        break;
      case GoalPace.faster:
        paceOffset = 750.0;
        break;
    }

    double calculated;
    switch (goal) {
      case Goal.loseWeight:
        calculated = tdee - paceOffset;
        break;
      case Goal.maintainWeight:
        calculated = tdee;
        break;
      case Goal.gainWeight:
        calculated = tdee + paceOffset;
        break;
    }

    // Enforce non-negotiable BMR floor
    return math.max(calculated, bmr);
  }

  /// Macro calculation based on Calora's established nutrition architecture:
  /// - Protein: 1.8g per kg of bodyweight (4 kcal/g)
  /// - Fat: 25% of total calories (9 kcal/g)
  /// - Carbs: Remaining calories (4 kcal/g)
  ///
  /// Mathematically consistent: 4 * Protein + 9 * Fat + 4 * Carbs == Calorie Target.
  static MacroTargets calculateMacros({
    required double calorieTarget,
    required double weightKg,
  }) {
    if (calorieTarget <= 0 || weightKg <= 0) {
      return const MacroTargets(proteinG: 0, carbsG: 0, fatG: 0);
    }

    final proteinG = weightKg * 1.8;
    final proteinKcal = proteinG * 4.0;

    final fatKcal = calorieTarget * 0.25;
    final fatG = fatKcal / 9.0;

    final remainingKcal = calorieTarget - proteinKcal - fatKcal;
    final carbsG = math.max(0.0, remainingKcal / 4.0);

    return MacroTargets(
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  }
}
