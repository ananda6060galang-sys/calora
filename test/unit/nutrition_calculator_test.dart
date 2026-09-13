import 'package:flutter_test/flutter_test.dart';
import 'package:calora/core/utils/age_calculator.dart';
import 'package:calora/core/utils/nutrition_calculator.dart';
import 'package:calora/models/user_profile.dart';
import 'package:calora/core/services/profile_service.dart';

void main() {
  group('Phase 6A: Nutrition & Target System Unit Tests', () {
    // 1. Male BMR (Mifflin-St Jeor): 10W + 6.25H - 5A + 5
    test('1. Male BMR calculation via Mifflin-St Jeor', () {
      final bmr = NutritionCalculator.calculateBmr(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 25,
        gender: Gender.male,
      );
      // 10(70) + 6.25(175) - 5(25) + 5 = 700 + 1093.75 - 125 + 5 = 1673.75
      expect(bmr, closeTo(1673.75, 0.01));
    });

    // 2. Female BMR (Mifflin-St Jeor): 10W + 6.25H - 5A - 161
    test('2. Female BMR calculation via Mifflin-St Jeor', () {
      final bmr = NutritionCalculator.calculateBmr(
        weightKg: 60.0,
        heightCm: 165.0,
        age: 25,
        gender: Gender.female,
      );
      // 10(60) + 6.25(165) - 5(25) - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      expect(bmr, closeTo(1345.25, 0.01));
    });

    // 3. Different activity levels
    test('3. Activity level multipliers on TDEE', () {
      const bmr = 1500.0;
      expect(
        NutritionCalculator.calculateTdee(bmr: bmr, activityLevel: ActivityLevel.sedentary),
        closeTo(1500.0 * 1.2, 0.01),
      );
      expect(
        NutritionCalculator.calculateTdee(bmr: bmr, activityLevel: ActivityLevel.light),
        closeTo(1500.0 * 1.375, 0.01),
      );
      expect(
        NutritionCalculator.calculateTdee(bmr: bmr, activityLevel: ActivityLevel.moderate),
        closeTo(1500.0 * 1.55, 0.01),
      );
      expect(
        NutritionCalculator.calculateTdee(bmr: bmr, activityLevel: ActivityLevel.active),
        closeTo(1500.0 * 1.725, 0.01),
      );
      expect(
        NutritionCalculator.calculateTdee(bmr: bmr, activityLevel: ActivityLevel.veryActive),
        closeTo(1500.0 * 1.9, 0.01),
      );
    });

    // 4. Lose + Gentle (-250 kcal)
    test('4. Lose Weight + Gentle pace applies -250 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2200,
        bmr: 1500,
        goal: Goal.loseWeight,
        goalPace: GoalPace.gentle,
      );
      expect(target, equals(1950.0));
    });

    // 5. Lose + Moderate (-500 kcal)
    test('5. Lose Weight + Moderate pace applies -500 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2200,
        bmr: 1500,
        goal: Goal.loseWeight,
        goalPace: GoalPace.moderate,
      );
      expect(target, equals(1700.0));
    });

    // 6. Lose + Faster (-750 kcal)
    test('6. Lose Weight + Faster pace applies -750 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2400,
        bmr: 1500,
        goal: Goal.loseWeight,
        goalPace: GoalPace.faster,
      );
      expect(target, equals(1650.0));
    });

    // 7. Maintain (0 kcal offset)
    test('7. Maintain Weight applies 0 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2000,
        bmr: 1500,
        goal: Goal.maintainWeight,
      );
      expect(target, equals(2000.0));
    });

    // 8. Gain + Gentle (+250 kcal)
    test('8. Gain Weight + Gentle pace applies +250 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2000,
        bmr: 1500,
        goal: Goal.gainWeight,
        goalPace: GoalPace.gentle,
      );
      expect(target, equals(2250.0));
    });

    // 9. Gain + Moderate (+500 kcal)
    test('9. Gain Weight + Moderate pace applies +500 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2000,
        bmr: 1500,
        goal: Goal.gainWeight,
        goalPace: GoalPace.moderate,
      );
      expect(target, equals(2500.0));
    });

    // 10. Gain + Faster (+750 kcal)
    test('10. Gain Weight + Faster pace applies +750 kcal offset', () {
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2000,
        bmr: 1500,
        goal: Goal.gainWeight,
        goalPace: GoalPace.faster,
      );
      expect(target, equals(2750.0));
    });

    // 11. BMR floor clamp (Critical rule)
    test('11. Critical BMR Floor: Daily calorie target NEVER drops below BMR', () {
      // Prompt example: 50kg female, BMR = 1250, TDEE = 1500, Moderate deficit = -500.
      // Raw: 1500 - 500 = 1000. Clamped target must be: 1250.
      final target = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 1500,
        bmr: 1250,
        goal: Goal.loseWeight,
        goalPace: GoalPace.moderate,
      );
      expect(target, equals(1250.0));

      // Faster deficit: 1500 - 750 = 750. Clamped target must still be: 1250.
      final targetFaster = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 1500,
        bmr: 1250,
        goal: Goal.loseWeight,
        goalPace: GoalPace.faster,
      );
      expect(targetFaster, equals(1250.0));
    });

    // 12. Custom target below BMR
    test('12. Custom Calorie Target is clamped to >= BMR in domain calculator', () {
      final targetClamped = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2000,
        bmr: 1400,
        goal: Goal.maintainWeight,
        customCalorieTarget: 1100, // Below BMR
      );
      expect(targetClamped, equals(1400.0));

      final targetValid = NutritionCalculator.calculateDailyCalorieTarget(
        tdee: 2000,
        bmr: 1400,
        goal: Goal.maintainWeight,
        customCalorieTarget: 1800, // Valid >= BMR
      );
      expect(targetValid, equals(1800.0));
    });

    // 13. Macro consistency: 4*P + 9*F + 4*C == calorieTarget
    test('13. Macro calculations are mathematically consistent with calorie target', () {
      const calorieTarget = 2000.0;
      const weightKg = 70.0;
      final macros = NutritionCalculator.calculateMacros(
        calorieTarget: calorieTarget,
        weightKg: weightKg,
      );

      // Protein = 1.8 * 70 = 126g -> 504 kcal
      expect(macros.proteinG, equals(126.0));

      // Fat = 25% of 2000 = 500 kcal / 9 = 55.555...g
      expect(macros.fatG, closeTo(55.555, 0.01));

      // Remaining = 2000 - 504 - 500 = 996 kcal / 4 = 249g
      expect(macros.carbsG, equals(249.0));

      final totalEnergy =
          (macros.proteinG * 4.0) + (macros.fatG * 9.0) + (macros.carbsG * 4.0);
      expect(totalEnergy, closeTo(calorieTarget, 0.01));
    });

    // 14. Age derived dynamically from date_of_birth
    test('14. Age is derived strictly and dynamically from dateOfBirth', () {
      final now = DateTime.now();
      final dob20YearsAgo = DateTime(now.year - 20, now.month, now.day);
      expect(calculateAge(dob20YearsAgo), equals(20));

      final profile = UserProfile(
        name: 'Alex',
        dateOfBirth: dob20YearsAgo,
        gender: Gender.male,
        heightCm: 180,
        weightKg: 75,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintainWeight,
      );
      expect(profile.age, equals(20));
    });

    // 15. Legacy goal mapping
    test('15. Supabase ProfileService preserves backward compatibility for legacy goals', () {
      expect(ProfileService.goalFromDb('gain_muscle'), equals(Goal.gainWeight));
      expect(ProfileService.goalFromDb('gainMuscle'), equals(Goal.gainWeight));
      expect(ProfileService.goalFromDb('lean_bulk'), equals(Goal.gainWeight));
      expect(ProfileService.goalFromDb('leanBulk'), equals(Goal.gainWeight));
      expect(ProfileService.goalFromDb('gain_weight'), equals(Goal.gainWeight));
      expect(ProfileService.goalFromDb('gainWeight'), equals(Goal.gainWeight));
      expect(ProfileService.goalFromDb('lose_weight'), equals(Goal.loseWeight));
      expect(ProfileService.goalFromDb('maintain_weight'), equals(Goal.maintainWeight));
      expect(ProfileService.goalFromDb('unknown_value'), equals(Goal.maintainWeight));
    });

    // 16. Target weight validation & UserProfile integration
    test('16. Target Weight handling and UserProfile model integration', () {
      final profile = UserProfile(
        name: 'Jordan',
        dateOfBirth: DateTime(1995, 8, 20),
        gender: Gender.female,
        heightCm: 165,
        weightKg: 65,
        activityLevel: ActivityLevel.light,
        goal: Goal.loseWeight,
        targetWeightKg: 58.0,
        goalPace: GoalPace.moderate,
      );

      expect(profile.targetWeightKg, equals(58.0));
      expect(profile.goalPace, equals(GoalPace.moderate));
      expect(profile.bmr, greaterThan(0));
      expect(profile.tdee, greaterThan(profile.bmr));
      expect(profile.dailyCalorieTarget, greaterThanOrEqualTo(profile.bmr));
      expect(profile.proteinTargetG, equals(65.0 * 1.8));

      // Test copyWith
      final updated = profile.copyWith(
        targetWeightKg: 55.0,
        goalPace: GoalPace.faster,
      );
      expect(updated.targetWeightKg, equals(55.0));
      expect(updated.goalPace, equals(GoalPace.faster));
      expect(updated.name, equals('Jordan'));

      // Validate non-negative / zero guards in NutritionCalculator
      expect(
        NutritionCalculator.calculateBmr(weightKg: 0, heightCm: 165, age: 25, gender: Gender.female),
        equals(0.0),
      );
      expect(
        NutritionCalculator.calculateTdee(bmr: 0, activityLevel: ActivityLevel.moderate),
        equals(0.0),
      );
      expect(
        NutritionCalculator.calculateMacros(calorieTarget: 0, weightKg: 65).proteinG,
        equals(0.0),
      );
    });
  });
}
