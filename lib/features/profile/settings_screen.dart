import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../models/user_profile.dart';
import '../auth/login_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import 'profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.locale.languageCode == 'id' ? 'Pengaturan' : 'Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? const Color(0xFF2C4A26) // Dark sage
                        : const Color.fromARGB(255, 214, 253, 150), // Light sage / soft green
                    bgColor.withValues(alpha: 0.0), // Fade to bg
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
            // ── SETTINGS LIST ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: dividerColor, width: 0.5),
              ),
              child: Column(
                children: [
                  _SettingsOptionRow(
                    icon: Icons.person_outline_rounded,
                    title: 'onboarding.personalInfoTitle'.tr(),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () => _openEditProfile(context, profile),
                  ),
                  _SettingsOptionRow(
                    icon: Icons.flag_outlined,
                    title: 'profile.goalsAndNutrition'.tr(),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () => _openEditProfile(context, profile),
                  ),
                  _SettingsOptionRow(
                    icon: Icons.palette_outlined,
                    title: 'profile.appearance'.tr(),
                    trailing: _themeModeLabel(themeMode),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () => _showAppearancePicker(
                      context,
                      ref,
                      themeMode,
                      isDark,
                    ),
                  ),
                  _SettingsOptionRow(
                    icon: Icons.translate_rounded,
                    title: 'profile.language'.tr(),
                    trailing: context.locale.languageCode == 'en'
                        ? 'English'
                        : 'Indonesian',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () => _showLanguagePicker(context, isDark),
                  ),
                  _SettingsOptionRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'profile.notifications'.tr(),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notifications settings updated'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _SettingsOptionRow(
                    icon: Icons.info_outline_rounded,
                    title: 'profile.aboutCalora'.tr(),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: false,
                    onTap: () => _showAbout(context, isDark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ── LOG OUT BUTTON ─────────────────────────────────
            GestureDetector(
              onTap: () => _confirmLogOut(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'profile.logOut'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── APP VERSION ────────────────────────────────────
            Center(
              child: Text(
                'Calora v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'profile.theme.light'.tr();
      case ThemeMode.dark:
        return 'profile.theme.dark'.tr();
      case ThemeMode.system:
        return 'profile.theme.system'.tr();
    }
  }

  void _openEditProfile(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  void _showAppearancePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'profile.appearance'.tr(),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            for (final entry in [
              (
                ThemeMode.light,
                'profile.theme.light'.tr(),
                Icons.light_mode_outlined,
              ),
              (
                ThemeMode.dark,
                'profile.theme.dark'.tr(),
                Icons.dark_mode_outlined,
              ),
              (
                ThemeMode.system,
                'profile.theme.system'.tr(),
                Icons.brightness_auto_outlined,
              ),
            ])
              _SettingsPickerRow(
                icon: entry.$3,
                label: entry.$2,
                selected: current == entry.$1,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {
                  ref.read(themeModeProvider.notifier).state = entry.$1;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'profile.language'.tr(),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _SettingsPickerRow(
              icon: Icons.translate_rounded,
              label: 'English',
              selected: context.locale.languageCode == 'en',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            _SettingsPickerRow(
              icon: Icons.translate_rounded,
              label: 'Indonesian',
              selected: context.locale.languageCode == 'id',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () {
                context.setLocale(const Locale('id'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, bool isDark) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Calora',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A modern calorie & gym workout tracking mobile app designed to help you reach your body goals with precision.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Built with Flutter & Supabase',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogOut(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logout.png',
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'profile.logOutConfirmTitle'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'profile.logOutConfirmMessage'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: borderColor),
                        foregroundColor: textPrimary,
                      ),
                      child: Text(
                        'profile.cancel'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        try {
                          await ref.read(authServiceProvider).signOut();
                        } catch (_) {}

                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'profile.logOut'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _SettingsOptionRow extends StatelessWidget {
  const _SettingsOptionRow({
    required this.icon,
    required this.title,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.showDivider,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  Text(
                    trailing!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Divider(height: 0.5, thickness: 0.5, color: dividerColor),
          ),
      ],
    );
  }
}

class _SettingsPickerRow extends StatelessWidget {
  const _SettingsPickerRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
