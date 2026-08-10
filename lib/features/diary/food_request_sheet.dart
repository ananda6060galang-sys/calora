import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
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
        const SnackBar(content: Text('Please fill out all required fields.')),
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

    Navigator.of(context).pop(); // Close the request sheet
    Navigator.of(context).pop(); // Close the add food sheet
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food request submitted successfully! It is now pending review.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request a food',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Your request will be reviewed before it's available in the food database.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Food name',
                        hint: 'e.g. Chicken Breast',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: mockFoodCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildTextField(
                        controller: _servingCtrl,
                        label: 'Serving label',
                        hint: 'e.g. 100g, 1 cup',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildTextField(
                        controller: _caloriesCtrl,
                        label: 'Calories',
                        hint: 'Calories per serving',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _proteinCtrl,
                              label: 'Protein (g)',
                              hint: '0.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildTextField(
                              controller: _carbsCtrl,
                              label: 'Carbs (g)',
                              hint: '0.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildTextField(
                              controller: _fatCtrl,
                              label: 'Fat (g)',
                              hint: '0.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Optional notes',
                        hint: 'Any details to help us verify?',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom
                      : AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: AppButton(
                  label: 'Submit Request',
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
