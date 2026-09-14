import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class MacroBreakdownCard extends StatelessWidget {
  const MacroBreakdownCard({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isDark,
  });

  final MacroInsightItem protein;
  final MacroInsightItem carbs;
  final MacroInsightItem fat;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);
    final borderColor =
        isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFEBECEF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'MACRO PROGRESS',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Protein Target
        _FactorRowItem(
          icon: Icons.fitness_center_rounded,
          iconColor: AppColors.protein,
          name: 'Protein',
          progress: protein.progress,
          barColor: AppColors.protein,
          value: '${protein.currentG.round()} / ${protein.targetG.round()} g',
          status: protein.progress >= 0.85 ? 'Good' : 'Moderate',
          isDark: isDark,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Container(height: 0.5, color: borderColor),
        ),

        // 2. Carb Balance
        _FactorRowItem(
          icon: Icons.grain_rounded,
          iconColor: AppColors.carbs,
          name: 'Carbohydrates',
          progress: carbs.progress,
          barColor: AppColors.carbs,
          value: '${carbs.currentG.round()} / ${carbs.targetG.round()} g',
          status: carbs.progress >= 0.85 ? 'Good' : 'Moderate',
          isDark: isDark,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Container(height: 0.5, color: borderColor),
        ),

        // 3. Fat Balance (Using egg icon per rule)
        _FactorRowItem(
          icon: Icons.egg_rounded,
          iconColor: AppColors.fat,
          name: 'Fat',
          progress: fat.progress,
          barColor: AppColors.fat,
          value: '${fat.currentG.round()} / ${fat.targetG.round()} g',
          status: fat.progress >= 0.8 ? 'Good' : 'Moderate',
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Single-line factor row matching the reference image 1:1:
/// [Icon]  [Name]  [━━━━━━━   ]  [Value]  [Status]
class _FactorRowItem extends StatelessWidget {
  const _FactorRowItem({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.progress,
    required this.barColor,
    required this.value,
    required this.status,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final double progress;
  final Color barColor;
  final String value;
  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111613);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF6B776E);
    final trackColor = isDark
        ? const Color(0xFF1E2620)
        : const Color(0xFFF0F2ED);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Icon
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 10),

        // 2. Name
        SizedBox(
          width: 95,
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // 3. Slim Progress Bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 4.0,
              color: trackColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth =
                      constraints.maxWidth * progress.clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: fillWidth,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 4. Value
        SizedBox(
          width: 36,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 5. Status
        SizedBox(
          width: 55,
          child: Text(
            status,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
