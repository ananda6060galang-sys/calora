import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

/// The desktop reference shows four equal-width stat blocks in a single
/// row with a soft icon badge, a big number, and a trend line. On mobile
/// that row doesn't fit without shrinking everything into illegible text,
/// so this becomes a horizontally scrollable set of taller cards instead —
/// same visual language (rounded badge, bold number, small label), but each
/// card gets room to breathe and stays thumb-scannable one at a time.
class NutrientStatCard extends StatelessWidget {
  const NutrientStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    this.sublabel,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 148,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isDark
            ? Border.all(color: AppColors.darkBorder)
            : Border.all(color: AppColors.lightBorder),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge,
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(sublabel!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}
