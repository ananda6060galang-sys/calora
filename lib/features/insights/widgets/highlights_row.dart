import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class HighlightsRow extends StatelessWidget {
  const HighlightsRow({
    super.key,
    required this.averageCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isDark,
  });

  final double averageCalories;
  final MacroInsightItem protein;
  final MacroInsightItem carbs;
  final MacroInsightItem fat;
  final bool isDark;

  String _formatWithComma(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (Matching reference "TODAY'S HIGHLIGHTS")
        Text(
          "THIS WEEK'S NUTRITION",
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // 4 Compact Cards Row (Matching reference proportions)
        Row(
          children: [
            // Card 1: Average Calories
            Expanded(
              child: _HighlightCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: isDark ? AppColors.accent : const Color(0xFF65A30D),
                value: _formatWithComma(averageCalories.round()),
                unit: 'kcal',
                label: 'CALORIES',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Protein
            Expanded(
              child: _HighlightCard(
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.protein,
                value: '${protein.currentG.round()}',
                unit: 'g',
                label: 'PROTEIN',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Card 3: Carbs
            Expanded(
              child: _HighlightCard(
                icon: Icons.grain_rounded,
                iconColor: AppColors.carbs,
                value: '${carbs.currentG.round()}',
                unit: 'g',
                label: 'CARBS',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Card 4: Fat (Egg icon per AGENTS.md, never water droplet)
            Expanded(
              child: _HighlightCard(
                icon: Icons.egg_rounded,
                iconColor: AppColors.fat,
                value: '${fat.currentG.round()}',
                unit: 'g',
                label: 'FAT',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFEBECEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111613);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF94A096);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.9),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Icon (Matching reference centered layout)
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(height: 8),

          // 2. Value + unit (FittedBox prevents ANY overflow)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Label (e.g. CALORIES / PROTEIN)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: textTertiary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
