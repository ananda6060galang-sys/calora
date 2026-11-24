import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../utils/meal_time_resolver.dart';

/// Result returned by [CaloraTimePickerSheet]
class CaloraTimePickerResult {
  final DateTime dateTime;
  final String suggestedMeal;

  const CaloraTimePickerResult({
    required this.dateTime,
    required this.suggestedMeal,
  });

  int get hour => dateTime.hour;
  int get minute => dateTime.minute;
}

/// Ultra-clean Gen-Z Apple-style time picker modal sheet for Calora.
/// Features quiet typography, native Cupertino tumbler wheels, restrained presets,
/// and smooth haptic feedback.
class CaloraTimePickerSheet extends StatefulWidget {
  const CaloraTimePickerSheet({
    super.key,
    required this.initialDateTime,
    this.title = 'Atur Waktu',
    this.includeDate = true,
    this.activeMeal,
  });

  final DateTime initialDateTime;
  final String title;
  final bool includeDate;
  final String? activeMeal;

  /// Shows the modern digital clock sheet and returns the selected [DateTime]
  /// or [CaloraTimePickerResult].
  static Future<CaloraTimePickerResult?> show(
    BuildContext context, {
    required DateTime initialDateTime,
    String title = 'Atur Waktu',
    bool includeDate = true,
    String? activeMeal,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<CaloraTimePickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaloraTimePickerSheet(
        initialDateTime: initialDateTime,
        title: title,
        includeDate: includeDate,
        activeMeal: activeMeal,
      ),
    );
  }

  @override
  State<CaloraTimePickerSheet> createState() => _CaloraTimePickerSheetState();
}

class _CaloraTimePickerSheetState extends State<CaloraTimePickerSheet> {
  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDateTime;
    _selectedHour = widget.initialDateTime.hour;
    _selectedMinute = widget.initialDateTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  DateTime get _currentCombinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
    );
  }

  String get _currentMealSuggestion {
    return MealTimeResolver.resolveCurrentMeal(time: _currentCombinedDateTime);
  }

  void _onHourChanged(int hour) {
    if (_selectedHour != hour) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedHour = hour;
      });
    }
  }

  void _onMinuteChanged(int minute) {
    if (_selectedMinute != minute) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedMinute = minute;
      });
    }
  }

  void _applyPresetTime(int hour, int minute, {DateTime? date}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
      if (date != null) {
        _selectedDate = date;
      }
    });

    if (_hourController.hasClients) {
      _hourController.animateToItem(
        hour,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    if (_minuteController.hasClients) {
      _minuteController.animateToItem(
        minute,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickCustomDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: isDark ? AppColors.accent : const Color(0xFF2E6319),
                  onPrimary: isDark ? const Color(0xFF0F1410) : Colors.white,
                  surface: isDark ? AppColors.darkSurface : Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161B16) : Colors.white;
    final dividerColor =
        isDark ? const Color(0xFF283028) : const Color(0xFFEFEFEF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A1A);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF8A8A8A);
    final brandAccent = isDark ? AppColors.accent : const Color(0xFF2E6319);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. Pill Drag Handle ──
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D352D)
                        : const Color(0xFFD6D6D4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── 2. Apple Top Bar (Batal · Title · Selesai) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final result = CaloraTimePickerResult(
                        dateTime: _currentCombinedDateTime,
                        suggestedMeal: _currentMealSuggestion,
                      );
                      Navigator.pop(context, result);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: brandAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Divider(height: 1, thickness: 0.5, color: dividerColor),

              // ── 3. Date Selector Segment (When includeDate is true) ──
              if (widget.includeDate) ...[
                const SizedBox(height: 12),
                _buildMinimalDateRow(
                  isDark: isDark,
                  dividerColor: dividerColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  brandAccent: brandAccent,
                ),
              ],

              const SizedBox(height: 10),

              // ── 4. Clean Apple Tumbler Wheels (No Boxes, Pure Typography) ──
              SizedBox(
                height: 180,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.22, 0.78, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hour Wheel (00 .. 23)
                      SizedBox(
                        width: 86,
                        child: CupertinoPicker.builder(
                          scrollController: _hourController,
                          itemExtent: 44,
                          diameterRatio: 1.15,
                          squeeze: 1.22,
                          useMagnifier: true,
                          magnification: 1.12,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: _onHourChanged,
                          childCount: 24,
                          itemBuilder: (context, index) {
                            final isSel = index == _selectedHour;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: GoogleFonts.inter(
                                  fontSize: isSel ? 28 : 18,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSel
                                      ? textPrimary
                                      : (isDark
                                          ? const Color(0xFF636D63)
                                          : const Color(0xFFA0A5A0)),
                                  letterSpacing: isSel ? -0.5 : 0.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Colon separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          ':',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),

                      // Minute Wheel (00 .. 59)
                      SizedBox(
                        width: 86,
                        child: CupertinoPicker.builder(
                          scrollController: _minuteController,
                          itemExtent: 44,
                          diameterRatio: 1.15,
                          squeeze: 1.22,
                          useMagnifier: true,
                          magnification: 1.12,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: _onMinuteChanged,
                          childCount: 60,
                          itemBuilder: (context, index) {
                            final isSel = index == _selectedMinute;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: GoogleFonts.inter(
                                  fontSize: isSel ? 28 : 18,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSel
                                      ? textPrimary
                                      : (isDark
                                          ? const Color(0xFF636D63)
                                          : const Color(0xFFA0A5A0)),
                                  letterSpacing: isSel ? -0.5 : 0.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 5. Quick Presets Row (3D Tactile pills) ──
              _buildMinimalPresetsRow(
                isDark: isDark,
                dividerColor: dividerColor,
                textSecondary: textSecondary,
                textPrimary: textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Minimal Date Selector Row ──────────────────────────────────────────

  Widget _buildMinimalDateRow({
    required bool isDark,
    required Color dividerColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color brandAccent,
  }) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final isToday = DateUtils.isSameDay(_selectedDate, now);
    final isYesterday = DateUtils.isSameDay(_selectedDate, yesterday);
    final isOther = !isToday && !isYesterday;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDateSegmentPill(
          label: 'Hari Ini',
          isSelected: isToday,
          isDark: isDark,
          dividerColor: dividerColor,
          brandAccent: brandAccent,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDate = now);
          },
        ),
        const SizedBox(width: 8),
        _buildDateSegmentPill(
          label: 'Kemarin',
          isSelected: isYesterday,
          isDark: isDark,
          dividerColor: dividerColor,
          brandAccent: brandAccent,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDate = yesterday);
          },
        ),
        const SizedBox(width: 8),
        _buildDateSegmentPill(
          label: isOther
              ? DateFormat('dd MMM').format(_selectedDate)
              : 'Pilih Tanggal',
          isSelected: isOther,
          isDark: isDark,
          dividerColor: dividerColor,
          brandAccent: brandAccent,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: _pickCustomDate,
        ),
      ],
    );
  }

  Widget _buildDateSegmentPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color dividerColor,
    required Color brandAccent,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.accent.withValues(alpha: 0.16)
                  : const Color(0xFFEAF5E5))
              : (isDark
                  ? const Color(0xFF1D241D)
                  : const Color(0xFFF4F4F3)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? AppColors.accent.withValues(alpha: 0.40)
                    : const Color(0xFFC7EBAF))
                : dividerColor,
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? brandAccent : textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Minimal Presets Row ───────────────────────────────────────────────────

  Widget _buildMinimalPresetsRow({
    required bool isDark,
    required Color dividerColor,
    required Color textSecondary,
    required Color textPrimary,
  }) {
    final now = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPresetPill(
            label: 'Sekarang',
            isDark: isDark,
            dividerColor: dividerColor,
            textSecondary: textSecondary,
            onTap: () => _applyPresetTime(now.hour, now.minute),
          ),
          const SizedBox(width: 6),
          _buildPresetPill(
            label: '-30m',
            isDark: isDark,
            dividerColor: dividerColor,
            textSecondary: textSecondary,
            onTap: () {
              final adjusted = now.subtract(const Duration(minutes: 30));
              _applyPresetTime(adjusted.hour, adjusted.minute);
            },
          ),
          const SizedBox(width: 6),
          _buildPresetPill(
            label: 'Sarapan 08:00',
            isDark: isDark,
            dividerColor: dividerColor,
            textSecondary: textSecondary,
            onTap: () => _applyPresetTime(8, 0),
          ),
          const SizedBox(width: 6),
          _buildPresetPill(
            label: 'Siang 12:30',
            isDark: isDark,
            dividerColor: dividerColor,
            textSecondary: textSecondary,
            onTap: () => _applyPresetTime(12, 30),
          ),
          const SizedBox(width: 6),
          _buildPresetPill(
            label: 'Malam 19:00',
            isDark: isDark,
            dividerColor: dividerColor,
            textSecondary: textSecondary,
            onTap: () => _applyPresetTime(19, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPill({
    required String label,
    required bool isDark,
    required Color dividerColor,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D241D) : const Color(0xFFF4F4F3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: dividerColor, width: 0.7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ),
    );
  }
}
