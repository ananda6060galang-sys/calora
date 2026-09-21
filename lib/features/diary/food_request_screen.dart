import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/input_validators.dart';
import '../../models/food_category.dart';
import 'providers/food_request_provider.dart';

/// CALORA - FOOD REQUEST SCREEN
///
/// Full page (pushed via MaterialPageRoute) for submitting a food that is
/// missing from the catalog. New submissions go through `food_request`
/// (pending/approved/rejected); users never write directly to `foods`.
/// Chrome and button styling follow the project's PersonalInformationScreen.
class FoodRequestScreen extends ConsumerStatefulWidget {
  const FoodRequestScreen({super.key});

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

  void _submit() {
    final name = _nameCtrl.text.trim();
    final serving = _servingCtrl.text.trim();
    final cals = int.tryParse(_caloriesCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final pro = double.tryParse(_proteinCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    final carbs = double.tryParse(_carbsCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    final fat = double.tryParse(_fatCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

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

    ref.read(foodRequestProvider.notifier).add(
          foodName: name,
          categoryId: _selectedCategoryId!,
          servingLabel: serving,
          calories: cals,
          proteinG: pro,
          carbsG: carbs,
          fatG: fat,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('diary.foodRequest.submittedSuccess'.tr()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'diary.foodRequest.title'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Image.asset(
                'assets/notfound.webp',
                height: 96,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Text(
            'diary.foodRequest.subtitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Food Name Field
          _RequestField(
            controller: _nameCtrl,
            label: 'diary.foodRequest.foodNameLabel'.tr(),
            hint: 'diary.foodRequest.foodNameHint'.tr(),
            icon: Icons.restaurant_menu_rounded,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          Text(
            'diary.foodRequest.categoryLabel'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              hintText: 'diary.foodRequest.selectCategoryHint'.tr(),
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.lightTextTertiary,
              ),
              prefixIcon: const Icon(
                Icons.category_rounded,
                size: 18,
              ),
              fillColor: surfaceColor,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                  width: 1.5,
                ),
              ),
            ),
            dropdownColor: surfaceColor,
            items: mockFoodCategories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Text(
                  cat.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 16),

          // Serving Label & Calories
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RequestField(
                  controller: _servingCtrl,
                  label: 'diary.foodRequest.servingSizeLabel'.tr(),
                  hint: 'diary.foodRequest.servingSizeHint'.tr(),
                  icon: Icons.scale_rounded,
                  errorText: _servingError,
                  onChanged: (_) {
                    if (_servingError != null) setState(() => _servingError = null);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RequestField(
                  controller: _caloriesCtrl,
                  label: 'diary.foodRequest.caloriesLabel'.tr(),
                  hint: 'diary.foodRequest.caloriesHint'.tr(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [InputValidators.integerFormatter],
                  icon: Icons.local_fire_department_rounded,
                  errorText: _caloriesError,
                  onChanged: (_) {
                    if (_caloriesError != null) setState(() => _caloriesError = null);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Macros Row (Protein, Carbs, Fat)
          Text(
            'diary.foodRequest.nutritionalBreakdown'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RequestField(
                  controller: _proteinCtrl,
                  label: 'diary.foodRequest.proteinLabel'.tr(),
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [InputValidators.decimalFormatter],
                  errorText: _proteinError,
                  onChanged: (_) {
                    if (_proteinError != null) setState(() => _proteinError = null);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestField(
                  controller: _carbsCtrl,
                  label: 'diary.foodRequest.carbsLabel'.tr(),
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [InputValidators.decimalFormatter],
                  errorText: _carbsError,
                  onChanged: (_) {
                    if (_carbsError != null) setState(() => _carbsError = null);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestField(
                  controller: _fatCtrl,
                  label: 'diary.foodRequest.fatLabel'.tr(),
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [InputValidators.decimalFormatter],
                  errorText: _fatError,
                  onChanged: (_) {
                    if (_fatError != null) setState(() => _fatError = null);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Optional Notes
          _RequestField(
            controller: _notesCtrl,
            label: 'diary.foodRequest.notesLabel'.tr(),
            hint: 'diary.foodRequest.notesHint'.tr(),
            maxLines: 2,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Submit Button (matches PersonalInformationScreen save button)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.accent : const Color(0xFF1B3D22),
                foregroundColor:
                    isDark ? const Color(0xFF0F1410) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'diary.foodRequest.submitButton'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Input Field ───────────────────────────────────────────────────────

class _RequestField extends StatelessWidget {
  const _RequestField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
    this.icon,
    this.maxLines = 1,
    required this.isDark,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final int maxLines;
  final bool isDark;

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
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorMaxLines: 2,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.lightTextTertiary,
            ),
            prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
