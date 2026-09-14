import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class FeaturedInsightCard extends StatelessWidget {
  const FeaturedInsightCard({
    super.key,
    required this.insight,
    required this.isDark,
    this.onTap,
  });

  final SmartInsightItem insight;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131A14), // Dark obsidian card matching reference
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF263326),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle botanical ambient glow on right edge (inspired by reference)
            Positioned(
              right: -30,
              top: -20,
              bottom: -20,
              width: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.16),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag: SMART INSIGHT
                        Text(
                          'SMART INSIGHT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title: e.g. Your calories are on track
                        Text(
                          insight.title,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          insight.description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFA5B8A2),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Subtle circular arrow button
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222C22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF344434),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
