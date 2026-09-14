import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/user_profile.dart';
import '../dashboard/providers/profile_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    final displayName = profile.name.isNotEmpty ? profile.name : 'Calora User';
    final goalLabel = _goalLabel(profile.goal);
    final bmr = _calcBMR(profile);

    // Provide a mock image URL or null to test the fallback
    const String? profileImageUrl = null;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── TOP BAR ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'profile.title'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final currentLang = context.locale.languageCode;
                          final nextLocale = currentLang == 'en' ? const Locale('id') : const Locale('en');
                          context.setLocale(nextLocale);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: dividerColor),
                          ),
                          child: Text(
                            'EN / ID (${context.locale.languageCode.toUpperCase()})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openSettings(context),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: dividerColor),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── PROFILE IDENTITY ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar Section
                  Stack(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : const Color(0xFFF0F0EE),
                          shape: BoxShape.circle,
                          image: profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profileImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: profileImageUrl == null
                            ? Text(
                                displayName[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: bgColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 12,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'profile.ageAndGender'.tr(args: ['${profile.age}', profile.gender == Gender.male ? 'onboarding.male'.tr() : 'onboarding.female'.tr()]),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openEditProfile(context, profile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: dividerColor),
                      ),
                      child: Text(
                        'profile.edit'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── BODY SNAPSHOT ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: dividerColor, width: 0.5),
                    bottom: BorderSide(color: dividerColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    _StatColumn(
                      label: 'dashboard.weight'.tr(),
                      value: '${profile.weightKg.toStringAsFixed(1)} kg',
                      textPrimary: textPrimary,
                      textSecondary: textTertiary,
                    ),
                    _VerticalDivider(color: dividerColor),
                    _StatColumn(
                      label: 'profile.height'.tr(),
                      value: '${profile.heightCm.round()} cm',
                      textPrimary: textPrimary,
                      textSecondary: textTertiary,
                    ),
                    _VerticalDivider(color: dividerColor),
                    _StatColumn(
                      label: 'dashboard.goal'.tr(),
                      value: '${profile.dailyCalorieTarget.round()} kcal',
                      textPrimary: textPrimary,
                      textSecondary: textTertiary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── CURRENT GOAL SECTION ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openEditProfile(context, profile),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: dividerColor, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _goalIcon(profile.goal),
                          size: 20,
                          color: isDark ? AppColors.accent : const Color(0xFF3D6B2E),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goalLabel,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Est. BMR $bmr kcal · ${_activityLabel(profile.activityLevel)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // ── PROGRESS SECTION ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.progressUpper'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _ProgressSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

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

  IconData _goalIcon(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return Icons.trending_down_rounded;
      case Goal.maintainWeight:
        return Icons.balance_rounded;
      case Goal.gainWeight:
        return Icons.trending_up_rounded;
    }
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'profile.activity.sedentary'.tr();
      case ActivityLevel.light:
        return 'profile.activity.light'.tr();
      case ActivityLevel.moderate:
        return 'profile.activity.moderate'.tr();
      case ActivityLevel.active:
        return 'profile.activity.active'.tr();
      case ActivityLevel.veryActive:
        return 'profile.activity.veryActive'.tr();
    }
  }

  int _calcBMR(UserProfile p) {
    return (10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + (p.gender == Gender.male ? 5 : -161)).round();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  // ─── Sheet: Edit Profile ────────────────────────────────────

  void _openEditProfile(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PROGRESS SECTION
// ════════════════════════════════════════════════════════════════

class _ProgressSection extends StatefulWidget {
  const _ProgressSection();

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  int _selectedIndex = 0;
  
  List<String> get _tabs => ['profile.tabs.weight'.tr(), 'profile.tabs.calories'.tr(), 'profile.tabs.gymVol'.tr()];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: Column(
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _tabs[index],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? textPrimary : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Chart Area
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            child: _buildChart(isDark, textSecondary),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChart(bool isDark, Color textColor) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    if (_selectedIndex == 0) {
      // Weight
      final data = [67.5, 67.1, 66.8, 66.4, 66.0, 65.7, 65.0];
      return CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(
          data: data,
          labels: days,
          lineColor: AppColors.accent,
          textColor: textColor,
          isDark: isDark,
        ),
      );
    } else if (_selectedIndex == 1) {
      // Calories
      final data = [2150.0, 2400.0, 1980.0, 2350.0, 2200.0, 2500.0, 2100.0];
      return CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(
          data: data,
          labels: days,
          barColor: AppColors.accent.withValues(alpha: 0.8),
          textColor: textColor,
          isDark: isDark,
        ),
      );
    } else {
      // Gym Volume
      final data = [1850.0, 0.0, 2200.0, 0.0, 2480.0, 1400.0, 0.0];
      return CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(
          data: data,
          labels: days,
          barColor: isDark ? AppColors.darkTextTertiary : const Color(0xFFAFA79C),
          textColor: textColor,
          isDark: isDark,
        ),
      );
    }
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color textColor;
  final bool isDark;

  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final gridPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : const Color(0xFFECECEC)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
      
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
      
    final dotBgPaint = Paint()
      ..color = isDark ? AppColors.darkSurface : Colors.white
      ..style = PaintingStyle.fill;

    const bottomPadding = 24.0;
    const leftPadding = 30.0;
    
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // Draw horizontal grid lines
    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    
    final adjustedMin = minVal - (range * 0.2);
    final adjustedMax = maxVal + (range * 0.2);
    final adjustedRange = adjustedMax - adjustedMin;

    final textStyle = GoogleFonts.inter(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Y Axis Labels & Grid
    for (int i = 0; i <= 4; i++) {
      final yValue = adjustedMin + (adjustedRange * i / 4);
      final y = chartHeight - (chartHeight * i / 4);
      
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );
      
      final textSpan = TextSpan(text: yValue.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // X Axis Labels
    final xStep = chartWidth / (data.length - 1);
    for (int i = 0; i < labels.length; i++) {
      final x = leftPadding + (i * xStep);
      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - textPainter.height));
    }

    // Draw Line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + (i * xStep);
      final y = chartHeight - ((data[i] - adjustedMin) / adjustedRange * chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw Dots
    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + (i * xStep);
      final y = chartHeight - ((data[i] - adjustedMin) / adjustedRange * chartHeight);
      
      canvas.drawCircle(Offset(x, y), 4, dotBgPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final Color textColor;
  final bool isDark;

  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final gridPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : const Color(0xFFECECEC)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
      
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
      
    final barBgPaint = Paint()
      ..color = isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFECECEC).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const bottomPadding = 24.0;
    const leftPadding = 35.0;
    
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final maxVal = data.reduce(math.max);
    final adjustedMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    final textStyle = GoogleFonts.inter(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Y Axis Labels & Grid
    for (int i = 0; i <= 4; i++) {
      final yValue = (adjustedMax * i / 4).round();
      final y = chartHeight - (chartHeight * i / 4);
      
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );
      
      final textSpan = TextSpan(text: yValue.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Bars & X Axis Labels
    final xStep = chartWidth / data.length;
    final barWidth = xStep * 0.5;
    
    for (int i = 0; i < data.length; i++) {
      final xCenter = leftPadding + (i * xStep) + (xStep / 2);
      
      // Label
      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2, size.height - textPainter.height));
      
      // Bar background
      final barBgRect = Rect.fromLTRB(
        xCenter - barWidth / 2,
        0,
        xCenter + barWidth / 2,
        chartHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barBgRect, const Radius.circular(4)),
        barBgPaint,
      );

      // Value bar
      if (data[i] > 0) {
        final barHeight = (data[i] / adjustedMax) * chartHeight;
        final barRect = Rect.fromLTRB(
          xCenter - barWidth / 2,
          chartHeight - barHeight,
          xCenter + barWidth / 2,
          chartHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ════════════════════════════════════════════════════════════════
// INTERNAL WIDGETS
// ════════════════════════════════════════════════════════════════

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 28, color: color);
  }
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late Goal _selectedGoal;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _heightCtrl = TextEditingController(text: widget.profile.heightCm.round().toString());
    _weightCtrl = TextEditingController(text: widget.profile.weightKg.toStringAsFixed(1));
    _selectedGoal = widget.profile.goal;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'profile.editProfile'.tr(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'auth.fullName'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'profile.heightCmLabel'.tr(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'profile.weightKgLabel'.tr(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Goal>(
                  initialValue: _selectedGoal,
                  style: GoogleFonts.inter(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'dashboard.goal'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: Goal.loseWeight, child: Text('dashboard.goals.loseWeight'.tr())),
                    DropdownMenuItem(value: Goal.maintainWeight, child: Text('dashboard.goals.maintainWeight'.tr())),
                    DropdownMenuItem(value: Goal.gainWeight, child: Text('dashboard.goals.gainWeight'.tr())),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedGoal = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Consumer(
            builder: (context, ref, _) {
              return GestureDetector(
                onTap: () {
                  final p = widget.profile.copyWith(
                    name: _nameCtrl.text.trim(),
                    heightCm: double.tryParse(_heightCtrl.text) ?? widget.profile.heightCm,
                    weightKg: double.tryParse(_weightCtrl.text) ?? widget.profile.weightKg,
                    goal: _selectedGoal,
                  );
                  ref.read(userProfileProvider.notifier).state = p;
                  Navigator.pop(context);
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'profile.save'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F1410),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
