import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class CalorieOverviewCard extends StatelessWidget {
  const CalorieOverviewCard({
    super.key,
    required this.averageCalories,
    required this.targetCalories,
    required this.history,
    required this.loggedDaysCount,
    required this.isDark,
  });

  final double averageCalories;
  final double targetCalories;
  final List<DailyCalorieData> history;
  final int loggedDaysCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    final intakeLineColor = isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF132E2B); // Refined dark deep teal

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          '7-DAY CALORIE INTAKE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textTertiary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),

        // Large 7-Day Calorie Chart (Directly on canvas with ample room to breathe)
        RepaintBoundary(
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _EditorialCalorieChartPainter(
                history: history,
                targetCalories: targetCalories,
                isDark: isDark,
                intakeLineColor: intakeLineColor,
                targetLineColor: isDark
                    ? AppColors.accent.withValues(alpha: 0.8)
                    : const Color(0xFF7CB81B),
                fillColor: AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.10),
                textColor: textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorialCalorieChartPainter extends CustomPainter {
  const _EditorialCalorieChartPainter({
    required this.history,
    required this.targetCalories,
    required this.isDark,
    required this.intakeLineColor,
    required this.targetLineColor,
    required this.fillColor,
    required this.textColor,
  });

  final List<DailyCalorieData> history;
  final double targetCalories;
  final bool isDark;
  final Color intakeLineColor;
  final Color targetLineColor;
  final Color fillColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const bottomPadding = 32.0;
    const topPadding = 24.0;
    const rightPadding = 48.0; // Space for target reference label
    const leftPadding = 10.0;

    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width - leftPadding - rightPadding;

    // Calculate vertical scale
    double maxVal = targetCalories * 1.25;
    for (final item in history) {
      if (item.calories > maxVal) maxVal = item.calories * 1.15;
    }
    if (maxVal <= 0) maxVal = 2500;

    // 1. Y-Axis Gridlines & Labels (Matching reference 100, 75, 50, 25, 0)
    final gridValues = [1.0, 0.75, 0.5, 0.25, 0.0];
    final gridLinePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    for (final ratio in gridValues) {
      final y = topPadding + (chartHeight * (1.0 - ratio));
      // Grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridLinePaint,
      );

      // Label on right
      final labelVal = (maxVal * ratio).round();
      final labelText = labelVal >= 1000
          ? '${(labelVal / 1000).toStringAsFixed(1)}k'
          : labelVal.toString();

      final yPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      yPainter.paint(
        canvas,
        Offset(size.width - rightPadding + 6, y - (yPainter.height / 2)),
      );
    }

    // 2. Plot Points
    final count = history.length;
    final step = chartWidth / (count - 1);
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      final item = history[i];
      final x = leftPadding + (i * step);
      final calVal = item.isLogged ? item.calories : 0.0;
      final y = topPadding + (chartHeight * (1.0 - (calVal / maxVal)));
      points.add(Offset(x, y));
    }

    // 3. Smooth Cubic Bezier Wave & Cyan-to-Lime Gradient Fill
    if (points.isNotEmpty) {
      final path = Path();
      final fillPath = Path();

      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, topPadding + chartHeight);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
        fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.close();

      // Soft cyan-to-lime wave fill (matching Phone 2 exactly)
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF14B8A6).withValues(alpha: 0.30),
                AppColors.accent.withValues(alpha: 0.15),
                Colors.transparent,
              ]
            : [
                const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                const Color(0xFFE2F952).withValues(alpha: 0.20),
                Colors.transparent,
              ],
        stops: const [0.0, 0.65, 1.0],
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

      // Dark wave stroke line
      final strokePaint = Paint()
        ..color = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF132E2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, strokePaint);

      // Target reference line in Calora lime (per Section 10)
      if (targetCalories > 0 && targetCalories <= maxVal) {
        final targetY =
            topPadding + (chartHeight * (1.0 - (targetCalories / maxVal)));
        final targetPaint = Paint()
          ..color = targetLineColor.withValues(alpha: 0.85)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        const dashWidth = 4.5;
        const dashSpace = 3.5;
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
      }
    }

    // 4. Vertical Indicator Line & Black Pill Badge for Active Day
    int activeIndex = count - 1;
    for (int i = count - 1; i >= 0; i--) {
      if (history[i].isToday) {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex >= 0 && activeIndex < points.length) {
      final activePoint = points[activeIndex];
      final activeItem = history[activeIndex];

      // Vertical guide line to baseline
      canvas.drawLine(
        Offset(activePoint.dx, activePoint.dy),
        Offset(activePoint.dx, topPadding + chartHeight),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
          ..strokeWidth = 1.0,
      );

      // Black callout pill (matching reference "78" badge)
      if (activeItem.isLogged) {
        final badgeText = activeItem.calories.round().toString();
        final textSpan = TextSpan(
          text: badgeText,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF0F1410) : Colors.white,
          ),
        );
        final painter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        const padH = 8.0;
        const padV = 3.5;
        final w = painter.width + (padH * 2);
        final h = painter.height + (padV * 2);
        final left = (activePoint.dx - (w / 2))
            .clamp(leftPadding, leftPadding + chartWidth - w);
        final top = math.max(2.0, activePoint.dy - h - 8);

        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, w, h),
          const Radius.circular(999),
        );

        canvas.drawRRect(
          rrect,
          Paint()
            ..color = isDark ? AppColors.accent : const Color(0xFF111411),
        );
        painter.paint(canvas, Offset(left + padH, top + padV));
      }
    }

    // 5. X-Axis Day Numbers and Initials (matching reference 18/M 19/T ...)
    for (int i = 0; i < count; i++) {
      final item = history[i];
      final x = leftPadding + (i * step);
      final isToday = item.isToday;

      // Number on top
      final numText = item.dayNumber.toString();
      final numSpan = TextSpan(
        text: numText,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          color: isToday
              ? (isDark ? const Color(0xFF0F1410) : Colors.white)
              : (isDark ? AppColors.darkTextPrimary : const Color(0xFF111613)),
        ),
      );
      final numPainter = TextPainter(
        text: numSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeY = topPadding + chartHeight + 6;

      if (isToday) {
        // Rounded tag around active day number
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, badgeY + 7), width: 22, height: 19),
            const Radius.circular(7),
          ),
          Paint()
            ..color = isDark ? AppColors.accent : const Color(0xFF111411),
        );
      }

      numPainter.paint(
        canvas,
        Offset(x - (numPainter.width / 2), badgeY),
      );

      // Day Initial below (M, T, W, T, F, S, S)
      final initialSpan = TextSpan(
        text: item.dayInitial,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          color: isToday
              ? (isDark ? AppColors.accent : const Color(0xFF111613))
              : textColor,
        ),
      );
      final initialPainter = TextPainter(
        text: initialSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      initialPainter.paint(
        canvas,
        Offset(x - (initialPainter.width / 2), badgeY + 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EditorialCalorieChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.targetCalories != targetCalories ||
        oldDelegate.isDark != isDark;
  }
}
