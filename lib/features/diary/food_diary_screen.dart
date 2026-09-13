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
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodSheet(
        meal: meal,
        ref: ref,
        date: date ?? DateTime.now(),
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
                      ? const Color(0xFF2C4A26) // Dark sage
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
                        color: isDark ? Colors.white : Colors.black,
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
                                      ? Colors.white
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
                                'assets/head.png',
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.crop_free_rounded,
                                      color: isDark ? Colors.black : Colors.white,
                                      size: 26,
                                    ),
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: isDark ? Colors.black : Colors.white,
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
                                                        0xFF0E0F10,
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
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: isDark
                                                ? Colors.white60
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
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 32,
            color: isDark ? Colors.white : Colors.black,
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
                            ? const Color(0xFF0E0F10)
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
                            ? const Color(0xFF0E0F10)
                            : (isDark ? Colors.white : Colors.black),
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
  'breakfast': 'assets/breakfast.png',
  'lunch': 'assets/Lunch.png',
  'dinner': 'assets/Dinner.png',
  'snack': 'assets/Snack.png', // Bebas diganti ke asset gambar lain
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
                    color: const Color(0xFF0E0F10),
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
    final assetPath = _mealAssetPaths[lowerMeal] ?? 'assets/breakfast.png';
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
  });

  final String? meal;
  final WidgetRef ref;
  final DateTime date;

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
              maxHeight: MediaQuery.of(context).size.height * 0.94,
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
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : const Color(0xFFF7F8FA),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // App Bar style header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'diary.mealItems'.tr(args: [_mealLabel(_selectedMeal)]),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Search Input with active debounce
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'diary.searchFoods'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(foodSearchProvider.notifier)
                                  .onQueryChanged('');
                            },
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          tooltip: 'diary.aiScannerTitle'.tr(),
                          onPressed: () {
                            Navigator.pop(context);
                            FoodDiaryScreen.openAiScannerSheet(
                              context,
                              meal: _selectedMeal,
                              date: widget.date,
                            );
                          },
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    ref.read(foodSearchProvider.notifier).onQueryChanged(v);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

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

              // Content Area
              Expanded(child: _buildSearchBody(context, searchState, isDark)),

              // Dynamic Provider Attribution footer
              _buildProviderAttribution(searchState, isDark),
            ],
          ),
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

  Widget _buildSourceBadge(String source, bool isDark) {
    String label;
    Color badgeColor;
    Color textColor;
    switch (source.toLowerCase()) {
      case 'fatsecret':
        label = 'diary.sourceFatSecret'.tr();
        badgeColor = const Color(0xFF00B074).withValues(alpha: 0.12);
        textColor = const Color(0xFF00B074);
        break;
      case 'usda':
        label = 'diary.sourceUsda'.tr();
        badgeColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'ai_scan':
        label = 'diary.sourceAi'.tr();
        badgeColor = AppColors.lavender.withValues(alpha: 0.15);
        textColor = AppColors.lavender;
        break;
      default:
        label = 'diary.sourceLocal'.tr();
        badgeColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
        textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'diary.loadingFoods'.tr(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
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
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'diary.somethingWentWrong'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                searchState.errorMessage ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  foregroundColor: const Color(0xFF0E0F10),
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
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'diary.noFoodsFound'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'diary.tryAnotherSearch'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                "diary.cantFindFood".tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
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
                child: Text(
                  'diary.requestFood'.tr(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final results = searchState.foods;

    // 4. Results List
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final food = results[index];
        return GestureDetector(
          onTap: () => _onSelectFood(food),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSourceBadge(food.source, isDark),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            '${food.servingLabel} •',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                          ),
                          Text(
                            'P: ${food.proteinG.round()}g  C: ${food.carbsG.round()}g  F: ${food.fatG.round()}g',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${food.calories}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.accent
                            : const Color(0xFF2C4A26),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

    return Column(
      children: [
        // App bar style header with back button and drag handle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => setState(() {
                      _selectedFood = null;
                      _selectedServing = null;
                    }),
                  ),
                  Expanded(
                    child: Text(
                      'diary.foodDetails'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance width with back button
                ],
              ),
            ],
          ),
        ),

        if (_isLoadingDetails)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Selector Chips
                      _buildMealSelectorChips(isDark, accentColor),
                      const SizedBox(height: 24),

                      // Food Title & Subtitle Metadata
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111111),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildSourceBadge(food.source, isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        servingLabel,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Available Servings Selector (if food has multiple servings options)
                      if (food.servings.length > 1) ...[
                        _buildServingUnitChips(food, isDark),
                        const SizedBox(height: 20),
                      ],

                      // Relative Portion Multiplier Chips & Gram Equivalent
                      _buildServingsSelector(food, isDark),
                      const SizedBox(height: 28),

                      // Macro Cards Hierarchy: Full-width Calorie Card at top
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF9500,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFFF9500),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'diary.caloriesUpper'.tr(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$displayCalories',
                                        style: GoogleFonts.inter(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF111111),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'kcal',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row of 3 smaller Macro Cards (Protein, Carbs, Fat)
                      Row(
                        children: [
                          _macroCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.egg_outlined,
                            iconColor: AppColors.protein,
                            value: '${displayProtein}g',
                            label: 'diary.proteinUpper'.tr(),
                          ),
                          const SizedBox(width: 10),
                          _macroCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.grain,
                            iconColor: AppColors.carbs,
                            value: '${displayCarbs}g',
                            label: 'diary.carbsUpper'.tr(),
                          ),
                          const SizedBox(width: 10),
                          _macroCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.water_drop_outlined,
                            iconColor: AppColors.fat,
                            value: '${displayFat}g',
                            label: 'diary.fatUpper'.tr(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Stacked Macro Proportion Breakdown Bar
                      _buildMacroProportionBar(
                        displayProtein.toDouble(),
                        displayCarbs.toDouble(),
                        displayFat.toDouble(),
                        isDark,
                      ),

                      // Extra bottom spacing to prevent CTA overlap
                      SizedBox(
                        height: 32 + MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                ),
              ),

              // Primary CTA "Add Meals" Button
              _buildPrimaryCtaButton(accentColor, isDark),
            ],
          ),
        ),
      ],
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
                                ? const Color(0xFF0E0F10)
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
                      ? AppColors.accentSoft
                      : (isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF3F4F6)),
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
                          ? const Color(0xFF0E0F10)
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
                  padding: const EdgeInsets.symmetric(horizontal: 3),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                  ? AppColors.darkSurface
                                  : const Color(0xFFF3F4F6)),
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
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0E0F10)
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
                padding: const EdgeInsets.symmetric(horizontal: 3),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isCustomServing
                          ? AppColors.accent
                          : (isDark
                                ? AppColors.darkSurface
                                : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isCustomServing
                            ? AppColors.accent
                            : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE5E7EB)),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Custom',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _isCustomServing
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isCustomServing
                            ? const Color(0xFF0E0F10)
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 12),
          Text(
            '≈ ${_formatGramValue(gramTotal)} g',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  Widget _macroCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroProportionBar(
    double proG,
    double carbsG,
    double fatG,
    bool isDark,
  ) {
    final proCal = proG * 4;
    final carbsCal = carbsG * 4;
    final fatCal = fatG * 9;
    final totalCal = proCal + carbsCal + fatCal;

    final proPct = totalCal > 0 ? (proCal / totalCal) : 0.33;
    final carbsPct = totalCal > 0 ? (carbsCal / totalCal) : 0.33;
    final fatPct = totalCal > 0 ? (fatCal / totalCal) : 0.34;

    const proColor = Color(0xFFFF6B57);
    const carbsColor = Color(0xFFFFC24B);
    const fatColor = Color(0xFF7C9CFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'diary.macroProportion'.tr(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280),
              ),
            ),
            Text(
              '${totalCal.round()} kcal',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (carbsPct > 0)
                  Expanded(
                    flex: (carbsPct * 100).round().clamp(1, 100),
                    child: Container(color: carbsColor),
                  ),
                if (proPct > 0)
                  Expanded(
                    flex: (proPct * 100).round().clamp(1, 100),
                    child: Container(color: proColor),
                  ),
                if (fatPct > 0)
                  Expanded(
                    flex: (fatPct * 100).round().clamp(1, 100),
                    child: Container(color: fatColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _macroLegendItem(
              'dashboard.carbs'.tr(),
              '${carbsG.round()}g',
              '${(carbsPct * 100).round()}%',
              carbsColor,
              isDark,
            ),
            _macroLegendItem(
              'dashboard.protein'.tr(),
              '${proG.round()}g',
              '${(proPct * 100).round()}%',
              proColor,
              isDark,
            ),
            _macroLegendItem(
              'dashboard.fat'.tr(),
              '${fatG.round()}g',
              '${(fatPct * 100).round()}%',
              fatColor,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _macroLegendItem(
    String label,
    String grams,
    String pct,
    Color color,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label ($pct)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCtaButton(Color accentColor, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isCtaPressed = true),
        onTapUp: (_) => setState(() => _isCtaPressed = false),
        onTapCancel: () => setState(() => _isCtaPressed = false),
        onTap: _addFood,
        child: AnimatedScale(
          scale: _isCtaPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'diary.addMeals'.tr(),
              style: GoogleFonts.inter(
                color: const Color(0xFF0E0F10),
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
