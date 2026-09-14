import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/insights_state.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
    required this.isDark,
  });

  final InsightsPeriod selectedPeriod;
  final ValueChanged<InsightsPeriod> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF1B241C)
        : const Color(0xFFEEF3EA);
    final borderColor = isDark
        ? const Color(0xFF2C3B2C)
        : const Color(0xFFE0E8DC);
    final inactiveText = isDark
        ? const Color(0xFF8B9E8A)
        : const Color(0xFF5A6B56);

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodPillTab(
              label: 'insights.periodWeek'.tr(),
              isSelected: selectedPeriod == InsightsPeriod.week,
              isDark: isDark,
              inactiveColor: inactiveText,
              onTap: () => onChanged(InsightsPeriod.week),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _PeriodPillTab(
              label: 'insights.periodMonth'.tr(),
              isSelected: selectedPeriod == InsightsPeriod.month,
              isDark: isDark,
              inactiveColor: inactiveText,
              onTap: () => onChanged(InsightsPeriod.month),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPillTab extends StatelessWidget {
  const _PeriodPillTab({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F1410) : inactiveColor,
          ),
        ),
      ),
    );
  }
}
