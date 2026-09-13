import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';

/// Service responsible for Supabase database operations on the `profiles` table.
class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  /// Fetch user profile from Supabase profiles table.
  /// Returns null if profile does not exist or has incomplete onboarding data.
  Future<UserProfile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    final fullName = response['full_name'] as String?;
    final dobStr = response['date_of_birth'] as String?;
    final genderStr = response['gender'] as String?;
    final heightCm = (response['height_cm'] as num?)?.toDouble();
    final weightKg = (response['weight_kg'] as num?)?.toDouble();
    final activityLevelStr = response['activity_level'] as String?;
    final goalStr = response['goal'] as String?;

    if (fullName == null ||
        fullName.trim().isEmpty ||
        dobStr == null ||
        genderStr == null ||
        heightCm == null ||
        weightKg == null ||
        activityLevelStr == null ||
        goalStr == null) {
      return null;
    }

    final dob = DateTime.tryParse(dobStr);
    if (dob == null) return null;

    final gender = _genderFromDb(genderStr);
    final activityLevel = _activityLevelFromDb(activityLevelStr);
    final goal = goalFromDb(goalStr);
    final targetWeightKg = (response['target_weight_kg'] as num?)?.toDouble();
    final goalPaceStr = response['goal_pace'] as String?;
    final goalPace = _goalPaceFromDb(goalPaceStr);
    final customCalorieTarget = (response['custom_calorie_target'] as num?)?.toDouble();
    final role = response['role'] as String? ?? 'user';

    return UserProfile(
      name: fullName,
      dateOfBirth: dob,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goal: goal,
      targetWeightKg: targetWeightKg,
      goalPace: goalPace,
      customCalorieTarget: customCalorieTarget,
      isAdmin: role == 'admin',
    );
  }

  /// Check if user has already completed onboarding.
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final profile = await getProfile(userId);
      return profile != null;
    } catch (_) {
      return false;
    }
  }

  /// Upsert/Save the authenticated user's profile to Supabase `profiles` table.
  Future<void> saveProfile({
    required String userId,
    required UserProfile profile,
    DateTime? dateOfBirth,
  }) async {
    final effectiveDob = dateOfBirth ?? profile.dateOfBirth;
    final dobFormatted = DateFormat('yyyy-MM-dd').format(effectiveDob);

    final payload = {
      'id': userId,
      'full_name': profile.name,
      'date_of_birth': dobFormatted,
      'gender': profile.gender.name,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'activity_level': _activityLevelToDb(profile.activityLevel),
      'goal': _goalToDb(profile.goal),
      if (profile.targetWeightKg != null) 'target_weight_kg': profile.targetWeightKg,
      'goal_pace': _goalPaceToDb(profile.goalPace),
      if (profile.customCalorieTarget != null)
        'custom_calorie_target': profile.customCalorieTarget,
      'daily_calorie_target': profile.dailyCalorieTarget,
      'protein_target_g': profile.proteinTargetG,
      'carbs_target_g': profile.carbsTargetG,
      'fat_target_g': profile.fatTargetG,
      'role': profile.isAdmin ? 'admin' : 'user',
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('profiles').upsert(payload);
  }

  /// Helper to convert ActivityLevel enum to DB string matching CHECK constraint.
  static String _activityLevelToDb(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'sedentary';
      case ActivityLevel.light:
        return 'light';
      case ActivityLevel.moderate:
        return 'moderate';
      case ActivityLevel.active:
        return 'active';
      case ActivityLevel.veryActive:
        return 'very_active';
    }
  }

  /// Helper to convert DB string to ActivityLevel enum.
  static ActivityLevel _activityLevelFromDb(String value) {
    switch (value) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.light;
      case 'moderate':
        return ActivityLevel.moderate;
      case 'active':
        return ActivityLevel.active;
      case 'very_active':
      case 'veryActive':
        return ActivityLevel.veryActive;
      default:
        return ActivityLevel.moderate;
    }
  }

  /// Helper to convert Goal enum to DB string matching CHECK constraint.
  static String _goalToDb(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'lose_weight';
      case Goal.maintainWeight:
        return 'maintain_weight';
      case Goal.gainWeight:
        return 'gain_weight';
    }
  }

  /// Helper to convert DB string to Goal enum (with legacy backward compatibility).
  static Goal goalFromDb(String value) {
    switch (value) {
      case 'lose_weight':
      case 'loseWeight':
        return Goal.loseWeight;
      case 'maintain_weight':
      case 'maintainWeight':
        return Goal.maintainWeight;
      case 'gain_weight':
      case 'gainWeight':
      case 'gain_muscle':
      case 'gainMuscle':
      case 'lean_bulk':
      case 'leanBulk':
        return Goal.gainWeight;
      default:
        return Goal.maintainWeight;
    }
  }

  /// Helper to convert GoalPace to DB string.
  static String _goalPaceToDb(GoalPace pace) {
    return pace.name;
  }

  /// Helper to convert DB string to GoalPace enum.
  static GoalPace _goalPaceFromDb(String? value) {
    switch (value) {
      case 'gentle':
        return GoalPace.gentle;
      case 'faster':
        return GoalPace.faster;
      case 'moderate':
      default:
        return GoalPace.moderate;
    }
  }

  /// Helper to convert DB string to Gender enum.
  static Gender _genderFromDb(String value) {
    return value.toLowerCase() == 'female' ? Gender.female : Gender.male;
  }
}
