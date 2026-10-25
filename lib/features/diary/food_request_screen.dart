import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/category_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/input_validators.dart';
import '../../models/food_category.dart';
import '../../models/food_request.dart';
import 'my_food_submissions_screen.dart';
import 'providers/food_request_provider.dart';

/// CALORA - FOOD REQUEST SCREEN
///
/// Ultra-clean, user-friendly food submission flow with real-time live preview.
/// Designed for everyday users: zero visual bloat, no intimidating headers,
/// fast and delightful data entry.
class FoodRequestScreen extends ConsumerStatefulWidget {
  const FoodRequestScreen({
    super.key,
    this.editRequest,
    this.initialBarcode,
  });

  final FoodRequest? editRequest;
  final String? initialBarcode;

  @override
  ConsumerState<FoodRequestScreen> createState() => _FoodRequestScreenState();
}

class _FoodRequestScreenState extends ConsumerState<FoodRequestScreen> {
  final _nameCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedCategoryId;
  String? _nameError;
  String? _servingError;
  String? _caloriesError;
  String? _proteinError;
  String? _carbsError;
  String? _fatError;
  bool _showNotes = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editRequest;
    if (edit != null) {
      _nameCtrl.text = edit.foodName;
      _servingCtrl.text = edit.servingLabel;
      _caloriesCtrl.text = edit.calories.toString();
      _proteinCtrl.text = edit.proteinG.toStringAsFixed(
        edit.proteinG.truncateToDouble() == edit.proteinG ? 0 : 1,
      );
      _carbsCtrl.text = edit.carbsG.toStringAsFixed(
        edit.carbsG.truncateToDouble() == edit.carbsG ? 0 : 1,
      );
      _fatCtrl.text = edit.fatG.toStringAsFixed(
        edit.fatG.truncateToDouble() == edit.fatG ? 0 : 1,
      );
      if (edit.notes != null && edit.notes!.trim().isNotEmpty) {
        _notesCtrl.text = edit.notes!;
        _showNotes = true;
      }
      _selectedCategoryId = edit.categoryId;
    } else if (defaultFoodCategories.isNotEmpty) {
      _selectedCategoryId = defaultFoodCategories.first.id;
    }
    _nameCtrl.addListener(_onFieldChanged);
    _servingCtrl.addListener(_onFieldChanged);
    _caloriesCtrl.addListener(_onFieldChanged);
    _proteinCtrl.addListener(_onFieldChanged);
    _carbsCtrl.addListener(_onFieldChanged);
    _fatCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _parsedCalories =>
      int.tryParse(_caloriesCtrl.text.trim().replaceAll(',', '.')) ?? 0;
  double get _parsedProtein =>
      double.tryParse(_proteinCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
  double get _parsedCarbs =>
      double.tryParse(_carbsCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
  double get _parsedFat =>
      double.tryParse(_fatCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final serving = _servingCtrl.text.trim();
    final cals = _parsedCalories;
    final pro = _parsedProtein;
    final carbs = _parsedCarbs;
    final fat = _parsedFat;

    setState(() {
      _nameError = name.isEmpty ? 'diary.foodRequest.fillRequired'.tr() : null;
      _servingError = serving.isEmpty ? 'diary.foodRequest.fillRequired'.tr() : null;
      _caloriesError = cals <= 0
          ? 'validation.invalidNumber'.tr()
          : (cals > InputValidators.maxCalories
              ? 'validation.caloriesMax'.tr(args: ['${InputValidators.maxCalories}'])
              : null);
      _proteinError = pro > InputValidators.maxMacroGrams
          ? 'validation.macroMax'.tr(args: ['${InputValidators.maxMacroGrams.round()}'])
          : null;
      _carbsError = carbs > InputValidators.maxMacroGrams
          ? 'validation.macroMax'.tr(args: ['${InputValidators.maxMacroGrams.round()}'])
          : null;
      _fatError = fat > InputValidators.maxMacroGrams
          ? 'validation.macroMax'.tr(args: ['${InputValidators.maxMacroGrams.round()}'])
          : null;
    });

    if (_nameError != null ||
        _servingError != null ||
        _caloriesError != null ||
        _proteinError != null ||
        _carbsError != null ||
        _fatError != null) {
      HapticFeedback.vibrate();
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('diary.foodRequest.fillRequired'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final edit = widget.editRequest;
      if (edit != null) {
        await ref.read(foodRequestProvider.notifier).update(
              id: edit.id,
              foodName: name,
              categoryId: _selectedCategoryId!,
              servingLabel: serving,
              calories: cals,
              proteinG: pro,
              carbsG: carbs,
              fatG: fat,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      edit.status.toLowerCase() == 'rejected'
                          ? 'diary.foodRequest.resubmittedSuccess'.tr()
                          : 'profile.submissionUpdated'.tr(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1B3D22),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        await ref.read(foodRequestProvider.notifier).add(
              foodName: name,
              categoryId: _selectedCategoryId!,
              servingLabel: serving,
              calories: cals,
              proteinG: pro,
              carbsG: carbs,
              fatG: fat,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              barcode: widget.initialBarcode,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'diary.foodRequest.submittedSuccess'.tr(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1B3D22),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('diary.foodRequest.submitFailed'.tr(args: ['$e'])),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  IconData _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'protein':
        return Icons.fitness_center_rounded;
      case 'carbs':
        return Icons.grain_rounded;
      case 'fats':
        return Icons.eco_rounded;
      case 'dairy':
        return Icons.local_drink_rounded;
      case 'fruit':
        return Icons.apple_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final categoriesAsync = ref.watch(foodCategoriesProvider);
    final categories = categoriesAsync.asData?.value ?? defaultFoodCategories;
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final selectedCategory = categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => categories.isNotEmpty ? categories.first : defaultFoodCategories.first,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: dividerColor, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: textPrimary,
              ),
            ),
          ),
        ),
        title: Text(
          widget.editRequest != null
              ? 'diary.foodRequest.editTitle'.tr()
              : 'diary.foodRequest.title'.tr(),
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (widget.editRequest == null) ...[
            // Submissions history icon button
            IconButton(
              tooltip: 'profile.myFoodRequests'.tr(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyFoodSubmissionsScreen(),
                  ),
                );
              },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: dividerColor, width: 0.8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  if (widget.initialBarcode != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceAlt
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.qr_code_rounded,
                              color: Color(0xFF4D7800),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Barcode Kemasan Terdeteksi',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.initialBarcode!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── 1. LIVE NUTRITION CARD PREVIEW (THE HERO) ─────────────
                  _LiveNutritionHero(
                    name: _nameCtrl.text.trim(),
                    serving: _servingCtrl.text.trim(),
                    categoryName: selectedCategory.name,
                    categoryIcon: _categoryIcon(selectedCategory.name),
                    calories: _parsedCalories,
                    protein: _parsedProtein,
                    carbs: _parsedCarbs,
                    fat: _parsedFat,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 20),

                  // ── 2. FOOD BASIC DETAILS ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dividerColor, width: 0.8),
                      boxShadow: AppShadows.card(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Name
                        _SimpleInputField(
                          controller: _nameCtrl,
                          label: 'diary.foodRequest.foodNameLabel'.tr(),
                          hint: 'diary.foodRequest.foodNameHint'.tr(),
                          icon: Icons.restaurant_rounded,
                          errorText: _nameError,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          dividerColor: dividerColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onChanged: (_) {
                            if (_nameError != null) setState(() => _nameError = null);
                          },
                        ),

                        const SizedBox(height: 14),

                        // Portion / Serving
                        _SimpleInputField(
                          controller: _servingCtrl,
                          label: 'diary.foodRequest.portionLabel'.tr(),
                          hint: 'diary.foodRequest.portionHint'.tr(),
                          icon: Icons.scale_rounded,
                          errorText: _servingError,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          dividerColor: dividerColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onChanged: (_) {
                            if (_servingError != null) setState(() => _servingError = null);
                          },
                        ),

                        const SizedBox(height: 14),

                        // Category Chips
                        Text(
                          'diary.foodRequest.categoryLabel'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) {
                            final isSelected = cat.id == _selectedCategoryId;
                            final icon = _categoryIcon(cat.name);

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategoryId = cat.id);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.accent.withValues(alpha: 0.15)
                                          : const Color(0xFFEFF8EA))
                                      : surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.accent
                                            : const Color(0xFF2E6319))
                                        : dividerColor,
                                    width: 1.0, // Fixed width prevents layout shift
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 14,
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.accent
                                              : const Color(0xFF2E6319))
                                          : textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700, // Fixed weight prevents text jump
                                        color: isSelected
                                            ? (isDark
                                                ? AppColors.accent
                                                : const Color(0xFF2E6319))
                                            : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 3. NUTRITION & MACROS ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dividerColor, width: 0.8),
                      boxShadow: AppShadows.card(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calories
                        _SimpleInputField(
                          controller: _caloriesCtrl,
                          label: 'Calories',
                          hint: 'e.g. 350',
                          icon: Icons.local_fire_department_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [InputValidators.integerFormatter],
                          errorText: _caloriesError,
                          suffixText: 'kcal',
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          dividerColor: dividerColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onChanged: (_) {
                            if (_caloriesError != null) {
                              setState(() => _caloriesError = null);
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        // Macros row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _CompactMacroField(
                                controller: _proteinCtrl,
                                label: 'Protein',
                                color: AppColors.protein,
                                isDark: isDark,
                                surfaceAlt: surfaceAlt,
                                dividerColor: dividerColor,
                                textPrimary: textPrimary,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CompactMacroField(
                                controller: _carbsCtrl,
                                label: 'Carbs',
                                color: AppColors.carbs,
                                isDark: isDark,
                                surfaceAlt: surfaceAlt,
                                dividerColor: dividerColor,
                                textPrimary: textPrimary,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CompactMacroField(
                                controller: _fatCtrl,
                                label: 'Fat',
                                color: AppColors.fat,
                                isDark: isDark,
                                surfaceAlt: surfaceAlt,
                                dividerColor: dividerColor,
                                textPrimary: textPrimary,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── 4. DISCREET OPTIONAL NOTE TOGGLE ─────────────────────
                  if (!_showNotes)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showNotes = true),
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          size: 15,
                          color: textSecondary,
                        ),
                        label: Text(
                          'diary.foodRequest.notesHint'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dividerColor, width: 0.8),
                      ),
                      child: _SimpleInputField(
                        controller: _notesCtrl,
                        label: 'diary.foodRequest.notesHint'.tr(),
                        hint: 'e.g. Brand name, restaurant, or barcode',
                        icon: Icons.notes_rounded,
                        maxLines: 2,
                        isDark: isDark,
                        surfaceAlt: surfaceAlt,
                        dividerColor: dividerColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── DOCKED SUBMIT BUTTON ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: dividerColor, width: 0.8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.accent
                        : const Color(0xFF1B3D22),
                    foregroundColor:
                        isDark ? const Color(0xFF0F1410) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isDark
                                ? const Color(0xFF0F1410)
                                : Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.editRequest != null
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.send_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.editRequest != null
                                  ? 'diary.foodRequest.saveChanges'.tr()
                                  : 'diary.foodRequest.submitButton'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CLEAN LIVE NUTRITION CARD HERO
// ═════════════════════════════════════════════════════════════════════════════

class _LiveNutritionHero extends StatelessWidget {
  const _LiveNutritionHero({
    required this.name,
    required this.serving,
    required this.categoryName,
    required this.categoryIcon,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isDark,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String name;
  final String serving;
  final String categoryName;
  final IconData categoryIcon;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isDark;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : 'Food name...';
    final displayServing = serving.isNotEmpty ? serving : '1 serving';
    final totalMacros = protein + carbs + fat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8DF),
          width: 0.8,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon,
                            size: 12,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            categoryName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E6319),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: name.isNotEmpty
                            ? textPrimary
                            : textSecondary.withValues(alpha: 0.6),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayServing,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Calorie readout
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$calories',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Slim Macro Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 5,
              width: double.infinity,
              color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFECEEEB),
              child: totalMacros > 0
                  ? Row(
                      children: [
                        if (protein > 0)
                          Expanded(
                            flex: (protein / totalMacros * 100).round(),
                            child: Container(color: AppColors.protein),
                          ),
                        if (carbs > 0)
                          Expanded(
                            flex: (carbs / totalMacros * 100).round(),
                            child: Container(color: AppColors.carbs),
                          ),
                        if (fat > 0)
                          Expanded(
                            flex: (fat / totalMacros * 100).round(),
                            child: Container(color: AppColors.fat),
                          ),
                      ],
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 10),

          // Mini macro badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroMacroText(label: 'Protein', grams: protein, color: AppColors.protein),
              _HeroMacroText(label: 'Carbs', grams: carbs, color: AppColors.carbs),
              _HeroMacroText(label: 'Fat', grams: fat, color: AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMacroText extends StatelessWidget {
  const _HeroMacroText({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ${grams.toStringAsFixed(grams.truncateToDouble() == grams ? 0 : 1)}g',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPACT FORM FIELDS
// ═════════════════════════════════════════════════════════════════════════════

class _SimpleInputField extends StatelessWidget {
  const _SimpleInputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
    this.icon,
    this.suffixText,
    this.maxLines = 1,
    required this.isDark,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final String? suffixText;
  final int maxLines;
  final bool isDark;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          maxLines: maxLines,
          scrollPadding: const EdgeInsets.only(bottom: 80.0, top: 20.0),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorMaxLines: 2,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.darkTextTertiary : const Color(0xFFAFA79C),
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    size: 17,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF8E8E93),
                  )
                : null,
            suffixIcon: suffixText != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suffixText!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            fillColor: surfaceAlt,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactMacroField extends StatelessWidget {
  const _CompactMacroField({
    required this.controller,
    required this.label,
    required this.color,
    required this.isDark,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textPrimary,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Color color;
  final bool isDark;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textPrimary;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [InputValidators.decimalFormatter],
          onChanged: onChanged,
          scrollPadding: const EdgeInsets.only(bottom: 80.0, top: 20.0),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: 'g',
            suffixStyle: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            fillColor: surfaceAlt,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
