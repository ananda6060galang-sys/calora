import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../diary/food_diary_screen.dart';
import '../diary/providers/diary_provider.dart';
import 'providers/profile_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final totals = ref.watch(diaryTotalsProvider);

    final target = profile.dailyCalorieTarget;
    final remaining = (target - totals.calories).round();
    final calorieProgress = target <= 0 ? 0.0 : totals.calories / target;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // Soft gradient hero background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? const Color(0xFF2C4A26) // Dark sage
                        : const Color.fromARGB(255, 214, 253, 150), // Light sage / soft green
                    (isDark ? AppColors.darkBg : AppColors.lightBg).withValues(alpha: 0.0), // Fade to bg
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 124),
          children: [
            _DashboardHeader(profile: profile, isDark: isDark),
            const SizedBox(height: 22),
            _CalorieHeroCard(
              consumed: totals.calories,
              remaining: remaining,
              target: target.round(),
              progress: calorieProgress,
              goal: _goalLabel(profile.goal),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth < 340 ? 8.0 : 10.0;
                return Row(
                  children: [
                    Expanded(
                      child: _MacroCard(
                        label: 'dashboard.protein'.tr(),
                        value: '${totals.proteinG.round()}g',
                        target: '${profile.proteinTargetG.round()}g',
                        color: AppColors.protein,
                        progress: totals.proteinG / profile.proteinTargetG,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _MacroCard(
                        label: 'dashboard.carbs'.tr(),
                        value: '${totals.carbsG.round()}g',
                        target: '${profile.carbsTargetG.round()}g',
                        color: AppColors.carbs,
                        progress: totals.carbsG / profile.carbsTargetG,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _MacroCard(
                        label: 'dashboard.fat'.tr(),
                        value: '${totals.fatG.round()}g',
                        target: '${profile.fatTargetG.round()}g',
                        color: AppColors.lavender,
                        progress: totals.fatG / profile.fatTargetG,
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'dashboard.quickActions'.tr(),
              action: 'dashboard.viewAll'.tr(),
              onActionTap: () {},
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth < 340 ? 8.0 : 10.0;
                return Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.add_rounded,
                        label: 'dashboard.food'.tr(),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FoodDiaryScreen(),
                          ),
                        ),
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.fitness_center_outlined,
                        label: 'dashboard.workout'.tr(),
                        color: AppColors.lavender,
                        onTap: () {},
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'dashboard.weight'.tr(),
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        onTap: () {},
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'dashboard.todaysInsights'.tr(), isDark: isDark),
            const SizedBox(height: 12),
            _InsightCard(
              remaining: remaining,
              isDark: isDark,
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  String _goalLabel(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'dashboard.goals.loseWeight'.tr();
      case Goal.gainMuscle:
        return 'dashboard.goals.gainMuscle'.tr();
      case Goal.leanBulk:
        return 'dashboard.goals.leanBulk'.tr();
      case Goal.maintainWeight:
        return 'dashboard.goals.maintainWeight'.tr();
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile, required this.isDark});

  final UserProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'C',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0E0F10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dashboard.hello'.tr(),
                style: _textStyle(
                  isDark: isDark,
                  size: 11,
                  weight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(isDark: isDark, size: 17, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _CircleIconButton(icon: Icons.search_rounded, isDark: isDark),
        const SizedBox(width: 8),
        _CircleIconButton(icon: Icons.notifications_none_rounded, isDark: isDark),
      ],
    );
  }
}

class _CalorieHeroCard extends StatelessWidget {
  const _CalorieHeroCard({
    required this.consumed,
    required this.remaining,
    required this.target,
    required this.progress,
    required this.goal,
    required this.isDark,
  });

  final int consumed;
  final int remaining;
  final int target;
  final double progress;
  final String goal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 244,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: _cardDecoration(isDark: isDark, radius: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'dashboard.dailySummary'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(isDark: isDark, size: 19, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      goal,
                      style: _textStyle(isDark: isDark, size: 11, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              height: 132,
              width: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(210, 132),
                    painter: _SegmentedGaugePainter(progress: progress, isDark: isDark),
                  ),
                  Positioned(
                    bottom: 14,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$remaining',
                          style: _textStyle(isDark: isDark, size: 31, weight: FontWeight.w900),
                        ),
                        Text(
                          'dashboard.kcalLeft'.tr(),
                          style: _textStyle(
                            isDark: isDark,
                            size: 12,
                            weight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(label: 'dashboard.consumed'.tr(), value: '$consumed kcal', isDark: isDark),
              ),
              Container(width: 1, height: 34, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              Expanded(
                child: _HeroMetric(label: 'dashboard.goal'.tr(), value: '$target kcal', isDark: isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, required this.isDark});

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: _textStyle(
            isDark: isDark,
            size: 11,
            weight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: _textStyle(isDark: isDark, size: 14, weight: FontWeight.w800)),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.progress,
    required this.isDark,
  });

  final String label;
  final String value;
  final String target;
  final Color color;
  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: _cardDecoration(isDark: isDark, radius: 20, blur: 18, offset: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    isDark: isDark,
                    size: 11,
                    weight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: _textStyle(isDark: isDark, size: 16, weight: FontWeight.w900)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 5,
              color: color,
              backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'dashboard.ofTarget'.tr(args: [target]),
            style: _textStyle(
              isDark: isDark,
              size: 10,
              weight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onActionTap, required this.isDark});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(isDark: isDark, size: 17, weight: FontWeight.w900)),
        ),
        if (action != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action!,
              style: _textStyle(
                isDark: isDark,
                size: 12,
                weight: FontWeight.w800,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.accent,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isPrimaryColor = color == AppColors.lightTextPrimary || color == AppColors.darkTextPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: _cardDecoration(isDark: isDark, radius: 22, blur: 16, offset: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: isPrimaryColor ? 0.08 : 0.18,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(isDark: isDark, size: 11, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.remaining,
    required this.isDark,
  });

  final int remaining;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark: isDark, radius: 28),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  remaining >= 0 ? 'dashboard.onPaceToday'.tr() : 'dashboard.lightResetNeeded'.tr(),
                  style: _textStyle(isDark: isDark, size: 15, weight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  remaining >= 0
                      ? 'dashboard.kcalLeftKeepItUp'.tr(args: ['$remaining'])
                      : 'dashboard.kcalOverKeepDinnerLighter'.tr(args: ['${remaining.abs()}']),
                  style: _textStyle(
                    isDark: isDark,
                    size: 12,
                    weight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: BoxShape.circle,
        boxShadow: _softShadow(isDark: isDark, blur: 16, offset: 6),
      ),
      child: Icon(icon, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
    );
  }
}

class _SegmentedGaugePainter extends CustomPainter {
  const _SegmentedGaugePainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 34;
    final center = Offset(size.width / 2, size.height * 0.94);
    final radius = size.width * 0.43;
    final activeCount = (segments * progress.clamp(0, 1)).round();

    for (var i = 0; i < segments; i++) {
      final t = i / (segments - 1);
      final angle = math.pi + (math.pi * t);
      final isActive = i < activeCount;
      final barLength = 18.0 + (math.sin(t * math.pi) * 14);
      final startRadius = radius - barLength;
      final endRadius = radius;
      final start = Offset(
        center.dx + math.cos(angle) * startRadius,
        center.dy + math.sin(angle) * startRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * endRadius,
        center.dy + math.sin(angle) * endRadius,
      );

      final paint = Paint()
        ..color = isActive
            ? Color.lerp(AppColors.lavender, AppColors.accent, t)!
            : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

BoxDecoration _cardDecoration({
  required bool isDark,
  required double radius,
  double blur = 24,
  double offset = 10,
}) {
  return BoxDecoration(
    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.72)),
    boxShadow: _softShadow(isDark: isDark, blur: blur, offset: offset),
  );
}

List<BoxShadow> _softShadow({required bool isDark, required double blur, required double offset}) {
  if (isDark) return [];
  return [
    BoxShadow(
      color: AppColors.lightTextPrimary.withValues(alpha: 0.055),
      blurRadius: blur,
      offset: Offset(0, offset),
    ),
  ];
}

TextStyle _textStyle({
  required bool isDark,
  required double size,
  required FontWeight weight,
  Color? color,
  double? height,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
    height: height,
    letterSpacing: 0,
  );
}

