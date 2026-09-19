import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/widgets/food_card.dart';
import '../../core/widgets/progress_ring.dart';

import '../../models/food.dart';

import '../dashboard/providers/profile_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/food_search_provider.dart';
import 'food_request_sheet.dart';
import 'widgets/ai_scanner_sheet.dart';
import 'widgets/barcode_scanner_screen.dart';

/// Auto-detects the default main meal type based on local device time:
/// Snack tidak memiliki jadwal otomatis; hanya dipilih saat pengguna mengkliknya.
/// - 05:00 - 10:59 -> Breakfast
/// - 11:00 - 16:59 -> Lunch
/// - 17:00 - 04:59 -> Dinner
String getDefaultMealType(DateTime currentTime) {
  final hour = currentTime.hour;
  final minute = currentTime.minute;
  final totalMinutes = hour * 60 + minute;

  if (totalMinutes >= 5 * 60 && totalMinutes < 11 * 60) {
    return 'Breakfast';
  } else if (totalMinutes >= 11 * 60 && totalMinutes < 17 * 60) {
    return 'Lunch';
  } else {
    return 'Dinner';
  }
}

String _mealLabel(String? meal) {
  if (meal == null || meal.isEmpty) return '';
  switch (meal.toLowerCase()) {
    case 'breakfast':
      return 'diary.meals.breakfast'.tr();
    case 'lunch':
      return 'diary.meals.lunch'.tr();
    case 'snack':
      return 'diary.meals.snack'.tr();
    case 'dinner':
      return 'diary.meals.dinner'.tr();
    default:
      return meal;
  }
}

class FoodDiaryScreen extends ConsumerWidget {
  final bool showBackButton;

  const FoodDiaryScreen({super.key, this.showBackButton = true});

  /// Static helper to directly open the Add/Search Food sheet from anywhere.
  static void openAddFoodSheet(
    BuildContext context,
    WidgetRef ref, {
    String? meal,
    DateTime? date,
    Food? initialFood,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodSheet(
        meal: meal,
        ref: ref,
        date: date ?? DateTime.now(),
        initialFood: initialFood,
      ),
    );
  }

  /// Static helper to directly open the Barcode Scanner Sheet from anywhere.
  static void openBarcodeScanner(
    BuildContext context, {
    String? meal,
    DateTime? date,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerScreen(
          meal: meal,
          date: date ?? DateTime.now(),
        ),
      ),
    );
  }

  /// Static helper to directly open the Phase 5 AI Scanner Sheet from anywhere.
  static void openAiScannerSheet(
    BuildContext context, {
    String? meal,
    DateTime? date,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AiScannerSheet(
          initialMeal: meal,
          date: date ?? DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBg
          : const Color(0xFFF8F9FB), // Clean off-white background
      body: FoodDiaryScreenBody(showBackButton: showBackButton),
    );
  }
}

class FoodDiaryScreenBody extends ConsumerStatefulWidget {
  final bool showBackButton;
  const FoodDiaryScreenBody({super.key, this.showBackButton = true});

  @override
  ConsumerState<FoodDiaryScreenBody> createState() =>
      _FoodDiaryScreenBodyState();
}

class _FoodDiaryScreenBodyState extends ConsumerState<FoodDiaryScreenBody> {
  static const _meals = [
    'Breakfast',
    'Lunch',
    'Snack',
    'Dinner',
  ]; // Matching reference
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(diaryEntriesForDateProvider(_selectedDate));
    final profile = ref.watch(userProfileProvider);
    final totals = ref.watch(diaryTotalsForDateProvider(_selectedDate));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetCals = profile.dailyCalorieTarget.round();
    final consumedCals = totals.calories;
    final progress = targetCals > 0 ? (consumedCals / targetCals) : 0.0;

    return Stack(
      children: [
        // Soft gradient hero background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 460,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? const Color(0xFF1C2B1E) // Dark botanical sage
                      : const Color.fromARGB(
                          255,
                          214,
                          253,
                          150,
                        ), // Light sage / soft green
                  (isDark ? AppColors.darkBg : const Color(0xFFF8F9FB))
                      .withValues(alpha: 0.0), // Fade to bg
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              if (widget.showBackButton)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: isDark ? AppColors.darkTextPrimary : Colors.black,
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 36),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Set your daily meal plan" + Image
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text(
                                'diary.setDailyMealPlan'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : const Color(0xFF1E2022),
                                  height: 1.25,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: Image.asset(
                                'assets/head.webp',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search bar & AI Scan button row (matching reference)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Row(
                          children: [
                            // White pill search bar
                            Expanded(
                              child: GestureDetector(
                                onTap: () => FoodDiaryScreen.openAddFoodSheet(
                                  context,
                                  ref,
                                  date: _selectedDate,
                                ),
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : const Color(0xFF8E95A2),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'diary.searchBarPlaceholder'.tr(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : const Color(0xFF8E95A2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Lime rounded scanner button
                            GestureDetector(
                              onTap: () => FoodDiaryScreen.openAiScannerSheet(
                                context,
                                date: _selectedDate,
                              ),
                              child: Container(
                                height: 44,
                                width: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.crop_free_rounded,
                                      color: isDark ? const Color(0xFF0F1410) : Colors.white,
                                      size: 26,
                                    ),
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: isDark ? const Color(0xFF0F1410) : Colors.white,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Calendar Card
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // 1. Active Month & Year Header (Tap to open full Calendar)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: Theme.of(context)
                                                    .colorScheme
                                                    .copyWith(
                                                      primary: AppColors.accent,
                                                      onPrimary: const Color(
                                                        0xFF0F1410,
                                                      ),
                                                    ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(
                                            () => _selectedDate = picked,
                                          );
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'MMMM yyyy',
                                            ).format(_selectedDate),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? AppColors.darkTextPrimary
                                                      : Colors.black,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 2. Horizontal scrollable months list (Full Width)
                              SizedBox(
                                height: 44,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: List.generate(12, (index) {
                                      final monthIndex = index + 1;
                                      final date = DateTime(
                                        _selectedDate.year,
                                        monthIndex,
                                        1,
                                      );
                                      final isSelected =
                                          date.month == _selectedDate.month &&
                                          date.year == _selectedDate.year;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: index == 0 ? 24 : 10,
                                          right: index == 11 ? 24 : 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              final daysInMonth =
                                                  DateUtils.getDaysInMonth(
                                                    date.year,
                                                    date.month,
                                                  );
                                              final day = _selectedDate.day
                                                  .clamp(1, daysInMonth);
                                              _selectedDate = DateTime(
                                                date.year,
                                                date.month,
                                                day,
                                              );
                                            });
                                          },
                                          child: _monthText(
                                            context,
                                            DateFormat('MMM').format(date),
                                            isSelected,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Day selector
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 7,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final date = _selectedDate.subtract(
                                        Duration(days: 3 - index),
                                      );
                                      final isSelected = DateUtils.isSameDay(
                                        date,
                                        _selectedDate,
                                      );

                                      // Get progress for this specific day to draw the bottom progress fill
                                      final dayTotals = ref.watch(
                                        diaryTotalsForDateProvider(date),
                                      );
                                      final dayTarget = profile
                                          .dailyCalorieTarget
                                          .round();
                                      final dayProgress = dayTarget > 0
                                          ? (dayTotals.calories / dayTarget)
                                          : 0.0;

                                      return _DayCard(
                                        date: date,
                                        isSelected: isSelected,
                                        progress: dayProgress,
                                        onTap: () => setState(
                                          () => _selectedDate = date,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Nutrition Summary (Consumed Today)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ProgressRing(
                                progress: progress,
                                size: 110,
                                strokeWidth: 12,
                                gradientColors: const [
                                  Color(0xFFC3F53C), // Bright lime
                                  Color(0xFF5ED636), // Vibrant green
                                ],
                                color: AppColors.accent,
                                trackColor: isDark
                                    ? AppColors.darkSurfaceAlt
                                    : const Color(0xFFF3F3F3),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$consumedCals',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.0,
                                            height: 1.0,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'dashboard.ofTarget'.tr(
                                        args: ['$targetCals'],
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : const Color(0xFF999999),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _MacroRow(
                                      label: 'dashboard.protein'.tr(),
                                      consumed: totals.proteinG,
                                      target: profile.proteinTargetG,
                                    ),
                                    const SizedBox(height: 12),
                                    _MacroRow(
                                      label: 'dashboard.carbs'.tr(),
                                      consumed: totals.carbsG,
                                      target: profile.carbsTargetG,
                                    ),
                                    const SizedBox(height: 12),
                                    _MacroRow(
                                      label: 'dashboard.fat'.tr(),
                                      consumed: totals.fatG,
                                      target: profile.fatTargetG,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Meal Cards
                      ..._meals.asMap().entries.map((entry) {
                        final index = entry.key;
                        final meal = entry.value;
                        final mealEntries = entries
                            .where((e) => e.meal == meal)
                            .toList();
                        return _MealCard(
                          meal: meal,
                          items: mealEntries,
                          isReversed: index % 2 != 0, // Alternate layout
                          onAddTap: () => _openAddFoodSheet(
                            context,
                            ref,
                            meal,
                            _selectedDate,
                          ),
                          onDeleteTap: (id) =>
                              ref.read(diaryProvider.notifier).remove(id),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openAddFoodSheet(
    BuildContext context,
    WidgetRef ref,
    String? meal,
    DateTime date,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodSheet(meal: meal, ref: ref, date: date),
    );
  }

  Widget _monthText(BuildContext context, String text, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.darkTextPrimary : Colors.black)
                : (isDark ? AppColors.darkTextTertiary : Colors.black54),
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 32,
            color: isDark ? AppColors.accent : Colors.black,
          ),
        ] else ...[
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.isSelected,
    required this.progress,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : Colors.transparent, // Brand accent for selected
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : (isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE9ECEF)), // Subtle outline
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Bottom Progress Fill (only for unselected days)
              if (!isSelected && progress > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80 * progress.clamp(0.0, 1.0),
                  child: Container(
                    color: AppColors.accent.withValues(
                      alpha: 0.15,
                    ), // Soft brand green vertical progress fill
                  ),
                ),
              // Text Content
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF0F1410)
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.black54),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF0F1410)
                            : (isDark ? AppColors.darkTextPrimary : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// KONFIGURASI GAMBAR MEAL CARD (Ganti Asset & Ukuran di Sini)
// =============================================================
/// Jalur asset gambar per kategori makan.
/// Anda dapat mengganti path di bawah ini sesuai keinginan.
const Map<String, String> _mealAssetPaths = {
  'breakfast': 'assets/breakfast.webp',
  'lunch': 'assets/Lunch.webp',
  'dinner': 'assets/Dinner.webp',
  'snack': 'assets/Snack.webp', // Bebas diganti ke asset gambar lain
};

/// Ukuran gambar (px) per kategori makan.
/// Anda dapat menyesuaikan angka di bawah ini untuk mengubah ukuran masing-masing gambar.
const Map<String, double> _mealImageSizes = {
  'breakfast': 110.0,
  'lunch': 98.0,
  'dinner': 115.0,
  'snack': 85.0,
};

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.items,
    required this.isReversed,
    required this.onAddTap,
    required this.onDeleteTap,
  });

  final String meal;
  final List<DiaryEntry> items;
  final bool isReversed;
  final VoidCallback onAddTap;
  final Function(String) onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cals = items.fold(0, (sum, item) => sum + item.calories);

    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top half (like reference card)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: isReversed
                  ? [
                      _buildImage(context, isDark, cals),
                      const SizedBox(width: 16),
                      _buildContent(context, cals),
                    ]
                  : [
                      _buildContent(context, cals),
                      const SizedBox(width: 16),
                      _buildImage(context, isDark, cals),
                    ],
            ),
          ),

          // Logged Items
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'diary.loggedFoods'.tr(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFFAAAAAA),
                              letterSpacing: 0.5,
                            ),
                      ),
                      Text(
                        'diary.itemCount'.tr(args: ['${items.length}']),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFFAAAAAA),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16), // 16px gap
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => onDeleteTap(item.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        child: FoodCard(
                          name: item.food.name,
                          serving:
                              '${item.servings == item.servings.toInt() ? item.servings.toInt() : item.servings} x ${item.food.servingLabel}',
                          calories: item.calories,
                          protein: item.proteinG,
                          carbs: item.carbsG,
                          fat: item.fatG,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, int cals) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String rec = 'diary.recommendedCal'.tr(args: ['830-1170']);
    if (meal == 'Lunch') rec = 'diary.recommendedCal'.tr(args: ['255-370']);
    if (meal == 'Dinner') rec = 'diary.recommendedCal'.tr(args: ['255-370']);

    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: isReversed
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isReversed
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  _mealLabel(meal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (cals > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '• $cals Cal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rec,
            textAlign: isReversed ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // + Add Button (Premium Pill)
          Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onAddTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  'diary.add'.tr(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF0F1410),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isDark, int cals) {
    final lowerMeal = meal.toLowerCase();
    final assetPath = _mealAssetPaths[lowerMeal] ?? 'assets/breakfast.webp';
    final imageSize = _mealImageSizes[lowerMeal] ?? 110.0;
    const double circleBgSize = 90.0;
    final maxBounds = imageSize > circleBgSize ? imageSize : circleBgSize;

    return Expanded(
      flex: 2,
      child: Align(
        alignment: isReversed ? Alignment.centerLeft : Alignment.centerRight,
        child: SizedBox(
          width: maxBounds,
          height: maxBounds,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Independent fixed gradient background circle (90x90)
              Container(
                width: circleBgSize,
                height: circleBgSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withValues(alpha: 0.2),
                      AppColors.accent.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Picture asset with independent size
              Image.asset(
                assetPath,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.restaurant_rounded,
                    color: Theme.of(
                      context,
                    ).disabledColor.withValues(alpha: 0.3),
                    size: 48,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.consumed,
    required this.target,
  });

  final String label;
  final double consumed;
  final double target;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    // Pastel/muted tonal colors
    Color dotColor;
    if (label == 'Protein' || label == 'dashboard.protein'.tr()) {
      dotColor = const Color(0xFFFF8B7B); // Soft coral
    } else if (label == 'Carbs' || label == 'dashboard.carbs'.tr()) {
      dotColor = const Color(0xFFFFC04D); // Soft amber
    } else {
      dotColor = const Color(0xFF7BAAF7); // Soft blue
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4, // Thinner fully rounded bar
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceAlt.withValues(alpha: 0.5)
                  : const Color(0xFFF3F3F3), // very light subtle track
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: p,
              child: Container(
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '${consumed.round()}'),
              TextSpan(
                text: '/${target.round()}g',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Add Food Bottom Sheet (Matching clean nutrition label) ──────────

class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet({
    super.key,
    this.meal,
    required this.ref,
    required this.date,
    this.initialFood,
  });

  final String? meal;
  final WidgetRef ref;
  final DateTime date;
  final Food? initialFood;

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  final TextEditingController _searchController = TextEditingController();
  Food? _selectedFood;
  FoodServing? _selectedServing;
  bool _isLoadingDetails = false;
  double _servings = 1.0;
  late String _selectedMeal;
  bool _isCtaPressed = false;
  bool _isCustomServing = false;
  late TextEditingController _customServingController;

  @override
  void initState() {
    super.initState();
    if (widget.meal != null && widget.meal!.trim().isNotEmpty) {
      _selectedMeal = widget.meal!;
    } else {
      _selectedMeal = getDefaultMealType(DateTime.now());
    }
    _customServingController = TextEditingController(text: '1.0');
    if (widget.initialFood != null) {
      _selectedFood = widget.initialFood;
      if (widget.initialFood!.servings.isNotEmpty) {
        _selectedServing = widget.initialFood!.servings.first;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customServingController.dispose();
    super.dispose();
  }

  Future<void> _onSelectFood(Food food) async {
    setState(() {
      _selectedFood = food;
      _servings = 1.0;
      _isCustomServing = false;
      _customServingController.text = '1.0';
      _selectedServing = null;
    });

    // If the food has no servings list or comes from search, fetch full details
    if (food.servings.isEmpty && food.source == 'fatsecret') {
      setState(() => _isLoadingDetails = true);
      try {
        final details = await ref
            .read(foodSearchServiceProvider)
            .getFoodDetails(food.id);
        if (mounted && details != null && _selectedFood?.id == food.id) {
          setState(() {
            _selectedFood = details;
            if (details.servings.isNotEmpty) {
              _selectedServing = details.servings.first;
            }
            _isLoadingDetails = false;
          });
          return;
        }
      } catch (_) {
        // Continue with initial food data on failure
      }
      if (mounted) setState(() => _isLoadingDetails = false);
    } else if (food.servings.isNotEmpty) {
      _selectedServing = food.servings.first;
    }
  }

  void _addFood() {
    if (_selectedFood == null) return;

    final baseFood = _selectedFood!;
    final serving = _selectedServing;

    // Determine active base calories and macros
    final baseCalories = serving?.calories ?? baseFood.calories;
    final baseProtein = serving?.proteinG ?? baseFood.proteinG;
    final baseCarbs = serving?.carbsG ?? baseFood.carbsG;
    final baseFat = serving?.fatG ?? baseFood.fatG;
    final servingLabel = serving?.servingDescription ?? baseFood.servingLabel;

    // Determine total portion grams
    double? totalGrams;
    if (serving != null &&
        serving.metricServingAmount != null &&
        serving.metricServingUnit?.toLowerCase() == 'g') {
      totalGrams = serving.metricServingAmount! * _servings;
    } else if (baseFood.portionGrams != null) {
      totalGrams = baseFood.portionGrams! * _servings;
    } else {
      final match = RegExp(r'(\d+(?:\.\d+)?)\s*g\b', caseSensitive: false)
          .firstMatch(servingLabel);
      if (match != null) {
        final g = double.tryParse(match.group(1)!);
        if (g != null) totalGrams = g * _servings;
      }
    }

    final entryFood = Food(
      id: baseFood.id,
      name: baseFood.name,
      servingLabel: servingLabel,
      calories: baseCalories,
      proteinG: baseProtein,
      carbsG: baseCarbs,
      fatG: baseFat,
      category: baseFood.category,
      portionGrams: totalGrams != null ? (totalGrams / _servings) : null,
      source: baseFood.source,
      servings: baseFood.servings,
    );

    widget.ref.read(diaryProvider.notifier).add(
          entryFood,
          _servings,
          _selectedMeal,
          widget.date,
          portionGrams: totalGrams,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(foodSearchProvider);

    final accentColor = isDark
        ? const Color(0xFF3DDC84)
        : const Color(0xFF2C5E3B);

    if (_selectedFood != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildFoodDetails(context, isDark, accentColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.90,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header: ← Lunch
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _mealLabel(_selectedMeal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Clean integrated search field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        hintText: 'diary.searchFoods'.tr(),
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minHeight: 40,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  ref
                                      .read(foodSearchProvider.notifier)
                                      .onQueryChanged('');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () => _openScanOptions(context, isDark),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, right: 14),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        ref.read(foodSearchProvider.notifier).onQueryChanged(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Attribution strip & offline fallback banner
                if (searchState.isFallback)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'diary.offlineNotice'.tr(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content Area: Editorial List
                Expanded(child: _buildSearchBody(context, searchState, isDark)),

                // Dynamic Provider Attribution footer
                _buildProviderAttribution(searchState, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openScanOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          14,
          24,
          MediaQuery.of(modalCtx).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF0F1F3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'diary.scanFood'.tr(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 18),

            // Option 1: Scan Barcode (Packaged food)
            InkWell(
              onTap: () async {
                Navigator.pop(modalCtx);
                final scannedFood = await Navigator.of(context).push<Food>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => BarcodeScannerScreen(
                      meal: _selectedMeal,
                      date: widget.date,
                    ),
                  ),
                );
                if (scannedFood != null && mounted) {
                  _onSelectFood(scannedFood);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 22,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'diary.scanBarcode'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'diary.packagedFood'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark
                  ? AppColors.darkBorder
                  : const Color(0xFFF0F1F3),
            ),
            const SizedBox(height: 4),

            // Option 2: Scan with AI (Meals & dishes)
            InkWell(
              onTap: () {
                Navigator.pop(modalCtx); // Close options modal
                Navigator.pop(context); // Close add food sheet
                FoodDiaryScreen.openAiScannerSheet(
                  context,
                  meal: _selectedMeal,
                  date: widget.date,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 22,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'diary.scanAi'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'diary.mealsDishes'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProviderAttribution(FoodSearchState searchState, bool isDark) {
    String? attributionText;
    final foods = searchState.foods;
    if (foods.any((f) => f.source == 'fatsecret')) {
      attributionText = 'diary.fatSecretAttribution'.tr();
    } else if (foods.any((f) => f.source == 'usda')) {
      attributionText = 'diary.usdaAttribution'.tr();
    }

    if (attributionText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Text(
        attributionText,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }

  Widget _buildSearchBody(
    BuildContext context,
    FoodSearchState searchState,
    bool isDark,
  ) {
    // 1. Loading State
    if (searchState.status == FoodSearchStatus.loading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.accent : const Color(0xFF2C5E3B),
            ),
          ),
        ),
      );
    }

    // 2. Error State
    if (searchState.status == FoodSearchStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'diary.somethingWentWrong'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                searchState.errorMessage ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(foodSearchProvider.notifier).retry(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('diary.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0F1410),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty Results State
    if (searchState.status == FoodSearchStatus.empty ||
        (searchState.foods.isEmpty && searchState.query.isNotEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/notfound.webp',
                height: 110,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'diary.noFoodsFound'.tr(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'diary.tryAnotherOrRequest'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  final sheetRef = widget.ref;
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FoodRequestSheet(ref: sheetRef),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    'diary.requestFood'.tr(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.accent
                          : const Color(0xFF2C5E3B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final results = searchState.foods;
    final isSearching = searchState.query.trim().isNotEmpty;
    final sectionLabel = isSearching
        ? 'diary.searchResults'.tr()
        : 'diary.recentFoods'.tr();

    // 4. Clean Editorial Results List
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              16,
              AppSpacing.xl,
              8,
            ),
            child: Text(
              sectionLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final food = results[index];
                final isLast = index == results.length - 1;
                return Column(
                  children: [
                    _buildFoodItemRow(context, food, isDark),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.6)
                            : const Color(0xFFECEEF0),
                      ),
                  ],
                );
              },
              childCount: results.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildFoodItemRow(BuildContext context, Food food, bool isDark) {
    final servingText = food.servingLabel.trim();
    final p = food.proteinG.round();
    final c = food.carbsG.round();
    final f = food.fatG.round();
    final macroLine = '$servingText · P ${p}g · C ${c}g · F ${f}g';

    return InkWell(
      onTap: () => _onSelectFood(food),
      borderRadius: BorderRadius.circular(8),
      splashColor: (isDark ? AppColors.accent : Colors.black)
          .withValues(alpha: 0.05),
      highlightColor: (isDark ? AppColors.accent : Colors.black)
          .withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Food Name & Macro line
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level 1: Food Name (16-17px, semibold)
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Level 3: Nutrition details (12-13px, muted, no bold, no pills, no dots)
                  Text(
                    macroLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right: Level 2: Calories & kcal
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${food.calories}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'kcal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodDetails(
    BuildContext context,
    bool isDark,
    Color accentColorParam,
  ) {
    final food = _selectedFood!;
    final accentColor = AppColors.accent;

    // Use selected serving's macros or fallback to food base macros
    final serving = _selectedServing;
    final baseCalories = (serving?.calories ?? food.calories);
    final baseProtein = (serving?.proteinG ?? food.proteinG);
    final baseCarbs = (serving?.carbsG ?? food.carbsG);
    final baseFat = (serving?.fatG ?? food.fatG);
    final servingLabel = serving?.servingDescription ?? food.servingLabel;

    final displayCalories = (baseCalories * _servings).round();
    final displayProtein = (baseProtein * _servings).round();
    final displayCarbs = (baseCarbs * _servings).round();
    final displayFat = (baseFat * _servings).round();

    final totalMacros = displayProtein + displayFat + displayCarbs;
    final proteinProgress = totalMacros > 0
        ? (displayProtein / totalMacros).clamp(0.15, 0.90)
        : 0.33;
    final fatProgress = totalMacros > 0
        ? (displayFat / totalMacros).clamp(0.15, 0.90)
        : 0.33;
    final carbsProgress = totalMacros > 0
        ? (displayCarbs / totalMacros).clamp(0.15, 0.90)
        : 0.33;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top Drag Handle ──
        Center(
          child: Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // ── Header: Back button + Food Name + Serving text ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                onPressed: () => setState(() {
                  _selectedFood = null;
                  _selectedServing = null;
                }),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      servingLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48), // Balance back button width to center the title
            ],
          ),
        ),

        if (_isLoadingDetails)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),

        // ── Scrollable Body Area ──
        Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3. MEAL SELECTION
                _buildMealSelectorChips(isDark, accentColor),
                const SizedBox(height: 14),

                // 4. CALORIE SUMMARY
                _buildCaloriesSummary(displayCalories, isDark),
                const SizedBox(height: 12),

                // 5. MACRO SECTION
                _buildMacroSection(
                  displayProtein: displayProtein,
                  displayFat: displayFat,
                  displayCarbs: displayCarbs,
                  proteinProgress: proteinProgress,
                  fatProgress: fatProgress,
                  carbsProgress: carbsProgress,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // 6. ABOUT THIS MEAL
                _buildAboutThisMealSection(
                  displayProtein,
                  displayFat,
                  displayCarbs,
                  displayCalories,
                  isDark,
                ),
                const SizedBox(height: 16),

                // Available Servings Selector (if food has multiple options)
                if (food.servings.length > 1) ...[
                  _buildServingUnitChips(food, isDark),
                  const SizedBox(height: 12),
                ],

                // 7. PORTION SECTION
                _buildServingsSelector(food, isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // 8. PRIMARY CTA: "Add to Diary"
        _buildPrimaryCtaButton(accentColor, isDark),
      ],
    );
  }

  Widget _buildCaloriesSummary(int displayCalories, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.6)
            : const Color(0xFFF7FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5ECE0),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Total $displayCalories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'kcal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : const Color(0xFF2C5E3B),
                ),
              ),
            ],
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 19,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutThisMealSection(
    int proteinG,
    int fatG,
    int carbsG,
    int calories,
    bool isDark,
  ) {
    final explanation = _generateMealExplanation(proteinG, fatG, carbsG, calories);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.45)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'diary.aboutThisMeal'.tr(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            explanation,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  String _generateMealExplanation(int proteinG, int fatG, int carbsG, int calories) {
    final proteinCals = proteinG * 4;
    final carbsCals = carbsG * 4;
    final fatCals = fatG * 9;
    final totalMacroCals = proteinCals + carbsCals + fatCals;

    if (totalMacroCals == 0) {
      return 'diary.aboutMealZero'.tr();
    }

    final carbRatio = carbsCals / totalMacroCals;
    final proteinRatio = proteinCals / totalMacroCals;
    final fatRatio = fatCals / totalMacroCals;

    if (carbRatio >= 0.50) {
      if (proteinRatio >= 0.15 && fatRatio >= 0.15) {
        return 'diary.aboutMealCarbDominant'.tr();
      }
      return 'diary.aboutMealCarbFocused'.tr();
    } else if (proteinRatio >= 0.30 || (proteinRatio > carbRatio && proteinRatio > fatRatio)) {
      return 'diary.aboutMealProteinFocused'.tr();
    } else if (fatRatio >= 0.45 || (fatRatio > carbRatio && fatRatio > proteinRatio)) {
      return 'diary.aboutMealFatFocused'.tr();
    } else {
      return 'diary.aboutMealBalanced'.tr();
    }
  }

  Widget _buildMacroSection({
    required int displayProtein,
    required int displayFat,
    required int displayCarbs,
    required double proteinProgress,
    required double fatProgress,
    required double carbsProgress,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            label: 'Protein',
            grams: displayProtein.toDouble(),
            progress: proteinProgress,
            color: const Color(0xFF8AC926),
            trackColor: isDark
                ? const Color(0xFF8AC926).withValues(alpha: 0.20)
                : const Color(0xFFE5F7CB),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMacroCard(
            label: 'Fat',
            grams: displayFat.toDouble(),
            progress: fatProgress,
            color: const Color(0xFF00B4D8),
            trackColor: isDark
                ? const Color(0xFF00B4D8).withValues(alpha: 0.20)
                : const Color(0xFFDDF3F8),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMacroCard(
            label: 'Carbs',
            grams: displayCarbs.toDouble(),
            progress: carbsProgress,
            color: const Color(0xFFFF5722),
            trackColor: isDark
                ? const Color(0xFFFF5722).withValues(alpha: 0.20)
                : const Color(0xFFFFE7E0),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required double grams,
    required double progress,
    required Color color,
    required Color trackColor,
    required bool isDark,
  }) {
    final displayGrams = grams.round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.6)
            : const Color(0xFFF7FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5ECE0),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 54,
            height: 54,
            child: CustomPaint(
              painter: _MacroRingPainter(
                progress: progress,
                trackColor: trackColor,
                progressColor: color,
                strokeWidth: 4.2,
              ),
              child: Center(
                child: Text(
                  '${displayGrams}g',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingUnitChips(Food food, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'diary.selectServing'.tr(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: food.servings.map((serving) {
              final isSelected = _selectedServing?.servingId == serving.servingId;
              final desc = serving.servingDescription;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedServing = serving;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentSoft
                          : (isDark
                              ? AppColors.darkSurface
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE5E7EB)),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF0F1410)
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF1F2937)),
                          ),
                        ),
                        if (serving.metricServingAmount != null &&
                            serving.metricServingUnit != null &&
                            !desc.toLowerCase().contains('${serving.metricServingAmount!.round()}g')) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${serving.metricServingAmount!.round()}${serving.metricServingUnit})',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF1E293B)
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : const Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSelectorChips(bool isDark, Color accentColor) {
    final meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    return Row(
      children: meals.map((m) {
        final isSelected = m.toLowerCase() == _selectedMeal.toLowerCase();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMeal = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark
                            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.6)
                            : const Color(0xFFF1F3F5)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : (isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E7EB)),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _mealLabel(m),
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0F1410)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF4B5563)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  double? _parseGramWeight(String label) {
    final lower = label.toLowerCase().trim();
    final regExp = RegExp(r'(\d+(?:\.\d+)?)\s*(g|gram|grams|kg)\b');
    final match = regExp.firstMatch(lower);
    if (match != null) {
      final val = double.tryParse(match.group(1)!);
      final unit = match.group(2)!;
      if (val != null) {
        if (unit == 'kg') {
          return val * 1000;
        }
        return val;
      }
    }
    return null;
  }

  String _formatGramValue(double val) {
    if (val % 1 == 0) {
      return val.round().toString();
    }
    return val.toStringAsFixed(1);
  }

  Widget _buildServingsSelector(Food food, bool isDark) {
    final presets = [
      {'label': '¼', 'val': 0.25},
      {'label': '½', 'val': 0.5},
      {'label': '1', 'val': 1.0},
      {'label': '1½', 'val': 1.5},
      {'label': '2', 'val': 2.0},
    ];

    final serving = _selectedServing;
    double? gramWeight;
    if (serving != null &&
        serving.metricServingAmount != null &&
        serving.metricServingUnit?.toLowerCase() == 'g') {
      gramWeight = serving.metricServingAmount;
    } else {
      gramWeight = _parseGramWeight(serving?.servingDescription ?? food.servingLabel);
    }
    final gramTotal = gramWeight != null ? (gramWeight * _servings) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset portion chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...presets.map((p) {
                final val = p['val'] as double;
                final label = p['label'] as String;
                final isSelected = !_isCustomServing && _servings == val;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomServing = false;
                        _servings = val;
                        _customServingController.text = val % 1 == 0
                            ? val.toInt().toString()
                            : val.toString();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                  ? AppColors.darkSurfaceAlt.withValues(alpha: 0.6)
                                  : const Color(0xFFF1F3F5)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : (isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE5E7EB)),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0F1410)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF4B5563)),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Custom chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCustomServing = true;
                      _customServingController.text = _servings % 1 == 0
                          ? _servings.toInt().toString()
                          : _servings.toString();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _isCustomServing
                          ? AppColors.accent
                          : (isDark
                                ? AppColors.darkSurfaceAlt.withValues(alpha: 0.6)
                                : const Color(0xFFF1F3F5)),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                        color: _isCustomServing
                            ? AppColors.accent
                            : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE5E7EB)),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Custom',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: _isCustomServing
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isCustomServing
                            ? const Color(0xFF0F1410)
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF4B5563)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Custom numeric TextField (revealed when Custom chip is tapped)
        if (_isCustomServing) ...[
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 130,
              child: TextField(
                controller: _customServingController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
                decoration: InputDecoration(
                  hintText: '1.0',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : const Color(0xFF9CA3AF),
                  ),
                  suffixText: 'x',
                  suffixStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF6B7280),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _servings = parsed;
                    });
                  }
                },
              ),
            ),
          ),
        ],

        // Informational gram equivalent text line
        if (gramTotal != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '= ${_formatGramValue(gramTotal)} g',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryCtaButton(Color accentColor, bool isDark) {
    final buttonText = 'diary.addToDiary'.tr();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isCtaPressed = true),
        onTapUp: (_) => setState(() => _isCtaPressed = false),
        onTapCancel: () => setState(() => _isCtaPressed = false),
        onTap: _addFood,
        child: AnimatedScale(
          scale: _isCtaPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              buttonText,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0F1410),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring painter for macro cards matching the reference design.
class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _MacroRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 4.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.05, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}

