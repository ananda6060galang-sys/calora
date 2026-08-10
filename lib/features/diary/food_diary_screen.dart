import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/widgets/food_card.dart';
import '../../core/widgets/progress_ring.dart';

import '../../models/food.dart';
import '../../models/mock_data.dart';

import '../dashboard/providers/profile_provider.dart';
import 'providers/diary_provider.dart';
import 'food_request_sheet.dart';

class FoodDiaryScreen extends ConsumerWidget {
  final bool showBackButton;
  
  const FoodDiaryScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB), // Clean off-white background
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
  static const _meals = ['Breakfast', 'Lunch', 'Snack', 'Dinner']; // Matching reference
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
                  (isDark ? AppColors.darkBg : const Color(0xFFF8F9FB)).withValues(alpha: 0.0), // Fade to bg
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Header (App Bar style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    if (widget.showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: isDark ? Colors.white : Colors.black,
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      )
                    else
                      const SizedBox(height: 48), // maintain header height
                    const Spacer(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Set your daily meal plan" + Image
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                'Set your daily\nmeal plan',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.black,
                                      height: 1.2,
                                    ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Image.asset(
                                'assets/head.webp',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Calendar Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // 1. Active Month & Year Header (Tap to open full Calendar)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                                      primary: AppColors.accent,
                                                      onPrimary: const Color(0xFF0E0F10),
                                                    ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(() => _selectedDate = picked);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            DateFormat('MMMM yyyy').format(_selectedDate),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: isDark ? Colors.white60 : Colors.black54,
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
                                      final date = DateTime(_selectedDate.year, monthIndex, 1);
                                      final isSelected = date.month == _selectedDate.month && date.year == _selectedDate.year;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: index == 0 ? 24 : 10,
                                          right: index == 11 ? 24 : 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
                                              final day = _selectedDate.day.clamp(1, daysInMonth);
                                              _selectedDate = DateTime(date.year, date.month, day);
                                            });
                                          },
                                          child: _monthText(context, DateFormat('MMM').format(date), isSelected),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Day selector
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 7,
                                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final date = _selectedDate.subtract(Duration(days: 3 - index));
                                      final isSelected = DateUtils.isSameDay(date, _selectedDate);
                                      
                                      // Get progress for this specific day to draw the bottom progress fill
                                      final dayTotals = ref.watch(diaryTotalsForDateProvider(date));
                                      final dayTarget = profile.dailyCalorieTarget.round();
                                      final dayProgress = dayTarget > 0 ? (dayTotals.calories / dayTarget) : 0.0;

                                      return _DayCard(
                                        date: date,
                                        isSelected: isSelected,
                                        progress: dayProgress,
                                        onTap: () => setState(() => _selectedDate = date),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
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
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.0,
                                        height: 1.0,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'of $targetCals',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF999999),
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
                                  label: 'Protein',
                                  consumed: totals.proteinG,
                                  target: profile.proteinTargetG,
                                ),
                                const SizedBox(height: 12),
                                _MacroRow(
                                  label: 'Carbs',
                                  consumed: totals.carbsG,
                                  target: profile.carbsTargetG,
                                ),
                                const SizedBox(height: 12),
                                _MacroRow(
                                  label: 'Fat',
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
                    final mealEntries = entries.where((e) => e.meal == meal).toList();
                    return _MealCard(
                      meal: meal,
                      items: mealEntries,
                      isReversed: index % 2 != 0, // Alternate layout
                      onAddTap: () => _openAddFoodSheet(context, ref, meal, _selectedDate),
                      onDeleteTap: (id) => ref.read(diaryProvider.notifier).remove(id),
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

  void _openAddFoodSheet(BuildContext context, WidgetRef ref, String meal, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(meal: meal, ref: ref, date: date),
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
          )
        ] else ...[
          const SizedBox(height: 6),
        ]
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
            color: isSelected ? AppColors.lavender : Colors.transparent, // Lavender for selected
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isSelected
                  ? AppColors.lavender
                  : AppColors.success.withValues(alpha: 0.8), // Success green outline for unselected
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.lavender.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
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
                    color: AppColors.success.withValues(alpha: 0.15), // Soft green vertical fill
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
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected 
                            ? Colors.white 
                            : (isDark ? AppColors.darkTextSecondary : Colors.black54),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected 
                            ? Colors.white 
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
      margin: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          // Top half (like reference card)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: isReversed
                  ? [_buildImage(context, isDark, cals), const SizedBox(width: 32), _buildContent(context, cals)]
                  : [_buildContent(context, cals), const SizedBox(width: 32), _buildImage(context, isDark, cals)],
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
                        'Logged Foods',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFFAAAAAA),
                              letterSpacing: 0.5,
                            ),
                      ),
                      Text(
                        '${items.length} item${items.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFFAAAAAA),
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
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                        ),
                        child: FoodCard(
                          name: item.food.name,
                          serving: '${item.servings == item.servings.toInt() ? item.servings.toInt() : item.servings} x ${item.food.servingLabel}',
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
    String rec = 'Recommended 830-1170Cal';
    if (meal == 'Lunch') rec = 'Recommended 255-370Cal';
    if (meal == 'Dinner') rec = 'Recommended 255-370Cal';

    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment:
            isReversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment:
                  isReversed ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (cals > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• $cals Cal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.lavender,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // + Add Button (Premium Lavender pill)
            Material(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onAddTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    '+ Add',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
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
    return Expanded(
      flex: 2,
      child: Align(
        alignment: isReversed ? Alignment.centerLeft : Alignment.centerRight,
        child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Trendy Gen Z subtle glow / background shape
              Container(
                width: 110,
                height: 110,
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
              // The actual frameless image floating on top
              Image.asset(
                'assets/breakfast.png', // Using the header asset in folder as requested
                width: 130,
                height: 130,
                fit: BoxFit.contain, // Allow the image's natural shape, no clipping
                errorBuilder: (context, error, stackTrace) {
                  // Fallback without a harsh circle frame
                  return Icon(
                    Icons.image_outlined,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                    size: 56,
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
    if (label == 'Protein') {
      dotColor = const Color(0xFFFF8B7B); // Soft coral
    } else if (label == 'Carbs') {
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
          width: 48,
          child: Text(
            label,
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
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  letterSpacing: -0.3,
                ),
            children: [
              TextSpan(text: '${consumed.round()}'),
              TextSpan(
                text: '/${target.round()}g',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Add Food Bottom Sheet (Matching right reference screen) ──────────

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.meal, required this.ref, required this.date});

  final String meal;
  final WidgetRef ref;
  final DateTime date;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  String _query = '';
  Food? _selectedFood;
  double _servings = 1.0;

  void _addFood() {
    if (_selectedFood == null) return;
    widget.ref.read(diaryProvider.notifier).add(
          _selectedFood!,
          _servings,
          widget.meal,
          widget.date,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _query.isEmpty
        ? demoFoods
        : demoFoods
            .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Almost full screen
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFF7F8FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // App Bar style header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    '${widget.meal} items',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 48), // Balance
              ],
            ),
          ),

          // Search / Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _query = v;
                  _selectedFood = null;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Content
          Expanded(
            child: _selectedFood != null
                ? _buildFoodDetails(context, isDark)
                : _buildSearchResults(context, results, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<Food> results, bool isDark) {
    if (results.isEmpty && _query.isNotEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).disabledColor),
              const SizedBox(height: AppSpacing.lg),
              Text("Can't find your food?", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FoodRequestSheet(ref: widget.ref),
                  );
                },
                child: Text('Request Food', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final food = results[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFood = food;
              _servings = 1.0;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                  ),
                  child: const Icon(Icons.restaurant_rounded),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${food.calories} Cal', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodDetails(BuildContext context, bool isDark) {
    final food = _selectedFood!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                // Food Image Placeholder
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Icon(Icons.restaurant_rounded, size: 64, color: AppColors.accent),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title & Desc
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A delicious choice for ${widget.meal.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepperBtn(
                      icon: Icons.remove_rounded,
                      onTap: _servings > 0.5 ? () => setState(() => _servings -= 0.5) : null,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Icon(Icons.local_dining_rounded, color: AppColors.accent, size: 32),
                    const SizedBox(width: AppSpacing.xl),
                    _stepperBtn(
                      icon: Icons.add_rounded,
                      onTap: () => setState(() => _servings += 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_servings == _servings.toInt() ? _servings.toInt() : _servings} Servings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 3 Colorful Macro Squares (like the time/level/cal in reference)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _coloredSquare(
                      color: AppColors.accent,
                      icon: Icons.local_fire_department_rounded,
                      label: '${(food.calories * _servings).round()} Cal',
                    ),
                    _coloredSquare(
                      color: AppColors.protein,
                      icon: Icons.fitness_center_rounded,
                      label: '${(food.proteinG * _servings).round()}g Pro',
                    ),
                    _coloredSquare(
                      color: AppColors.carbs,
                      icon: Icons.grain_rounded,
                      label: '${(food.carbsG * _servings).round()}g Carb',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Per serving breakdown
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Per serving',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _macroBar(label: 'CARBS', value: food.carbsG, color: AppColors.carbs),
                    _macroBar(label: 'PROTEIN', value: food.proteinG, color: AppColors.protein),
                    _macroBar(label: 'FAT', value: food.fatG, color: AppColors.fat),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),

        // Bottom Add Button
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(context).padding.bottom + AppSpacing.lg),
          child: Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _addFood,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                child: Text(
                  '+ Add Meals', // Exact text from reference
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0E0F10),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepperBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? AppColors.accent : Theme.of(context).disabledColor, width: 2),
        ),
        child: Icon(icon, color: enabled ? AppColors.accent : Theme.of(context).disabledColor),
      ),
    );
  }

  Widget _coloredSquare({required Color color, required IconData icon, required String label}) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _macroBar({required String label, required double value, required Color color}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text('${value.round()}g', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
