import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class InsightsEmptyState extends StatelessWidget {
  const InsightsEmptyState({
    super.key,
    required this.isDark,
    required this.onLogMealTap,
  });

  final bool isDark;
  final VoidCallback onLogMealTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF161A1D);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clean, minimal icon circle (NO mascot or food illustration)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B241C) : const Color(0xFFF1F5EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_graph_rounded,
              size: 28,
              color: isDark ? AppColors.accent : const Color(0xFF4A7C20),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'insights.emptyTitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'insights.emptySubtitle'.tr(),
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // Clean pill CTA button
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onLogMealTap,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Color(0xFF0F1410),
              ),
              label: Text(
                'insights.logMeal'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F1410),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
