import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/food_category.dart';
import 'providers/food_request_provider.dart';

class FoodRequestSheet extends StatefulWidget {
  const FoodRequestSheet({super.key, required this.ref});

  final WidgetRef ref;

  @override
  State<FoodRequestSheet> createState() => _FoodRequestSheetState();
}

class _FoodRequestSheetState extends State<FoodRequestSheet> {
  final _nameCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedCategoryId;

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
    final cals = int.tryParse(_caloriesCtrl.text.trim()) ?? 0;

    if (name.isEmpty || serving.isEmpty || cals <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.ref.read(foodRequestProvider.notifier).add(
          foodName: name,
          categoryId: _selectedCategoryId!,
          servingLabel: serving,
          calories: cals,
          proteinG: double.tryParse(_proteinCtrl.text.trim()) ?? 0.0,
          carbsG: double.tryParse(_carbsCtrl.text.trim()) ?? 0.0,
          fatG: double.tryParse(_fatCtrl.text.trim()) ?? 0.0,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food request submitted successfully! Pending review.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Alignment.bottomCenter.child(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),

              // Navigation / Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Request New Food',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

              // Form Scroll Area (Smooth hardware accelerated scrolling)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                  children: [
                    Text(
                      'Add missing nutrition details for admin verification.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Food Name Field
                    _SheetField(
                      controller: _nameCtrl,
                      label: 'Food Name *',
                      hint: 'e.g. Grilled Salmon Bowl',
                      icon: Icons.restaurant_menu_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Text(
                      'Category *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        hintText: 'Select Food Category',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextTertiary),
                        prefixIcon: const Icon(Icons.category_rounded, size: 18),
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                      ),
                      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                      items: mockFoodCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(
                            cat.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),

                    // Serving Label & Calories
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            controller: _servingCtrl,
                            label: 'Serving Size *',
                            hint: 'e.g. 100g, 1 bowl',
                            icon: Icons.scale_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SheetField(
                            controller: _caloriesCtrl,
                            label: 'Calories (kcal) *',
                            hint: 'e.g. 350',
                            keyboardType: TextInputType.number,
                            icon: Icons.local_fire_department_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Macros Row (Protein, Carbs, Fat)
                    Text(
                      'Nutritional Breakdown (Grams)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            controller: _proteinCtrl,
                            label: 'Protein (g)',
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SheetField(
                            controller: _carbsCtrl,
                            label: 'Carbs (g)',
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SheetField(
                            controller: _fatCtrl,
                            label: 'Fat (g)',
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Optional Notes
                    _SheetField(
                      controller: _notesCtrl,
                      label: 'Additional Notes',
                      hint: 'Details to assist admin verification...',
                      maxLines: 2,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Submit Food Request',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0E0F10),
                          ),
                        ),
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

// ─── Helper Input Field ───────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.icon,
    this.maxLines = 1,
    required this.isDark,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
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
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextTertiary),
            prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

extension _AlignmentChildExtension on AlignmentGeometry {
  Widget child({required Widget child}) {
    return Align(alignment: this, child: child);
  }
}
