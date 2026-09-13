import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MealTag extends StatelessWidget {
  const MealTag({super.key, required this.meal});

  final String meal;

  static const _colors = {
    'Breakfast': AppColors.mealBreakfast,
    'Lunch': AppColors.mealLunch,
    'Snacks': AppColors.mealSnack,
    'Dinner': AppColors.mealDinner,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[meal] ?? AppColors.mealDinner;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        meal,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
