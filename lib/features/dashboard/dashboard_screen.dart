import 'dart:math' as math;

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

    return ColoredBox(
      color: AppColors.lightBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 124),
          children: [
            _DashboardHeader(profile: profile),
            const SizedBox(height: 22),
            _CalorieHeroCard(
              consumed: totals.calories,
              remaining: remaining,
              target: target.round(),
              progress: calorieProgress,
              goal: _goalLabel(profile.goal),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth < 340 ? 8.0 : 10.0;
                return Row(
                  children: [
                    Expanded(
                      child: _MacroCard(
                        label: 'Protein',
                        value: '${totals.proteinG.round()}g',
                        target: '${profile.proteinTargetG.round()}g',
                        color: AppColors.protein,
                        progress: totals.proteinG / profile.proteinTargetG,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _MacroCard(
                        label: 'Carbs',
                        value: '${totals.carbsG.round()}g',
                        target: '${profile.carbsTargetG.round()}g',
                        color: AppColors.carbs,
                        progress: totals.carbsG / profile.carbsTargetG,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _MacroCard(
                        label: 'Fat',
                        value: '${totals.fatG.round()}g',
                        target: '${profile.fatTargetG.round()}g',
                        color: AppColors.lavender,
                        progress: totals.fatG / profile.fatTargetG,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Quick Actions',
              action: 'View all',
              onActionTap: () {},
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
                        label: 'Food',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FoodDiaryScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.fitness_center_outlined,
                        label: 'Workout',
                        color: AppColors.lavender,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight',
                        color: AppColors.lightTextPrimary,
                        onTap: () {},
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: "Today's Insights"),
            const SizedBox(height: 12),
            _InsightCard(
              remaining: remaining,
            ),
          ],
        ),
      ),
    );
  }

  String _goalLabel(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'Lose weight';
      case Goal.gainMuscle:
        return 'Gain muscle';
      case Goal.leanBulk:
        return 'Lean bulk';
      case Goal.maintainWeight:
        return 'Maintain';
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            profile.name.characters.first.toUpperCase(),
            style: _textStyle(
              size: 18,
              weight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello',
                style: _textStyle(
                  size: 11,
                  weight: FontWeight.w600,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(size: 17, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const _CircleIconButton(icon: Icons.search_rounded),
        const SizedBox(width: 8),
        const _CircleIconButton(icon: Icons.notifications_none_rounded),
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
  });

  final int consumed;
  final int remaining;
  final int target;
  final double progress;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 244,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: _cardDecoration(radius: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Daily Summary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(size: 19, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: AppColors.lightTextPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      goal,
                      style: _textStyle(size: 11, weight: FontWeight.w700),
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
                    painter: _SegmentedGaugePainter(progress: progress),
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
                          style: _textStyle(size: 31, weight: FontWeight.w900),
                        ),
                        Text(
                          'kcal left',
                          style: _textStyle(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.lightTextSecondary,
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
                child: _HeroMetric(label: 'Consumed', value: '$consumed kcal'),
              ),
              Container(width: 1, height: 34, color: AppColors.lightBorder),
              Expanded(
                child: _HeroMetric(label: 'Goal', value: '$target kcal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: _textStyle(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: _textStyle(size: 14, weight: FontWeight.w800)),
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
  });

  final String label;
  final String value;
  final String target;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: _cardDecoration(radius: 20, blur: 18, offset: 7),
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
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: _textStyle(size: 16, weight: FontWeight.w900)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 5,
              color: color,
              backgroundColor: AppColors.lightSurfaceAlt,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'of $target',
            style: _textStyle(
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onActionTap});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(size: 17, weight: FontWeight.w900)),
        ),
        if (action != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action!,
              style: _textStyle(
                size: 12,
                weight: FontWeight.w800,
                color: AppColors.lavender,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: _cardDecoration(radius: 22, blur: 16, offset: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: color == AppColors.lightTextPrimary ? 0.08 : 0.18,
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
              style: _textStyle(size: 11, weight: FontWeight.w800),
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
  });

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 28),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  remaining >= 0 ? 'On pace today' : 'Light reset needed',
                  style: _textStyle(size: 15, weight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  remaining >= 0
                      ? '$remaining kcal left today. Keep it up!'
                      : '${remaining.abs()} kcal over. Keep dinner lighter.',
                  style: _textStyle(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
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
  const _CircleIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        shape: BoxShape.circle,
        boxShadow: _softShadow(blur: 16, offset: 6),
      ),
      child: Icon(icon, size: 18, color: AppColors.lightTextPrimary),
    );
  }
}

class _SegmentedGaugePainter extends CustomPainter {
  const _SegmentedGaugePainter({required this.progress});

  final double progress;

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
            : AppColors.lightSurfaceAlt
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

BoxDecoration _cardDecoration({
  required double radius,
  double blur = 24,
  double offset = 10,
}) {
  return BoxDecoration(
    color: AppColors.lightSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.72)),
    boxShadow: _softShadow(blur: blur, offset: offset),
  );
}

List<BoxShadow> _softShadow({required double blur, required double offset}) {
  return [
    BoxShadow(
      color: AppColors.lightTextPrimary.withValues(alpha: 0.055),
      blurRadius: blur,
      offset: Offset(0, offset),
    ),
  ];
}

TextStyle _textStyle({
  required double size,
  required FontWeight weight,
  Color color = AppColors.lightTextPrimary,
  double? height,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: 0,
  );
}
