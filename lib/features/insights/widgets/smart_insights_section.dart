import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class SmartInsightsSection extends StatelessWidget {
  const SmartInsightsSection({
    super.key,
    required this.items,
    required this.isDark,
  });

  final List<SmartInsightItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111613);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);
    final borderColor =
        isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFEBECEF);

    final displayItems = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: SMART INSIGHTS
        Text(
          'SMART INSIGHTS',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Items with subtle separators
        for (int i = 0; i < displayItems.length; i++) ...[
          _EditorialInsightRow(
            item: displayItems[i],
            isDark: isDark,
          ),
          if (i < displayItems.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Container(height: 0.5, color: borderColor),
            ),
        ],
      ],
    );
  }
}

class _EditorialInsightRow extends StatelessWidget {
  const _EditorialInsightRow({
    required this.item,
    required this.isDark,
  });

  final SmartInsightItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111613);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final actionColor = isDark
        ? AppColors.accent
        : const Color(0xFF386616); // Calora dark botanical green

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (e.g. Protein is slightly low)
        Text(
          item.title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),

        // Description (e.g. Your average protein intake is below your target this week.)
        Text(
          item.description,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            height: 1.4,
          ),
        ),

        // Action recommendation (e.g. Add a protein source to breakfast.)
        if (item.recommendation != null && item.recommendation!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            item.recommendation!,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: actionColor,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
