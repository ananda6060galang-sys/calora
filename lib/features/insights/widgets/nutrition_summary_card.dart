import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// The signature Nutrition AI Summary card from the visual benchmark.
/// Features:
/// - Editorial "Nutrition AI Summary" header with leaf icon
/// - Central circular progress arc with total kcal flanked by consumed and target
/// - Three clean horizontal macro progress bars (Carbs, Protein, Fat)
/// - Motivational editorial status copy
/// - Dark botanical green action pill button
class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    super.key,
    required this.consumedCalories,
    required this.targetCalories,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.fatConsumed,
    required this.fatTarget,
    required this.insightMessage,
    this.ctaLabel = "See Today's Insights",
    required this.isDark,
    this.onActionTap,
  });

  final int consumedCalories;
  final double targetCalories;
  final double carbsConsumed;
  final double carbsTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final double fatConsumed;
  final double fatTarget;
  final String insightMessage;
  final String ctaLabel;
  final bool isDark;
  final VoidCallback? onActionTap;

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
        ? AppColors.darkBorder.withValues(alpha: 0.70)
        : const Color(0xFFEBECEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF131814);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);

    final targetCals = targetCalories > 0 ? targetCalories : 2100.0;
    final progress = targetCals > 0
        ? (consumedCalories / targetCals).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HEADER: Minimal Line-art Leaf Icon + "Nutrition AI Summary" ──
          Row(
            children: [
              Icon(
                Icons.eco_outlined,
                size: 19,
                color: isDark ? AppColors.accent : const Color(0xFF266E44),
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition AI Summary',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(height: 1, thickness: 0.8, color: borderColor),
          const SizedBox(height: 24),

          // ── 2. CIRCULAR ARC GAUGE FLANKED BY CONSUMED & TARGET ────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Consumed
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatWithComma(consumedCalories),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'consumed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Center: Circular Arc Progress Meter
              SizedBox(
                width: 135,
                height: 135,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(135, 135),
                      painter: _ArcProgressPainter(
                        progress: progress,
                        isDark: isDark,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatWithComma(consumedCalories),
                          style: GoogleFonts.inter(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kcal total',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Target
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatWithComma(targetCals.round()),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'target',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ── 3. THREE MACRO HORIZONTAL PROGRESS BARS ─────────────────
          Row(
            children: [
              Expanded(
                child: _MacroBarItem(
                  label: 'Carbohydrates',
                  currentG: carbsConsumed.round(),
                  targetG: carbsTarget.round(),
                  color: AppColors.carbs,
                  isDark: isDark,
                  textSecondary: textSecondary,
                  textPrimary: textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroBarItem(
                  label: 'Protein',
                  currentG: proteinConsumed.round(),
                  targetG: proteinTarget.round(),
                  color: AppColors.protein,
                  isDark: isDark,
                  textSecondary: textSecondary,
                  textPrimary: textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroBarItem(
                  label: 'Fat',
                  currentG: fatConsumed.round(),
                  targetG: fatTarget.round(),
                  color: AppColors.fat,
                  isDark: isDark,
                  textSecondary: textSecondary,
                  textPrimary: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── 4. SHORT DAILY NUTRITION INSIGHT ────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                insightMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── 5. ACTION CTA BUTTON (Matching Reference) ─────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E3A2B)
                    : const Color(0xFF17382B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                ctaLabel,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBarItem extends StatelessWidget {
  const _MacroBarItem({
    required this.label,
    required this.currentG,
    required this.targetG,
    required this.color,
    required this.isDark,
    required this.textSecondary,
    required this.textPrimary,
  });

  final String label;
  final int currentG;
  final int targetG;
  final Color color;
  final bool isDark;
  final Color textSecondary;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    final ratio = targetG > 0 ? (currentG / targetG).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222B22) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$currentG/${targetG}g',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ArcProgressPainter extends CustomPainter {
  const _ArcProgressPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 8.5;
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track circle
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF202A21) : const Color(0xFFEBECEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc progress
    const startAngle = -math.pi / 2;
    final progressSweep = 2 * math.pi * progress;
    if (progressSweep > 0.01) {
      final activePaint = Paint()
        ..color = isDark ? AppColors.accent : const Color(0xFF1B3D2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, progressSweep, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
