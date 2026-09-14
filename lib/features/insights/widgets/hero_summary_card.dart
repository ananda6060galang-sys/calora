import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/insights_state.dart';

class HeroSummaryCard extends StatelessWidget {
  const HeroSummaryCard({
    super.key,
    required this.period,
    required this.averageCalories,
    required this.targetCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isDark,
  });

  final InsightsPeriod period;
  final double averageCalories;
  final double targetCalories;
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
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.72)
        : const Color(0xFFE9ECEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1E2022);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF758273);

    final periodLabel = period == InsightsPeriod.week
        ? 'insights.thisWeek'.tr()
        : 'insights.thisMonth'.tr();

    // Macro proportions
    final totalMacroG = (protein.currentG + carbs.currentG + fat.currentG)
        .clamp(1.0, 9999.0);
    final proteinRatio = protein.currentG / totalMacroG;
    final carbsRatio = carbs.currentG / totalMacroG;
    final fatRatio = fat.currentG / totalMacroG;

    final targetPercentage = targetCalories > 0
        ? (averageCalories / targetCalories * 100).clamp(0, 999).round()
        : 0;

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
        children: [
          // Header row: Period tag & Target badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFDCEDC8),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      periodLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: isDark ? 0.2 : 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$targetPercentage% Target',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.accent : const Color(0xFF2E5316),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // DONUT RING VISUAL WITH FLOATING PERCENTAGE PILLS
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom painted chunky multi-segment donut ring
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _MacroDonutPainter(
                    proteinRatio: proteinRatio,
                    carbsRatio: carbsRatio,
                    fatRatio: fatRatio,
                    isDark: isDark,
                  ),
                ),

                // Center Calorie Info
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatWithComma(averageCalories.round()),
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'kcal / day',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),

                // Floating Pill: Protein (top-left)
                Positioned(
                  left: 6,
                  top: 20,
                  child: _FloatingMacroBadge(
                    label: 'Protein',
                    percentage: (proteinRatio * 100).round(),
                    color: AppColors.protein,
                    isDark: isDark,
                  ),
                ),

                // Floating Pill: Carbs (top-right)
                Positioned(
                  right: 6,
                  top: 20,
                  child: _FloatingMacroBadge(
                    label: 'Carbs',
                    percentage: (carbsRatio * 100).round(),
                    color: AppColors.carbs,
                    isDark: isDark,
                  ),
                ),

                // Floating Pill: Fat (bottom-right)
                Positioned(
                  right: 18,
                  bottom: 10,
                  child: _FloatingMacroBadge(
                    label: 'Fat',
                    percentage: (fatRatio * 100).round(),
                    color: AppColors.fat,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Bottom 3 Macro Pills (Capsules with gram counts)
          Row(
            children: [
              Expanded(
                child: _MacroCapsule(
                  label: 'Protein',
                  grams: '${protein.currentG.round()}g',
                  targetG: '${protein.targetG.round()}g',
                  color: AppColors.protein,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroCapsule(
                  label: 'Carbs',
                  grams: '${carbs.currentG.round()}g',
                  targetG: '${carbs.targetG.round()}g',
                  color: AppColors.carbs,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroCapsule(
                  label: 'Fat',
                  grams: '${fat.currentG.round()}g',
                  targetG: '${fat.targetG.round()}g',
                  color: AppColors.fat,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingMacroBadge extends StatelessWidget {
  const _FloatingMacroBadge({
    required this.label,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int percentage;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE9ECEF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$percentage%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E2022),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCapsule extends StatelessWidget {
  const _MacroCapsule({
    required this.label,
    required this.grams,
    required this.targetG,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String grams;
  final String targetG;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF8F9FB);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE9ECEF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            grams,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E2022),
            ),
          ),
          Text(
            '/ $targetG',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextTertiary : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  const _MacroDonutPainter({
    required this.proteinRatio,
    required this.carbsRatio,
    required this.fatRatio,
    required this.isDark,
  });

  final double proteinRatio;
  final double carbsRatio;
  final double fatRatio;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 16.0;
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track ring
    final trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF222B22)
          : const Color(0xFFF1F4EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Segment gap angle
    const gap = 0.08; // radians
    const startOffset = -math.pi / 2; // start from top (12 o'clock)

    final ratios = [proteinRatio, carbsRatio, fatRatio];
    final colors = [AppColors.protein, AppColors.carbs, AppColors.fat];

    double currentAngle = startOffset;

    for (int i = 0; i < ratios.length; i++) {
      final sweep = (ratios[i] * 2 * math.pi) - gap;
      if (sweep <= 0) continue;

      final segmentPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, currentAngle + (gap / 2), sweep, false, segmentPaint);
      currentAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter oldDelegate) =>
      oldDelegate.proteinRatio != proteinRatio ||
      oldDelegate.carbsRatio != carbsRatio ||
      oldDelegate.fatRatio != fatRatio ||
      oldDelegate.isDark != isDark;
}
