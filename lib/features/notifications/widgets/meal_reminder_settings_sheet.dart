import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calora_time_picker_sheet.dart';
import '../providers/meal_reminder_provider.dart';

class MealReminderSettingsSheet extends ConsumerWidget {
  const MealReminderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MealReminderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reminders = ref.watch(mealReminderProvider);
    final notifier = ref.read(mealReminderProvider.notifier);

    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final cardBg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF7F9F6);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5E9E2);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Center Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Title Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF5BA300),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengingat Log Makanan',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atur jadwal alarm pengingat harianmu',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF222B22) : const Color(0xFFECEFEA),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Reminder Cards List
              _buildReminderCard(
                context: context,
                title: 'Sarapan Sehat (Breakfast)',
                subtitle: 'Bangun energi harimu tepat waktu',
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF59E0B),
                config: reminders.breakfast,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onToggle: (val) {
                  HapticFeedback.selectionClick();
                  notifier.toggleReminder(MealReminderKind.breakfast, val);
                },
                onPickTime: () async {
                  final res = await CaloraTimePickerSheet.show(
                    context,
                    initialDateTime: DateTime(2026, 1, 1, reminders.breakfast.hour, reminders.breakfast.minute),
                    title: 'Jam Pengingat Sarapan',
                    includeDate: false,
                  );
                  if (res != null) {
                    notifier.updateTime(MealReminderKind.breakfast, res.hour, res.minute);
                  }
                },
              ),
              const SizedBox(height: 12),

              _buildReminderCard(
                context: context,
                title: 'Makan Siang (Lunch)',
                subtitle: 'Jaga stamina dan kalori harianmu',
                icon: Icons.lunch_dining_rounded,
                iconColor: const Color(0xFF10B981),
                config: reminders.lunch,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onToggle: (val) {
                  HapticFeedback.selectionClick();
                  notifier.toggleReminder(MealReminderKind.lunch, val);
                },
                onPickTime: () async {
                  final res = await CaloraTimePickerSheet.show(
                    context,
                    initialDateTime: DateTime(2026, 1, 1, reminders.lunch.hour, reminders.lunch.minute),
                    title: 'Jam Pengingat Makan Siang',
                    includeDate: false,
                  );
                  if (res != null) {
                    notifier.updateTime(MealReminderKind.lunch, res.hour, res.minute);
                  }
                },
              ),
              const SizedBox(height: 12),

              _buildReminderCard(
                context: context,
                title: 'Makan Malam (Dinner)',
                subtitle: 'Evaluasi nutrisi sebelum istirahat',
                icon: Icons.nights_stay_rounded,
                iconColor: const Color(0xFF6366F1),
                config: reminders.dinner,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onToggle: (val) {
                  HapticFeedback.selectionClick();
                  notifier.toggleReminder(MealReminderKind.dinner, val);
                },
                onPickTime: () async {
                  final res = await CaloraTimePickerSheet.show(
                    context,
                    initialDateTime: DateTime(2026, 1, 1, reminders.dinner.hour, reminders.dinner.minute),
                    title: 'Jam Pengingat Makan Malam',
                    includeDate: false,
                  );
                  if (res != null) {
                    notifier.updateTime(MealReminderKind.dinner, res.hour, res.minute);
                  }
                },
              ),
              const SizedBox(height: 22),

              // 4. Test Notification Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await notifier.sendTestReminder();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notifikasi uji coba dikirim! Cek bilah status HP-mu.',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF18261B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Kirim Notifikasi Uji Coba',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.accent : const Color(0xFF18261B),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required MealReminderConfig config,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<bool> onToggle,
    required VoidCallback onPickTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Title + Switch
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: config.enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.accent,
                activeTrackColor: const Color(0xFF18261B),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Modern Digital Time Action Pill
          InkWell(
            onTap: config.enabled ? onPickTime : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: config.enabled
                    ? (isDark ? const Color(0xFF1B261D) : const Color(0xFFEAF5E5))
                    : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFECEFEA)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: config.enabled
                      ? (isDark ? AppColors.accent.withValues(alpha: 0.4) : const Color(0xFF72D000))
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm_rounded,
                    size: 15,
                    color: config.enabled
                        ? (isDark ? AppColors.accent : const Color(0xFF3B7200))
                        : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Alarm: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: config.enabled
                          ? (isDark ? Colors.white70 : const Color(0xFF4B5563))
                          : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  Text(
                    '${config.formatTime()} WIB',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: config.enabled
                          ? (isDark ? AppColors.accent : const Color(0xFF2E6312))
                          : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  const Spacer(),
                  if (config.enabled) ...[
                    Text(
                      'Ubah Jam',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.accent : const Color(0xFF3F7500),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDark ? AppColors.accent : const Color(0xFF3F7500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
