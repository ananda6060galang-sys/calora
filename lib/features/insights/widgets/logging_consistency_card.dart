import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insights_state.dart';

class LoggingConsistencyCard extends StatelessWidget {
  const LoggingConsistencyCard({
    super.key,
    required this.loggedDaysCount,
    required this.totalDaysCount,
    required this.history,
    required this.isDark,
  });

  final int loggedDaysCount;
  final int totalDaysCount;
  final List<DailyCalorieData> history;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111613);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF5A665D);
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'FOOD LOGGING',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // Value & 7-day Day Pills in a single responsive row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 6 / 7 days
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$loggedDaysCount / $totalDaysCount',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  TextSpan(
                    text: ' days',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Minimal 7-day pill chips (Clean, 0 dots)
            Row(
              children: List.generate(history.length, (index) {
                final item = history[index];
                final isLogged = item.isLogged;
                final isToday = item.isToday;

                return Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isLogged
                          ? (isDark
                              ? AppColors.accent.withValues(alpha: 0.18)
                              : const Color(0xFFE8FCD0))
                          : (isDark
                              ? const Color(0xFF1B221C)
                              : const Color(0xFFF3F4F1)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isToday
                            ? (isDark
                                ? AppColors.accent
                                : const Color(0xFF65A30D))
                            : (isLogged
                                ? (isDark
                                    ? AppColors.accent.withValues(alpha: 0.4)
                                    : const Color(0xFFCCE8A3))
                                : Colors.transparent),
                        width: isToday ? 1.2 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.dayInitial,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: isToday || isLogged
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isLogged
                            ? (isDark
                                ? AppColors.accent
                                : const Color(0xFF234B0E))
                            : textTertiary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
