import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';
import '../theme/app_colors.dart';

/// Unified user greeting header used across Dashboard and Workout screens.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.profile,
    required this.isDark,
    this.onSearchTap,
    this.onNotificationTap,
    this.showSearch = true,
    this.showNotification = true,
  });

  final UserProfile profile;
  final bool isDark;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final bool showSearch;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    final displayName =
        profile.name.trim().isNotEmpty ? profile.name.trim() : 'Calora User';
    final initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

    return Row(
      children: [
        // User Avatar Circle (Accent with dark contrasting letter)
        Container(
          height: 44,
          width: 44,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initialLetter,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0E0F10), // Dark color on lime
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting & Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'dashboard.hello'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),

        if (showSearch) ...[
          const SizedBox(width: 10),
          _HeaderCircleButton(
            icon: Icons.search_rounded,
            isDark: isDark,
            onTap: onSearchTap,
          ),
        ],

        if (showNotification) ...[
          const SizedBox(width: 8),
          _HeaderCircleButton(
            icon: Icons.notifications_none_rounded,
            isDark: isDark,
            onTap: onNotificationTap,
          ),
        ],
      ],
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.72),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color:
                          AppColors.lightTextPrimary.withValues(alpha: 0.055),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
