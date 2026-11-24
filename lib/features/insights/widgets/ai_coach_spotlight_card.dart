import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/ai_insight_report.dart';

/// Compact spotlight card on the main InsightsScreen introducing the
/// AI Nutrition Coach report and driving navigation to InsightsDetailScreen.
class AiCoachSpotlightCard extends StatelessWidget {
  const AiCoachSpotlightCard({
    super.key,
    required this.report,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  final AiInsightReport? report;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.70)
        : const Color(0xFFEBECEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF131814);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder, width: 1.0),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Badge + Grade + Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'insights.aiCoachTitle'.tr().toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.accent : const Color(0xFF17382B),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (report != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222C24) : const Color(0xFFE4EDE5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              report!.weeklyGrade,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.accent : const Color(0xFF1A4735),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: textTertiary,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (isLoading)
                Text(
                  'insights.analyzingTelemetry'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                )
              else if (report != null) ...[
                Text(
                  report!.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report!.statusBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ] else
                Text(
                  'insights.aiCoachSubtitle'.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                  ),
                ),

              const SizedBox(height: 14),

              // Bottom subtle action prompt
              Row(
                children: [
                  Text(
                    'insights.viewAiReport'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.accent : const Color(0xFF17382B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? AppColors.accent : const Color(0xFF17382B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
