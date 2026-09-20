import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../models/user_profile.dart';
import '../../../models/weight_log.dart';

/// Compact, minimal Apple Health / Dashboard-style weight progress chart.
/// Fully bilingual, clean layout matching Calora's home dashboard cards.
class WeightJourneyChart extends StatelessWidget {
  const WeightJourneyChart({
    super.key,
    required this.logs,
    required this.profile,
    required this.isDark,
    this.onTap,
  });

  final List<WeightLog> logs;
  final UserProfile profile;
  final bool isDark;
  final VoidCallback? onTap;

  String _goalLabel(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'dashboard.goals.loseWeight'.tr();
      case Goal.maintainWeight:
        return 'dashboard.goals.maintainWeight'.tr();
      case Goal.gainWeight:
        return 'dashboard.goals.gainWeight'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF131814);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);
    final cardBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.70)
        : const Color(0xFFEBECEF);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    final firstWeight = logs.first.weightKg;
    final latestWeight = logs.last.weightKg;
    final totalDelta = latestWeight - firstWeight;
    final targetWeight = profile.targetWeightKg ?? profile.weightKg;
    final plan = NutritionCalculator.calculateGoalRoadmap(profile);

    // Trend badge copy & styling (Bilingual)
    final bool isProgressingWell;
    if (profile.goal == Goal.loseWeight) {
      isProgressingWell = totalDelta <= 0;
    } else if (profile.goal == Goal.gainWeight) {
      isProgressingWell = totalDelta >= 0;
    } else {
      isProgressingWell = totalDelta.abs() < 1.0;
    }

    final String trendText;
    final IconData trendIcon;
    if (totalDelta.abs() < 0.1) {
      trendText = 'profile.trendStable'.tr();
      trendIcon = Icons.remove_rounded;
    } else if (totalDelta < 0) {
      trendText =
          'profile.trendDown'.tr(args: [(-totalDelta).toStringAsFixed(1)]);
      trendIcon = Icons.trending_down_rounded;
    } else {
      trendText =
          'profile.trendUp'.tr(args: [totalDelta.toStringAsFixed(1)]);
      trendIcon = Icons.trending_up_rounded;
    }

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Title, Subtitle & Minimal Goal Pill ─────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'profile.weightProgress'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: textTertiary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${latestWeight.toStringAsFixed(1)} kg  ·  ${'profile.target'.tr()}: ${targetWeight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compact Dashboard-style Goal Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : const Color(0xFFF1F4F1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E7E2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      plan.isWeightLoss
                          ? Icons.trending_down_rounded
                          : (plan.isWeightGain
                              ? Icons.trending_up_rounded
                              : Icons.flag_outlined),
                      size: 13,
                      color: isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _goalLabel(profile.goal),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.accent
                            : const Color(0xFF2E6319),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Mini Sparkline Curve Canvas ──────────────────────────────
          RepaintBoundary(
            child: SizedBox(
              height: 95,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightChartPainter(
                  logs: logs,
                  targetWeight: targetWeight,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textTertiary: textTertiary,
                  targetLabel: 'profile.target'.tr(),
                  todayLabel: 'profile.today'.tr(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Bottom Minimal Stats Row ─────────────────────────────────
          Row(
            children: [
              Icon(
                trendIcon,
                size: 13,
                color: isProgressingWell
                    ? (isDark
                        ? AppColors.accent
                        : const Color(0xFF2E6319))
                    : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                trendText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isProgressingWell
                      ? (isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319))
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  color: textTertiary.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'profile.kcalPerDay'.tr(
                  args: [profile.dailyCalorieTarget.round().toString()],
                ),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const Spacer(),
              if (!plan.isMaintenance && plan.estimatedWeeks > 0)
                Text(
                  '~${plan.estimatedWeeks} ${'profile.goalRoadmap.weeksCount'.tr(args: ['']).trim()}',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({
    required this.logs,
    required this.targetWeight,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.targetLabel,
    required this.todayLabel,
  });

  final List<WeightLog> logs;
  final double targetWeight;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final String targetLabel;
  final String todayLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    const topPadding = 18.0;
    const bottomPadding = 16.0;
    const leftPadding = 8.0;
    const rightPadding = 38.0; // Room for target label

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Calculate Y min & max with comfortable breathing room
    double minWeight = targetWeight;
    double maxWeight = targetWeight;
    for (final l in logs) {
      if (l.weightKg < minWeight) minWeight = l.weightKg;
      if (l.weightKg > maxWeight) maxWeight = l.weightKg;
    }

    final double range = math.max(maxWeight - minWeight, 2.5);
    final double yMin = (minWeight - (range * 0.20)).floorToDouble();
    final double yMax = (maxWeight + (range * 0.25)).ceilToDouble();
    final double ySpan = math.max(yMax - yMin, 1.0);

    // ── 1. Target Dashed Guideline ──────────────────────────────────────
    if (targetWeight >= yMin && targetWeight <= yMax) {
      final targetY =
          topPadding + (chartHeight * (1.0 - ((targetWeight - yMin) / ySpan)));

      final targetPaint = Paint()
        ..color = (isDark ? AppColors.accent : const Color(0xFF2E6319))
            .withValues(alpha: 0.55)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;

      const dashWidth = 3.5;
      const dashSpace = 3.0;
      double startX = leftPadding;
      while (startX < leftPadding + chartWidth) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(
              math.min(startX + dashWidth, leftPadding + chartWidth), targetY),
          targetPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Target Label
      final targetLabelPainter = TextPainter(
        text: TextSpan(
          text: targetLabel,
          style: GoogleFonts.inter(
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            color: (isDark ? AppColors.accent : const Color(0xFF2E6319))
                .withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      targetLabelPainter.paint(
        canvas,
        Offset(
          leftPadding + chartWidth + 5,
          targetY - (targetLabelPainter.height / 2),
        ),
      );
    }

    // ── 2. Calculate Coordinate Points ─────────────────────────────────
    final count = logs.length;
    final stepX = count > 1 ? chartWidth / (count - 1) : 0.0;
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      final x = leftPadding + (i * stepX);
      final yRatio = ((logs[i].weightKg - yMin) / ySpan).clamp(0.0, 1.0);
      final y = topPadding + (chartHeight * (1.0 - yRatio));
      points.add(Offset(x, y));
    }

    // ── 3. Smooth Bezier Curve & Soft Fill ──────────────────────────────
    if (points.isNotEmpty) {
      final linePath = Path();
      final fillPath = Path();

      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, topPadding + chartHeight);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

        linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
        fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.close();

      // Soft gradient fill
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                AppColors.accent.withValues(alpha: 0.18),
                const Color(0xFF14B8A6).withValues(alpha: 0.05),
                Colors.transparent,
              ]
            : [
                const Color(0xFF2E6319).withValues(alpha: 0.14),
                const Color(0xFF2E6319).withValues(alpha: 0.02),
                Colors.transparent,
              ],
        stops: const [0.0, 0.6, 1.0],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTRB(
            leftPadding,
            topPadding,
            leftPadding + chartWidth,
            topPadding + chartHeight,
          ),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Line Stroke
      final strokePaint = Paint()
        ..color = isDark ? AppColors.accent : const Color(0xFF1B3D22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, strokePaint);

      // ── 4. Points & Active Endpoint Callout ───────────────────────────
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final isLast = i == points.length - 1;
        final isFirst = i == 0;

        if (isLast) {
          // Highlight halo for latest weight
          final haloPaint = Paint()
            ..color = (isDark ? AppColors.accent : const Color(0xFF2E6319))
                .withValues(alpha: 0.20)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p, 6.0, haloPaint);

          final pinPaint = Paint()
            ..color = isDark ? AppColors.accent : const Color(0xFF1B3D22)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p, 3.5, pinPaint);

          final innerCore = Paint()
            ..color = isDark ? const Color(0xFF0F1410) : Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p, 1.6, innerCore);

          // Compact Floating Callout Pill above the active point
          final pillText = '${logs.last.weightKg.toStringAsFixed(1)} kg';
          final pillPainter = TextPainter(
            text: TextSpan(
              text: pillText,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF0F1410) : Colors.white,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          const pillPaddingH = 5.0;
          const pillPaddingV = 2.0;
          final pillWidth = pillPainter.width + (pillPaddingH * 2);
          final pillHeight = pillPainter.height + (pillPaddingV * 2);
          final pillX = (p.dx - (pillWidth / 2))
              .clamp(leftPadding, leftPadding + chartWidth - pillWidth);
          final pillY = math.max(1.0, p.dy - pillHeight - 6.0);

          final pillRRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(pillX, pillY, pillWidth, pillHeight),
            const Radius.circular(6),
          );

          final pillBgPaint = Paint()
            ..color = isDark ? AppColors.accent : const Color(0xFF1B3D22)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(pillRRect, pillBgPaint);

          pillPainter.paint(
            canvas,
            Offset(pillX + pillPaddingH, pillY + pillPaddingV),
          );
        } else if (isFirst || count <= 5) {
          // Small dot for start or few points
          final dotPaint = Paint()
            ..color = isDark ? const Color(0xFF1B241D) : Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p, 2.4, dotPaint);

          final borderPaint = Paint()
            ..color = isDark ? AppColors.accent : const Color(0xFF2E6319)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawCircle(p, 2.4, borderPaint);
        }

        // ── 5. Bottom Date Labels (Start and End) ─────────────────────────
        if (isFirst || isLast) {
          final dateStr = isLast
              ? todayLabel
              : DateFormat('d MMM').format(logs[i].loggedDate);

          final datePainter = TextPainter(
            text: TextSpan(
              text: dateStr,
              style: GoogleFonts.inter(
                fontSize: 9.0,
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                color: isLast ? textPrimary : textTertiary,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final dateX = (p.dx - (datePainter.width / 2))
              .clamp(leftPadding, leftPadding + chartWidth - datePainter.width);

          datePainter.paint(
            canvas,
            Offset(dateX, topPadding + chartHeight + 4),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.logs != logs ||
      oldDelegate.targetWeight != targetWeight ||
      oldDelegate.isDark != isDark ||
      oldDelegate.targetLabel != targetLabel ||
      oldDelegate.todayLabel != todayLabel;
}
