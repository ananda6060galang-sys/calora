enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Goal { loseWeight, maintainWeight, gainMuscle, leanBulk }

class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    this.isAdmin = false,
  });

  final String name;
  final int age;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final Goal goal;
  final bool isAdmin;

  /// Mifflin-St Jeor BMR, adjusted by activity factor and goal offset.
  double get dailyCalorieTarget {
    final bmr = gender == Gender.male
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;

    const factors = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.light: 1.375,
      ActivityLevel.moderate: 1.55,
      ActivityLevel.active: 1.725,
      ActivityLevel.veryActive: 1.9,
    };

    final tdee = bmr * (factors[activityLevel] ?? 1.2);

    switch (goal) {
      case Goal.loseWeight:
        return tdee - 500;
      case Goal.maintainWeight:
        return tdee;
      case Goal.gainMuscle:
        return tdee + 250;
      case Goal.leanBulk:
        return tdee + 400;
    }
  }

  double get proteinTargetG => weightKg * 1.8;
  double get fatTargetG => (dailyCalorieTarget * 0.25) / 9;
  double get carbsTargetG =>
      (dailyCalorieTarget - (proteinTargetG * 4) - (fatTargetG * 9)) / 4;
}
