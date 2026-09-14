import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/insights_state.dart';

class MealDistributionCard extends StatelessWidget {
  const MealDistributionCard({
    super.key,
    required this.items,
    required this.isDark,
  });

  final List<MealDistributionItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.72)
        : const Color(0xFFE9ECEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1E2022);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'insights.mealPattern'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${items.length} meals',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thick segmented bar (12px height)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 12,
              width: double.infinity,
              child: Row(
                children: items.map((item) {
                  return Expanded(
                    flex: (item.percentage * 10).round(),
                    child: Container(
                      color: item.color,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Meal row pills
          for (final item in items) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                      : const Color(0xFFE9ECEF),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _mealTypeLabel(item.mealType),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.calories} kcal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: isDark ? 0.2 : 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${item.percentage.round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E2022),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'diary.breakfast'.tr();
      case 'lunch':
        return 'diary.lunch'.tr();
      case 'dinner':
        return 'diary.dinner'.tr();
      case 'snack':
      case 'snacks':
        return 'diary.snack'.tr();
      default:
        return mealType;
    }
  }
}
