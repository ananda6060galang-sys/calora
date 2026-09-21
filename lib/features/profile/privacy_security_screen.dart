import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// CALORA - PRIVACY & HEALTH DATA SCREEN
///
/// Full page (pushed via MaterialPageRoute) explaining how the app protects
/// the user's health data. Content states only real, verifiable properties
/// of the app (RLS binding, catalog moderation, no ad SDKs), no fabricated
/// compliance or security claims (R-36). Chrome follows the project's
/// full-page pattern: plain back button, left-aligned title.
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accentColor = isDark ? AppColors.accent : const Color(0xFF2E6319);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textPrimary,
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'profile.privacySecurity'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'profile.privacyIntro'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _PrivacyCard(
            icon: Icons.lock_outline_rounded,
            title: 'profile.privacyRlsTitle'.tr(),
            description: 'profile.privacyRlsDesc'.tr(),
            surfaceColor: surfaceColor,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _PrivacyCard(
            icon: Icons.verified_user_outlined,
            title: 'profile.privacyModerationTitle'.tr(),
            description: 'profile.privacyModerationDesc'.tr(),
            surfaceColor: surfaceColor,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _PrivacyCard(
            icon: Icons.phonelink_lock_outlined,
            title: 'profile.privacyLocalTitle'.tr(),
            description: 'profile.privacyLocalDesc'.tr(),
            surfaceColor: surfaceColor,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

// ── PRIVACY CARD ────────────────────────────────────────────────

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
