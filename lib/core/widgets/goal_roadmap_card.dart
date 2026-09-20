import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/nutrition_calculator.dart';
import '../../models/user_profile.dart';

/// Clean, Apple Health-inspired card presenting the user's Goal Roadmap & Projection.
///
/// Designed with generous whitespace, clear typography hierarchy, and effortless
/// glanceability (2x2 metric tiles + sleek weight journey indicator).
class GoalRoadmapCard extends StatelessWidget {
  const GoalRoadmapCard({
    super.key,
    required this.profile,
    this.showTitle = true,
  });

  final UserProfile profile;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = NutritionCalculator.calculateGoalRoadmap(profile);

    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final localeStr = context.locale.languageCode;
    final monthYearFormatter = DateFormat('MMM yyyy', localeStr);
    final formattedDate = monthYearFormatter.format(plan.estimatedTargetDate);

    // Goal badge label
    final String goalBadgeLabel;
    switch (plan.goal) {
      case Goal.loseWeight:
        goalBadgeLabel = 'dashboard.goals.loseWeight'.tr();
        break;
      case Goal.maintainWeight:
        goalBadgeLabel = 'dashboard.goals.maintainWeight'.tr();
        break;
      case Goal.gainWeight:
        goalBadgeLabel = 'dashboard.goals.gainWeight'.tr();
        break;
    }

    // Pace title
    final String paceLabel;
    switch (plan.goalPace) {
      case GoalPace.gentle:
        paceLabel = 'Pace Santai (0.25 kg/mg)';
        break;
      case GoalPace.moderate:
        paceLabel = 'Pace Sedang (0.50 kg/mg)';
        break;
      case GoalPace.faster:
        paceLabel = 'Pace Cepat (0.75 kg/mg)';
        break;
    }

    // Concise, natural Apple-style insight copy
    final String insightText;
    if (plan.isMaintenance) {
      insightText =
          'Target harianmu disesuaikan tepat di TDEE (${plan.dailyCalorieTarget.round()} kcal) untuk menjaga berat badan tetap stabil & fit.';
    } else if (plan.isWeightLoss) {
      insightText =
          'Defisit terukur ${plan.dailyDeficitOrSurplusKcal.round()} kcal/hari membakar lemak ~${plan.paceKgPerWeek.toStringAsFixed(2)} kg/minggu tanpa mengganggu metabolisme tubuh.';
    } else {
      insightText =
          'Surplus terukur ${plan.dailyDeficitOrSurplusKcal.round()} kcal/hari memberi energi optimal untuk membangun massa otot ~${plan.paceKgPerWeek.toStringAsFixed(2)} kg/minggu.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dividerColor.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Eyebrow + Goal Title & Status Pill ──────────────
          if (showTitle) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARGET SAYA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goalBadgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${plan.paceKgPerWeek.toStringAsFixed(2)} kg/mg',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
          ],

          // ── The Weight Journey (Clean Apple-Style Progress) ─────────
          if (!plan.isMaintenance) ...[
            // Numbers Row: Current -> Difference Badge -> Target
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Current Weight
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saat Ini',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.currentWeightKg.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'kg',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Sleek Center Difference Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        plan.isWeightLoss
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        size: 14,
                        color: const Color(0xFF0F1410),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${plan.isWeightLoss ? '-' : '+'}${plan.weightDifferenceKg.toStringAsFixed(1)} kg',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1410), // Dark on lime
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Target Weight
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.targetWeightKg.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF85C500),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'kg',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Smooth Pill Progress Track
            Container(
              height: 7,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? surfaceAlt
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3.5),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.65, // Elegant progress indication
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.8),
                          AppColors.accent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3.5),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),
          ],

          // ── 2x2 Spacious Metric Grid (Glanceable & Readable) ────────
          Row(
            children: [
              // 1. Proyeksi Selesai
              Expanded(
                child: _AppleMetricTile(
                  icon: Icons.access_time_rounded,
                  iconColor: isDark ? AppColors.accent : const Color(0xFF85C500),
                  label: 'PROYEKSI SELESAI',
                  value: plan.isMaintenance
                      ? 'Stabil'
                      : '~${plan.estimatedWeeks} Minggu',
                  sub: plan.isMaintenance
                      ? 'Target tercapai'
                      : 'Est. $formattedDate',
                  surface: surfaceAlt,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 12),

              // 2. Target Kalori
              Expanded(
                child: _AppleMetricTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF8A48),
                  label: 'TARGET KALORI',
                  value: '${plan.dailyCalorieTarget.round()} kcal',
                  sub: plan.isMaintenance
                      ? 'Keseimbangan TDEE'
                      : plan.isWeightLoss
                          ? 'Defisit ${plan.dailyDeficitOrSurplusKcal.round()} kcal/hari'
                          : 'Surplus ${plan.dailyDeficitOrSurplusKcal.round()} kcal/hari',
                  surface: surfaceAlt,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // 3. Target Protein
              Expanded(
                child: _AppleMetricTile(
                  icon: Icons.fitness_center_rounded,
                  iconColor: AppColors.protein,
                  label: 'TARGET PROTEIN',
                  value: '${plan.proteinTargetG.round()} g',
                  sub: 'Fokus otot & kenyang',
                  surface: surfaceAlt,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 12),

              // 4. Pace Target
              Expanded(
                child: _AppleMetricTile(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  label: 'PACE MINGGUAN',
                  value: plan.isMaintenance
                      ? 'Pertahankan'
                      : '${plan.paceKgPerWeek.toStringAsFixed(2)} kg',
                  sub: paceLabel,
                  surface: surfaceAlt,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Apple Trends-Style Subtle Insight Footnote ───────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: isDark ? AppColors.accent : const Color(0xFF85C500),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insightText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BMR Floor Safety Pill (Minimalist & Reassuring)
          if (plan.isBmrClamped) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: isDark ? AppColors.accent : const Color(0xFF85C500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Defisit dijaga minimal BMR (${profile.bmr.round()} kcal) demi menjaga kesehatan metabolismemu.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Spacious Apple-style glanceable tile for a single key metric.
class _AppleMetricTile extends StatelessWidget {
  const _AppleMetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
