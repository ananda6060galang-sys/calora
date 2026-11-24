import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/food_category.dart';
import '../../models/food_request.dart';
import 'food_request_screen.dart';
import 'providers/food_request_provider.dart';

/// CALORA - MY FOOD SUBMISSIONS SCREEN
///
/// Designed with the exact visual language of [FoodRequestScreen]:
/// Clean, card-based layout, live nutrition aesthetic, subtle macro proportion bars,
/// and clear moderation status badges. Default is empty until the user submits a food.
class MyFoodSubmissionsScreen extends ConsumerWidget {
  const MyFoodSubmissionsScreen({super.key});

  void _openSubmitFood(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FoodRequestScreen(),
      ),
    );
  }

  void _openDetailSheet(
    BuildContext context,
    WidgetRef ref,
    FoodRequest request,
    bool isDark,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FoodSubmissionDetailSheet(
        request: request,
        isDark: isDark,
        onEdit: () async {
          Navigator.of(sheetContext).pop();
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => FoodRequestScreen(editRequest: request),
            ),
          );
        },
        onDelete: () async {
          Navigator.of(sheetContext).pop();
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogCtx) => _DeleteConfirmDialog(
              isDark: isDark,
              foodName: request.foodName,
            ),
          );
          if (confirmed == true) {
            ref.read(foodRequestProvider.notifier).delete(request.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'profile.submissionDeleted'.tr(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(foodRequestProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final buttonBg = isDark ? AppColors.accent : const Color(0xFF1B3D22);
    final buttonFg = isDark ? const Color(0xFF0F1410) : Colors.white;

    // Sort newest first
    final ordered = [...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
          'profile.myFoodRequests'.tr(),
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      floatingActionButton: ordered.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openSubmitFood(context),
              backgroundColor: buttonBg,
              foregroundColor: buttonFg,
              elevation: 2,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'profile.submitFood'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(foodRequestProvider.notifier).reload(),
        child: ordered.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.75,
                  child: _EmptySubmissionsState(
                    onSubmit: () => _openSubmitFood(context),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    dividerColor: dividerColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    buttonBg: buttonBg,
                    buttonFg: buttonFg,
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
                itemCount: ordered.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 2),
                      child: Text(
                        'profile.myFoodRequestsSubtitle'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    );
                  }
                  final req = ordered[index - 1];
                  return _FoodSubmissionCard(
                    request: req,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () => _openDetailSheet(context, ref, req, isDark),
                  );
                },
              ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CLEAN SUBMISSION CARD
// ═════════════════════════════════════════════════════════════════════════════

class _FoodSubmissionCard extends StatelessWidget {
  const _FoodSubmissionCard({
    required this.request,
    required this.isDark,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    this.onTap,
  });

  final FoodRequest request;
  final bool isDark;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;

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

  String _categoryName(String categoryId) {
    final match = mockFoodCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => mockFoodCategories.first,
    );
    return match.name;
  }

  ({Color color, Color bgTint, String label, IconData icon}) _status() {
    switch (request.status.toLowerCase()) {
      case 'approved':
        return (
          color: const Color(0xFF16A34A),
          bgTint: isDark
              ? const Color(0xFF16A34A).withValues(alpha: 0.16)
              : const Color(0xFFDCFCE7),
          label: 'profile.statusApproved'.tr(),
          icon: Icons.check_circle_rounded,
        );
      case 'rejected':
        return (
          color: AppColors.danger,
          bgTint: isDark
              ? AppColors.danger.withValues(alpha: 0.16)
              : const Color(0xFFFFE4E6),
          label: 'profile.statusRejected'.tr(),
          icon: Icons.cancel_rounded,
        );
      case 'pending':
      default:
        return (
          color: AppColors.warning,
          bgTint: isDark
              ? AppColors.warning.withValues(alpha: 0.16)
              : const Color(0xFFFEF3C7),
          label: 'profile.statusPending'.tr(),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    final isId = context.locale.languageCode == 'id';
    final diff = DateTime.now().difference(date);

    if (diff.inHours < 24 && diff.inDays == 0) {
      if (diff.inHours == 0) {
        final m = diff.inMinutes.clamp(1, 60);
        return isId ? '$m mnt lalu' : '${m}m ago';
      }
      return isId ? '${diff.inHours} jam lalu' : '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return isId ? '${diff.inDays} hari lalu' : '${diff.inDays}d ago';
    }
    return DateFormat('d MMM yyyy', context.locale.languageCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _categoryName(request.categoryId);
    final categoryIcon = _categoryIcon(categoryName);
    final status = _status();
    final dateStr = _formatDate(request.createdAt, context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8DF),
          width: 0.8,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Category Icon + (Food Name & Serving/Category) + Status Pill & Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Squircle category icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceAlt
                            : const Color(0xFFF2F5F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5EBE0),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        categoryIcon,
                        size: 21,
                        color:
                            isDark ? AppColors.accent : const Color(0xFF2E6319),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.foodName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${request.servingLabel} · $categoryName',
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
                    const SizedBox(width: 8),

                    // Status pill badge + Subtle tap chevron
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status.bgTint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: status.color.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon, size: 11, color: status.color),
                              const SizedBox(width: 4),
                              Text(
                                status.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: status.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Hairline divider
                Container(
                  height: 0.8,
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.7)
                      : const Color(0xFFF0F3ED),
                ),

                const SizedBox(height: 12),

                // Row 2: Macro Badges (Left) & Calories + Date (Right)
                Row(
                  children: [
                    _MacroBadge(
                      label: 'P',
                      grams: request.proteinG,
                      color: AppColors.protein,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _MacroBadge(
                      label: 'C',
                      grams: request.carbsG,
                      color: AppColors.carbs,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _MacroBadge(
                      label: 'F',
                      grams: request.fatG,
                      color: AppColors.fat,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${request.calories}',
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        Text(
                          'kcal',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $dateStr',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Optional Curator Note / Feedback (e.g. rejection reason)
                if (request.notes != null &&
                    request.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: request.status.toLowerCase() == 'rejected'
                          ? (isDark
                              ? AppColors.danger.withValues(alpha: 0.12)
                              : const Color(0xFFFFF1F2))
                          : (isDark
                              ? AppColors.darkSurfaceAlt
                              : const Color(0xFFF8FAF7)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: request.status.toLowerCase() == 'rejected'
                            ? AppColors.danger.withValues(alpha: 0.25)
                            : (isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8DF)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          request.status.toLowerCase() == 'rejected'
                              ? Icons.error_outline_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: request.status.toLowerCase() == 'rejected'
                              ? AppColors.danger
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: request.status.toLowerCase() == 'rejected'
                                  ? (isDark
                                      ? const Color(0xFFFF9494)
                                      : const Color(0xFFB91C1C))
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUBMISSION DETAIL BOTTOM SHEET (Antislop UI/UX)
// ═════════════════════════════════════════════════════════════════════════════

class _FoodSubmissionDetailSheet extends StatelessWidget {
  const _FoodSubmissionDetailSheet({
    required this.request,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodRequest request;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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

  String _categoryName(String categoryId) {
    final match = mockFoodCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => mockFoodCategories.first,
    );
    return match.name;
  }

  ({Color color, Color bgTint, String label, IconData icon}) _status() {
    switch (request.status.toLowerCase()) {
      case 'approved':
        return (
          color: const Color(0xFF16A34A),
          bgTint: isDark
              ? const Color(0xFF16A34A).withValues(alpha: 0.16)
              : const Color(0xFFDCFCE7),
          label: 'profile.statusApproved'.tr(),
          icon: Icons.check_circle_rounded,
        );
      case 'rejected':
        return (
          color: AppColors.danger,
          bgTint: isDark
              ? AppColors.danger.withValues(alpha: 0.16)
              : const Color(0xFFFFE4E6),
          label: 'profile.statusRejected'.tr(),
          icon: Icons.cancel_rounded,
        );
      case 'pending':
      default:
        return (
          color: AppColors.warning,
          bgTint: isDark
              ? AppColors.warning.withValues(alpha: 0.16)
              : const Color(0xFFFEF3C7),
          label: 'profile.statusPending'.tr(),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  String _formatFullDate(DateTime date, BuildContext context) {
    return DateFormat(
      'EEEE, d MMMM yyyy · HH:mm',
      context.locale.languageCode,
    ).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _categoryName(request.categoryId);
    final categoryIcon = _categoryIcon(categoryName);
    final status = _status();
    final fullDateStr = _formatFullDate(request.createdAt, context);

    final isApproved = request.status.toLowerCase() == 'approved';
    final isRejected = request.status.toLowerCase() == 'rejected';

    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF6F8F5);
    final dividerColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE5EBE0);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final screenHeight = MediaQuery.sizeOf(context).height;

    return RepaintBoundary(
      child: Container(
        height: screenHeight * 0.82,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.card(isDark),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFD4DAD0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
              child: Row(
                children: [
                  // Category Squircle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceAlt
                          : const Color(0xFFF2F5F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dividerColor,
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      categoryIcon,
                      size: 21,
                      color:
                          isDark ? AppColors.accent : const Color(0xFF2E6319),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.submissionDetails'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Status badge pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: status.bgTint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: status.color.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon, size: 11, color: status.color),
                              const SizedBox(width: 4),
                              Text(
                                status.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: status.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button (44px target)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(color: dividerColor, width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 0.8, color: dividerColor),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Name & Serving
                    Text(
                      request.foodName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.servingLabel} · $categoryName',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.accent
                            : const Color(0xFF2E6319),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullDateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary.withValues(alpha: 0.8),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status Callout Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: status.bgTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(status.icon, size: 16, color: status.color),
                              const SizedBox(width: 8),
                              Text(
                                status.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: status.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isRejected
                                ? 'profile.statusRejectedNotice'.tr()
                                : (isApproved
                                    ? 'profile.statusApprovedNotice'.tr()
                                    : 'profile.statusPendingNotice'.tr()),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: status.color.withValues(alpha: 0.9),
                            ),
                          ),
                          // Curator feedback quote if rejected
                          if (isRejected &&
                              request.notes != null &&
                              request.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: status.color.withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'profile.curatorNotesTitle'.tr(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: status.color,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    request.notes!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nutritional Breakdown Section
                    Text(
                      'profile.nutritionSummary'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4 Metric cards
                    Row(
                      children: [
                        // Calories
                        Expanded(
                          child: _NutritionTile(
                            label: 'Calories',
                            value: '${request.calories}',
                            unit: 'kcal',
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Protein
                        Expanded(
                          child: _NutritionTile(
                            label: 'Protein',
                            value:
                                '${request.proteinG == request.proteinG.roundToDouble() ? request.proteinG.round() : request.proteinG.toStringAsFixed(1)}',
                            unit: 'g',
                            color: AppColors.protein,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Carbs
                        Expanded(
                          child: _NutritionTile(
                            label: 'Carbs',
                            value:
                                '${request.carbsG == request.carbsG.roundToDouble() ? request.carbsG.round() : request.carbsG.toStringAsFixed(1)}',
                            unit: 'g',
                            color: AppColors.carbs,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Fat
                        Expanded(
                          child: _NutritionTile(
                            label: 'Fat',
                            value:
                                '${request.fatG == request.fatG.roundToDouble() ? request.fatG.round() : request.fatG.toStringAsFixed(1)}',
                            unit: 'g',
                            color: AppColors.fat,
                            surfaceAlt: surfaceAlt,
                            dividerColor: dividerColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Submitter notes (if present and not rejected)
                    if (!isRejected &&
                        request.notes != null &&
                        request.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'profile.userNotesTitle'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dividerColor, width: 0.8),
                        ),
                        child: Text(
                          request.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Docked Bottom Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: dividerColor, width: 0.8),
                ),
              ),
              child: SafeArea(
                top: false,
                child: isApproved
                    ? SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceAlt
                                : const Color(0xFFF2F5F0),
                            foregroundColor: textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: dividerColor, width: 0.8),
                            ),
                          ),
                          child: Text(
                            'profile.close'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          // Cancel / Delete button
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: onDelete,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  'profile.cancelSubmission'.tr(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: BorderSide(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 0.8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Edit button
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  isRejected
                                      ? (context.locale.languageCode == 'id'
                                          ? 'Revisi & Ajukan'
                                          : 'Revise & Resubmit')
                                      : 'profile.editSubmission'.tr(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.accent
                                      : const Color(0xFF1B3D22),
                                  foregroundColor: isDark
                                      ? const Color(0xFF0F1410)
                                      : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
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
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({
    required this.isDark,
    required this.foodName,
  });

  final bool isDark;
  final String foodName;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 24,
        ),
      ),
      title: Text(
        'profile.cancelSubmissionConfirm'.tr(),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      content: Text(
        'profile.cancelSubmissionSubtitle'.tr(),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'profile.close'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'profile.cancelSubmission'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroBadge extends StatelessWidget {
  const _MacroBadge({
    required this.label,
    required this.grams,
    required this.color,
    required this.isDark,
  });

  final String label;
  final double grams;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final valueStr =
        grams.toStringAsFixed(grams.truncateToDouble() == grams ? 0 : 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '${valueStr}g',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CLEAN EMPTY STATE (Matches Food Request Aesthetic)
// ═════════════════════════════════════════════════════════════════════════════

class _EmptySubmissionsState extends StatelessWidget {
  const _EmptySubmissionsState({
    required this.onSubmit,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.buttonBg,
    required this.buttonFg,
  });

  final VoidCallback onSubmit;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color buttonBg;
  final Color buttonFg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : const Color(0xFFEFF8EA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFD4E8CD),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 34,
                color: isDark ? AppColors.accent : const Color(0xFF1B3D22),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'profile.requestsEmptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'profile.requestsEmptyBody'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'diary.foodRequest.title'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: buttonFg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
