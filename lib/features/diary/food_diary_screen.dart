import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/meal_tag.dart';
import '../../core/widgets/nutrient_stat_card.dart';
import '../../models/food.dart';
import '../../models/mock_data.dart';
import 'providers/diary_provider.dart';

class FoodDiaryScreen extends ConsumerWidget {
  const FoodDiaryScreen({super.key});

  static const _meals = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(diaryProvider);
    final totals = ref.watch(diaryTotalsProvider);
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFoodSheet(context, ref, 'Snacks'),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF0E0F10),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add food'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Food Diary', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 2),
                    Text(today, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),

            // Horizontally scrollable stat row — the mobile reinterpretation
            // of the desktop's four-across totals bar.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SizedBox(
                  height: 132,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      NutrientStatCard(
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.accent,
                        label: 'Calories',
                        value: '${totals.calories}',
                        unit: 'kcal',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      NutrientStatCard(
                        icon: Icons.grain_rounded,
                        color: AppColors.carbs,
                        label: 'Carbs',
                        value: totals.carbsG.round().toString(),
                        unit: 'g',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      NutrientStatCard(
                        icon: Icons.set_meal_rounded,
                        color: AppColors.protein,
                        label: 'Protein',
                        value: totals.proteinG.round().toString(),
                        unit: 'g',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      NutrientStatCard(
                        icon: Icons.water_drop_rounded,
                        color: AppColors.fat,
                        label: 'Fats',
                        value: totals.fatG.round().toString(),
                        unit: 'g',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search today\'s log',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterButton(),
                  ],
                ),
              ),
            ),

            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.restaurant_outlined,
                    title: 'No food logged yet',
                    message: 'Tap "Add food" to log your first meal today.',
                    actionLabel: 'Add food',
                    onAction: () => _openAddFoodSheet(context, ref, 'Breakfast'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    for (final meal in _meals)
                      _mealSection(
                        context,
                        ref,
                        meal,
                        entries.where((e) => e.meal == meal).toList(),
                      ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mealSection(
      BuildContext context, WidgetRef ref, String meal, List<DiaryEntry> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final mealCalories = items.fold<int>(0, (s, e) => s + e.calories);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    MealTag(meal: meal),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text('$mealCalories kcal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                onPressed: () => _openAddFoodSheet(context, ref, meal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger),
                  ),
                  onDismissed: (_) => ref.read(diaryProvider.notifier).remove(e.id),
                  child: FoodCard(
                    name: e.food.name,
                    serving:
                        '${e.servings.toStringAsFixed(e.servings % 1 == 0 ? 0 : 1)} × ${e.food.servingLabel}',
                    calories: e.calories,
                    protein: e.proteinG,
                    carbs: e.carbsG,
                    fat: e.fatG,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _openAddFoodSheet(BuildContext context, WidgetRef ref, String meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(meal: meal, ref: ref),
    );
  }
}

class _FilterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {},
        child: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: AppShadows.card(isDark),
          ),
          child: Icon(Icons.tune_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ),
    );
  }
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.meal, required this.ref});

  final String meal;
  final WidgetRef ref;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = demoFoods
        .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  MealTag(meal: widget.meal),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text('Add food',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search foods...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: results.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No foods found',
                        message: 'Try a different search term.',
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final food = results[i];
                          return FoodCard(
                            name: food.name,
                            serving: food.servingLabel,
                            calories: food.calories,
                            protein: food.proteinG,
                            carbs: food.carbsG,
                            fat: food.fatG,
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_rounded,
                                  color: AppColors.accent),
                              onPressed: () {
                                widget.ref
                                    .read(diaryProvider.notifier)
                                    .add(food, 1, widget.meal);
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
