import '../core/utils/age_calculator.dart';
import '../core/utils/nutrition_calculator.dart';

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Goal { loseWeight, maintainWeight, gainWeight }

enum GoalPace { gentle, moderate, faster }

class UserProfile {
  const UserProfile({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    this.targetWeightKg,
    this.goalPace = GoalPace.moderate,
    this.customCalorieTarget,
    this.isAdmin = false,
  });

  final String name;
  final DateTime dateOfBirth;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final Goal goal;
  final double? targetWeightKg;
  final GoalPace goalPace;
  final double? customCalorieTarget;
  final bool isAdmin;

  /// Dynamic age calculated strictly from [dateOfBirth].
  int get age => calculateAge(dateOfBirth);

  /// Basal Metabolic Rate (BMR) via Mifflin-St Jeor.
  double get bmr => NutritionCalculator.calculateBmr(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
      );

  /// Total Daily Energy Expenditure (TDEE).
  double get tdee => NutritionCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: activityLevel,
      );

  /// Daily calorie target, clamped to never drop below BMR.
  double get dailyCalorieTarget =>
      NutritionCalculator.calculateDailyCalorieTarget(
        tdee: tdee,
        bmr: bmr,
        goal: goal,
        goalPace: goalPace,
        customCalorieTarget: customCalorieTarget,
      );

  /// Computed macro targets mathematically consistent with [dailyCalorieTarget].
  MacroTargets get macroTargets => NutritionCalculator.calculateMacros(
        calorieTarget: dailyCalorieTarget,
        weightKg: weightKg,
      );

  double get proteinTargetG => macroTargets.proteinG;
  double get carbsTargetG => macroTargets.carbsG;
  double get fatTargetG => macroTargets.fatG;

  bool get isCustomTarget =>
      customCalorieTarget != null && customCalorieTarget! > 0;

  UserProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    Goal? goal,
    double? targetWeightKg,
    GoalPace? goalPace,
    double? customCalorieTarget,
    bool clearCustomCalorieTarget = false,
    bool? isAdmin,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      goalPace: goalPace ?? this.goalPace,
      customCalorieTarget: clearCustomCalorieTarget
          ? null
          : (customCalorieTarget ?? this.customCalorieTarget),
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
