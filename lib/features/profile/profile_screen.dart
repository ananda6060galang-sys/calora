import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../models/user_profile.dart';
import '../dashboard/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
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
                    'Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openSettings(context, ref, profile),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 22,
                      color: textSecondary,
                    ),
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
                          color: isDark ? const Color(0xFF2A2C2F) : const Color(0xFFF0F0EE),
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
                          '${profile.age} years old  ·  ${profile.gender == Gender.male ? 'Male' : 'Female'}',
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
                        'Edit',
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
                      label: 'Weight',
                      value: '${profile.weightKg.toStringAsFixed(1)} kg',
                      textPrimary: textPrimary,
                      textSecondary: textTertiary,
                    ),
                    _VerticalDivider(color: dividerColor),
                    _StatColumn(
                      label: 'Height',
                      value: '${profile.heightCm.round()} cm',
                      textPrimary: textPrimary,
                      textSecondary: textTertiary,
                    ),
                    _VerticalDivider(color: dividerColor),
                    _StatColumn(
                      label: 'Target',
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

            const SizedBox(height: 32),
            
            // ── PROGRESS SECTION ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROGRESS',
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

            const SizedBox(height: 32),

            // ── SETTINGS LIST ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: dividerColor, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Information',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          dividerColor: dividerColor,
                          showDivider: true,
                          onTap: () => _openEditProfile(context, profile),
                        ),
                        _SettingsRow(
                          icon: Icons.flag_outlined,
                          title: 'Goals & Nutrition',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          dividerColor: dividerColor,
                          showDivider: true,
                          onTap: () => _openEditProfile(context, profile),
                        ),
                        _SettingsRow(
                          icon: Icons.palette_outlined,
                          title: 'Appearance',
                          trailing: _themeModeLabel(themeMode),
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          dividerColor: dividerColor,
                          showDivider: true,
                          onTap: () => _showAppearancePicker(context, ref, themeMode, isDark),
                        ),
                        _SettingsRow(
                          icon: Icons.translate_rounded,
                          title: 'Language',
                          trailing: 'English',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          dividerColor: dividerColor,
                          showDivider: true,
                          onTap: () => _showLanguagePicker(context, isDark),
                        ),
                        _SettingsRow(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          dividerColor: dividerColor,
                          showDivider: true,
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          title: 'About Calora',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          dividerColor: dividerColor,
                          showDivider: false,
                          onTap: () => _showAbout(context, isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── LOG OUT ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── VERSION ────────────────────────────────────────
            Center(
              child: Text(
                'Calora v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textTertiary,
                ),
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
        return 'Lose Weight';
      case Goal.maintainWeight:
        return 'Maintain Weight';
      case Goal.gainMuscle:
        return 'Gain Muscle';
      case Goal.leanBulk:
        return 'Lean Bulk';
    }
  }

  IconData _goalIcon(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return Icons.trending_down_rounded;
      case Goal.maintainWeight:
        return Icons.balance_rounded;
      case Goal.gainMuscle:
        return Icons.fitness_center_outlined;
      case Goal.leanBulk:
        return Icons.trending_up_rounded;
    }
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Lightly active';
      case ActivityLevel.moderate:
        return 'Moderately active';
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.veryActive:
        return 'Very active';
    }
  }

  int _calcBMR(UserProfile p) {
    return (10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + (p.gender == Gender.male ? 5 : -161)).round();
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // ─── Sheet: Settings (just opens edit profile for now) ──────

  void _openSettings(BuildContext context, WidgetRef ref, UserProfile profile) {
    _openEditProfile(context, profile);
  }

  // ─── Sheet: Edit Profile ────────────────────────────────────

  void _openEditProfile(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  // ─── Sheet: Appearance Picker ───────────────────────────────

  void _showAppearancePicker(BuildContext context, WidgetRef ref, ThemeMode current, bool isDark) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Appearance',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            for (final entry in [
              (ThemeMode.light, 'Light', Icons.light_mode_outlined),
              (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
            ])
              _PickerRow(
                icon: entry.$3,
                label: entry.$2,
                selected: current == entry.$1,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {
                  ref.read(themeModeProvider.notifier).state = entry.$1;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── Sheet: Language Picker ─────────────────────────────────

  void _showLanguagePicker(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Language',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _PickerRow(
              icon: Icons.translate_rounded,
              label: 'English',
              selected: true,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.pop(ctx),
            ),
            _PickerRow(
              icon: Icons.translate_rounded,
              label: 'Indonesian',
              selected: false,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialog: About ──────────────────────────────────────────

  void _showAbout(BuildContext context, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Calora',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A calorie & gym workout tracker built with Flutter, Supabase, and Riverpod. Designed for gym-focused users who value simplicity.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
  
  final List<String> _tabs = ['Weight', 'Calories', 'Gym Vol'];

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
          barColor: isDark ? const Color(0xFF6B7280) : const Color(0xFFAFA79C),
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
      ..color = isDark ? const Color(0xFF2A2C2F) : const Color(0xFFECECEC)
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
      ..color = isDark ? const Color(0xFF17181A) : Colors.white
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
      ..color = isDark ? const Color(0xFF2A2C2F) : const Color(0xFFECECEC)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
      
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
      
    final barBgPaint = Paint()
      ..color = isDark ? const Color(0xFF2A2C2F).withValues(alpha: 0.5) : const Color(0xFFECECEC).withValues(alpha: 0.5)
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.showDivider,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  Text(
                    trailing!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Divider(height: 0.5, thickness: 0.5, color: dividerColor),
          ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// EDIT PROFILE BOTTOM SHEET
// ════════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
            'Edit Profile',
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
                    labelText: 'Full Name',
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
                          labelText: 'Height (cm)',
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
                          labelText: 'Weight (kg)',
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
                    labelText: 'Goal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: Goal.loseWeight, child: Text('Lose Weight')),
                    DropdownMenuItem(value: Goal.maintainWeight, child: Text('Maintain Weight')),
                    DropdownMenuItem(value: Goal.gainMuscle, child: Text('Gain Muscle')),
                    DropdownMenuItem(value: Goal.leanBulk, child: Text('Lean Bulk')),
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
                  final p = UserProfile(
                    name: _nameCtrl.text.trim(),
                    age: widget.profile.age,
                    gender: widget.profile.gender,
                    heightCm: double.tryParse(_heightCtrl.text) ?? widget.profile.heightCm,
                    weightKg: double.tryParse(_weightCtrl.text) ?? widget.profile.weightKg,
                    activityLevel: widget.profile.activityLevel,
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
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0E0F10),
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
