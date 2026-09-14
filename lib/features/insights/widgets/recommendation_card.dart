import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.isDark,
    this.onTap,
  });

  final SmartInsightItem recommendation;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFEBECEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111613);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small black/dark container with spark icon (matching reference)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222B22) : const Color(0xFF131914),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECOMMENDATION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  recommendation.recommendation != null &&
                          recommendation.recommendation!.isNotEmpty
                      ? recommendation.recommendation!
                      : recommendation.title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Arrow affordance
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: textTertiary,
          ),
        ],
      ),
    ),
  );
}
}
