import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Quick Language Toggle Pill
/// White pill container with a circular background shape highlighting the active language (EN / ID).
class LanguageTogglePill extends StatelessWidget {
  const LanguageTogglePill({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = context.locale.languageCode;
    final isEn = currentLang == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: isDark
            ? Border.all(color: AppColors.darkBorder, width: 0.8)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangCircle(
            text: 'EN',
            isSelected: isEn,
            isDark: isDark,
            onTap: () {
              if (!isEn) {
                context.setLocale(const Locale('en'));
              }
            },
          ),
          const SizedBox(width: 2),
          _LangCircle(
            text: 'ID',
            isSelected: !isEn,
            isDark: isDark,
            onTap: () {
              if (isEn) {
                context.setLocale(const Locale('id'));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LangCircle extends StatelessWidget {
  const _LangCircle({
    required this.text,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF111111)
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF76655C)),
            height: 1,
          ),
        ),
      ),
    );
  }
}
