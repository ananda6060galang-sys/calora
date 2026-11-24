import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/ai_insight_report.dart';

/// Full editorial section rendering the AI Nutrition Coach Report
/// inside InsightsDetailScreen. Adheres strictly to Calora's botanical design
/// language and anti-slop principles (clear purpose, no tacky AI aesthetics).
class AiCoachReportSection extends StatelessWidget {
  const AiCoachReportSection({
    super.key,
    required this.report,
    required this.isLoading,
    required this.isDark,
    required this.onRefresh,
  });

  final AiInsightReport? report;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF131814);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);
    final cardBg = isDark ? const Color(0xFF172019) : const Color(0xFFF4F7F4);
    final cardBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.65)
        : const Color(0xFFE2E7E3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SECTION HEADER & REFRESH ACTION ─────────────────────────
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.accent : const Color(0xFF17382B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFF0F1410) : Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'insights.aiCoachTitle'.tr().toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.accent : const Color(0xFF17382B),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'insights.aiCoachSubtitle'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            // Refresh Button (compact, responsive pill)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : onRefresh,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2821) : const Color(0xFFE8ECE9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : const Color(0xFFD6DCD7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? AppColors.accent : const Color(0xFF17382B),
                          ),
                        )
                      else
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: isDark ? AppColors.accent : const Color(0xFF17382B),
                        ),
                      const SizedBox(width: 5),
                      Text(
                        'insights.refreshAiAnalysis'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF17382B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── LOADING STATE SKELETON ───────────────────────────────────
        if (isLoading) ...[
          _buildLoadingSkeleton(isDark: isDark, textTertiary: textTertiary),
        ] else if (report != null) ...[
          // ── 1. HERO REPORT CARD (Grade + Headline + Executive Summary) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row: Grade Pill + Status Badge (Full-width Wrap, 100% overflow safe)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.accent : const Color(0xFF17382B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report!.weeklyGrade,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFF0F1410) : Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF212D23) : const Color(0xFFE4EDE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report!.statusBadge,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.accent : const Color(0xFF1F4A39),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Headline
                Text(
                  report!.headline,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Executive Summary
                Text(
                  report!.executiveSummary,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtle Editorial Gemini Attribution Footer
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'insights.poweredByGemini'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textTertiary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 2. CLINICAL PILLARS (Metabolic Health, Macros, Habits) ──
          for (final pillar in report!.pillars) ...[
            _buildPillarCard(
              pillar: pillar,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 18),

          // ── 3. ACTIONABLE LOCAL FOOD RECOMMENDATIONS ─────────────────
          if (report!.actionableFoodSwaps.isNotEmpty) ...[
            Text(
              'insights.actionableFoodSwaps'.tr(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            for (final swap in report!.actionableFoodSwaps) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E18) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.5)
                        : const Color(0xFFE5EAE6),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                          color: isDark ? AppColors.accent : const Color(0xFF245B45),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            swap.context,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        swap.recommendation,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (swap.macros.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222C24) : const Color(0xFFEFF3F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            swap.macros,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.accent : const Color(0xFF1E4837),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // ── 4. MOTIVATIONAL VERDICT (Callout Box) ─────────────────────
          if (report!.motivationalVerdict.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B241C) : const Color(0xFFF1F6F2),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: isDark ? AppColors.accent : const Color(0xFF265B45),
                    width: 3.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'insights.motivationalVerdictTitle'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.accent : const Color(0xFF1B4332),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report!.motivationalVerdict,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLoadingSkeleton({
    required bool isDark,
    required Color textTertiary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172019) : const Color(0xFFF4F7F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isDark ? AppColors.accent : const Color(0xFF17382B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'insights.analyzingTelemetry'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard({
    required AiInsightPillar pillar,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (pillar.status.toLowerCase()) {
      case 'warning':
        statusColor = const Color(0xFFE57373); // Softer warning red
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'needs_attention':
        statusColor = const Color(0xFFFFB74D); // Amber attention
        statusIcon = Icons.info_outline_rounded;
        break;
      case 'optimal':
      default:
        statusColor = isDark ? AppColors.accent : const Color(0xFF2E7548);
        statusIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pillar.category.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pillar.title,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pillar.detail,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          if (pillar.action.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202A22) : const Color(0xFFEAEFEA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '→ ${pillar.action}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : const Color(0xFF1E4837),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
