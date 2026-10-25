import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'providers/notifications_provider.dart';

/// CALORA - NOTIFICATIONS SCREEN
///
/// In-app reminders derived from the user's own local data (diary, weight
/// logs, streak). Read-only, no fabricated entries: an empty list shows an
/// honest "all caught up" state. Chrome follows the project's full-page
/// pattern (plain back button, left-aligned title).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reminders = ref.read(remindersProvider);
      ref.read(viewedNotificationsProvider.notifier).markAllAsViewed(reminders);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
            'notifications.title'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: reminders.isEmpty
          ? _EmptyState(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: reminders.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) => _ReminderCard(
                reminder: reminders[index],
                isDark: isDark,
                surfaceColor: surfaceColor,
                dividerColor: dividerColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
    );
  }
}

// ── EMPTY STATE ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceColor,
    required this.dividerColor,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: dividerColor, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'notifications.emptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'notifications.emptyBody'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── REMINDER CARD ───────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final AppReminder reminder;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  ({Color tint, IconData icon}) _visual() {
    switch (reminder.kind) {
      case ReminderKind.logMeal:
        return (
          tint: isDark ? AppColors.accent : const Color(0xFF2E6319),
          icon: Icons.restaurant_menu_rounded,
        );
      case ReminderKind.protein:
        return (tint: AppColors.protein, icon: Icons.egg_alt_outlined);
      case ReminderKind.weight:
        return (tint: AppColors.fat, icon: Icons.monitor_weight_outlined);
      case ReminderKind.streak:
        return (
          tint: AppColors.carbs,
          icon: Icons.local_fire_department_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual();

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
              color: visual.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, size: 22, color: visual.tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.titleKey.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.bodyKey.tr(args: reminder.bodyArgs),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.4,
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
