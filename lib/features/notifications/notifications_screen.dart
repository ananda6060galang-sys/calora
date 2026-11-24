import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/calora_time_picker_sheet.dart';
import '../diary/food_diary_screen.dart';
import '../profile/personal_information_screen.dart';
import 'providers/meal_reminder_provider.dart';
import 'providers/notifications_provider.dart';

/// CALORA - NOTIFICATIONS SCREEN
///
/// Ultra-clean, Gen-Z minimalist Apple-inspired UI:
/// - Restrained typography (no oversized numbers, max 16px)
/// - Single unified inset card for meal reminders
/// - Crisp hairline dividers (0.5px) and native Cupertino switches
/// - Zero visual clutter, distraction-free focus
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

  Future<void> _pickMealTime(
    MealReminderKind kind,
    MealReminderConfig config,
  ) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = DateTime(
      now.year,
      now.month,
      now.day,
      config.hour,
      config.minute,
    );

    final String title;
    switch (kind) {
      case MealReminderKind.breakfast:
        title = 'Waktu Sarapan';
        break;
      case MealReminderKind.lunch:
        title = 'Waktu Makan Siang';
        break;
      case MealReminderKind.dinner:
        title = 'Waktu Makan Malam';
        break;
    }

    final result = await CaloraTimePickerSheet.show(
      context,
      initialDateTime: initial,
      title: title,
      includeDate: false,
      activeMeal: kind.name,
    );

    if (result != null && mounted) {
      HapticFeedback.lightImpact();
      await ref.read(mealReminderProvider.notifier).updateTime(
            kind,
            result.hour,
            result.minute,
          );
    }
  }

  Future<void> _sendTestReminder() async {
    HapticFeedback.mediumImpact();
    await ref.read(mealReminderProvider.notifier).sendTestReminder();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notifikasi uji coba terkirim.',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1E241E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final mealReminders = ref.watch(mealReminderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF9F9F8);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final dividerColor = isDark ? const Color(0xFF283028) : const Color(0xFFEFEFEF);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? AppColors.darkTextSecondary : const Color(0xFF8A8A8A);
    final brandAccent = isDark ? AppColors.accent : const Color(0xFF2E6319);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: textPrimary,
          ),
        ),
        title: Text(
          'notifications.title'.tr(),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        children: [
          // ── SECTION 1: PENGINGAT MAKAN ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PENGINGAT MAKAN',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),

          // Single Clean Minimalist Inset Card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor, width: 0.8),
            ),
            child: Column(
              children: [
                _MinimalMealRow(
                  label: 'Sarapan',
                  config: mealReminders.breakfast,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  dividerColor: dividerColor,
                  brandAccent: brandAccent,
                  onToggle: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(mealReminderProvider.notifier).toggleReminder(
                          MealReminderKind.breakfast,
                          val,
                        );
                  },
                  onTapTime: () => _pickMealTime(
                    MealReminderKind.breakfast,
                    mealReminders.breakfast,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Divider(height: 1, thickness: 0.5, color: dividerColor),
                ),
                _MinimalMealRow(
                  label: 'Makan Siang',
                  config: mealReminders.lunch,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  dividerColor: dividerColor,
                  brandAccent: brandAccent,
                  onToggle: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(mealReminderProvider.notifier).toggleReminder(
                          MealReminderKind.lunch,
                          val,
                        );
                  },
                  onTapTime: () => _pickMealTime(
                    MealReminderKind.lunch,
                    mealReminders.lunch,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Divider(height: 1, thickness: 0.5, color: dividerColor),
                ),
                _MinimalMealRow(
                  label: 'Makan Malam',
                  config: mealReminders.dinner,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  dividerColor: dividerColor,
                  brandAccent: brandAccent,
                  onToggle: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(mealReminderProvider.notifier).toggleReminder(
                          MealReminderKind.dinner,
                          val,
                        );
                  },
                  onTapTime: () => _pickMealTime(
                    MealReminderKind.dinner,
                    mealReminders.dinner,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Clean footnote & test link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengingat harian otomatis',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: textSecondary,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _sendTestReminder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Tes Notifikasi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: brandAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 2: AKTIVITAS & CATATAN ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'AKTIVITAS & CATATAN',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),

          if (reminders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: brandAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Semua catatan sudah rapi',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor, width: 0.8),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < reminders.length; i++) ...[
                    _MinimalNotificationRow(
                      reminder: reminders[i],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      brandAccent: brandAccent,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        switch (reminders[i].kind) {
                          case ReminderKind.logMeal:
                          case ReminderKind.protein:
                            FoodDiaryScreen.openAddFoodSheet(context, ref);
                            break;
                          case ReminderKind.weight:
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PersonalInformationScreen(),
                              ),
                            );
                            break;
                          case ReminderKind.streak:
                            break;
                        }
                      },
                    ),
                    if (i < reminders.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Divider(height: 1, thickness: 0.5, color: dividerColor),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── MINIMAL MEAL ROW ─────────────────────────────────────────────

class _MinimalMealRow extends StatelessWidget {
  const _MinimalMealRow({
    required this.label,
    required this.config,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.brandAccent,
    required this.onToggle,
    required this.onTapTime,
  });

  final String label;
  final MealReminderConfig config;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final Color brandAccent;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // Meal label
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: config.enabled
                    ? textPrimary
                    : textSecondary.withValues(alpha: 0.45),
              ),
            ),
          ),

          // Clean time pill button (tap to open wheel)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF4F4F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: config.enabled
                      ? (isDark ? AppColors.accent.withValues(alpha: 0.3) : const Color(0xFFD8E6D3))
                      : dividerColor,
                  width: 0.7,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.formatTime(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: config.enabled
                          ? textPrimary
                          : textSecondary.withValues(alpha: 0.45),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: config.enabled
                        ? textSecondary
                        : textSecondary.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Compact Cupertino switch
          Transform.scale(
            scale: 0.82,
            child: CupertinoSwitch(
              value: config.enabled,
              activeTrackColor: isDark ? AppColors.accent : const Color(0xFF34C759),
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── MINIMAL NOTIFICATION ROW ─────────────────────────────────────

class _MinimalNotificationRow extends StatelessWidget {
  const _MinimalNotificationRow({
    required this.reminder,
    required this.textPrimary,
    required this.textSecondary,
    required this.brandAccent,
    required this.onTap,
  });

  final AppReminder reminder;
  final Color textPrimary;
  final Color textSecondary;
  final Color brandAccent;
  final VoidCallback onTap;

  Color _accentColor() {
    switch (reminder.kind) {
      case ReminderKind.logMeal:
        return brandAccent;
      case ReminderKind.protein:
        return AppColors.protein;
      case ReminderKind.weight:
        return AppColors.lavender;
      case ReminderKind.streak:
        return AppColors.carbs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _accentColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Minimal color indicator dot
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reminder.titleKey.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    reminder.bodyKey.tr(args: reminder.bodyArgs),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Subtle chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
