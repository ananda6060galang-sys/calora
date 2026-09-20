import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import '../../models/user_profile.dart';

/// Centralized validator utility to enforce PRD Chapter 9 business rules:
/// - No negative numeric values anywhere.
/// - Human biometrics constrained to physiologically realistic limits.
/// - Logical consistency between Goal and Target Weight.
/// - Meal servings and nutrient quantities constrained to realistic bounds.
class InputValidators {
  InputValidators._();

  // Biometric limits
  static const double minHeightCm = 90.0;
  static const double maxHeightCm = 250.0;
  static const double minWeightKg = 25.0;
  static const double maxWeightKg = 300.0;

  // Food & nutrition limits
  static const double minServing = 0.1;
  static const double maxServing = 50.0;
  static const int maxCalories = 5000;
  static const double maxMacroGrams = 500.0;
  static const double maxPortionGrams = 5000.0;

  /// Input formatter to strictly prevent negative signs and invalid characters.
  static final TextInputFormatter decimalFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

  /// Input formatter for positive integer values.
  static final TextInputFormatter integerFormatter =
      FilteringTextInputFormatter.digitsOnly;

  /// Validates height in cm.
  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(',', '.');
    final val = double.tryParse(cleaned);
    if (val == null) {
      return 'validation.invalidNumber'.tr();
    }
    if (val < minHeightCm || val > maxHeightCm) {
      return 'validation.heightRange'.tr(
        args: ['${minHeightCm.round()}', '${maxHeightCm.round()}'],
      );
    }
    return null;
  }

  /// Validates weight in kg.
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(',', '.');
    final val = double.tryParse(cleaned);
    if (val == null) {
      return 'validation.invalidNumber'.tr();
    }
    if (val < minWeightKg || val > maxWeightKg) {
      return 'validation.weightRange'.tr(
        args: ['${minWeightKg.round()}', '${maxWeightKg.round()}'],
      );
    }
    return null;
  }

  /// Validates target weight in relation to user goal and current weight.
  static String? validateTargetWeight({
    required String? targetWeightStr,
    required double? currentWeight,
    required Goal goal,
  }) {
    if (goal == Goal.maintainWeight) return null;
    if (targetWeightStr == null || targetWeightStr.trim().isEmpty) return null;

    final cleaned = targetWeightStr.trim().replaceAll(',', '.');
    final tw = double.tryParse(cleaned);
    if (tw == null) {
      return 'validation.invalidNumber'.tr();
    }
    if (tw < minWeightKg || tw > maxWeightKg) {
      return 'validation.weightRange'.tr(
        args: ['${minWeightKg.round()}', '${maxWeightKg.round()}'],
      );
    }

    if (currentWeight != null && currentWeight > 0) {
      if (goal == Goal.loseWeight && tw >= currentWeight) {
        return 'validation.targetMustBeLower'.tr(
          args: [currentWeight.toStringAsFixed(1)],
        );
      }
      if (goal == Goal.gainWeight && tw <= currentWeight) {
        return 'validation.targetMustBeHigher'.tr(
          args: [currentWeight.toStringAsFixed(1)],
        );
      }
    }
    return null;
  }

  /// Validates food servings.
  static String? validateServing(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(',', '.');
    final val = double.tryParse(cleaned);
    if (val == null || val <= 0) {
      return 'validation.servingPositive'.tr();
    }
    if (val < minServing || val > maxServing) {
      return 'validation.servingRange'.tr(
        args: ['$minServing', '${maxServing.round()}'],
      );
    }
    return null;
  }

  /// Validates calories per serving.
  static String? validateCalories(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(',', '.');
    final val = int.tryParse(cleaned);
    if (val == null || val < 0) {
      return 'validation.invalidNumber'.tr();
    }
    if (val > maxCalories) {
      return 'validation.caloriesMax'.tr(args: ['$maxCalories']);
    }
    return null;
  }

  /// Validates macronutrient grams (protein, carbs, fat).
  static String? validateMacro(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(',', '.');
    final val = double.tryParse(cleaned);
    if (val == null || val < 0) {
      return 'validation.invalidNumber'.tr();
    }
    if (val > maxMacroGrams) {
      return 'validation.macroMax'.tr(args: ['${maxMacroGrams.round()}']);
    }
    return null;
  }
}
