import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/food_request.dart';
import 'food_request_screen.dart';
import 'providers/food_request_provider.dart';

/// CALORA - MY FOOD SUBMISSIONS SCREEN
///
/// Full page (pushed via MaterialPageRoute) listing the foods this user has
/// submitted to `food_request`, each with its moderation status
/// (pending/approved/rejected). Read-only: approval is the Admin Web's job.
/// Chrome follows the project's PersonalInformationScreen pattern.
class MyFoodSubmissionsScreen extends ConsumerWidget {
  const MyFoodSubmissionsScreen({super.key});

  void _openSubmitFood(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FoodRequestScreen(),
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
    final accentColor = isDark ? AppColors.accent : const Color(0xFF2E6319);

    // Newest submission first.
    final ordered = [...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
            'profile.myFoodRequests'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      floatingActionButton: ordered.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openSubmitFood(context),
              backgroundColor: accentColor,
              foregroundColor:
                  isDark ? const Color(0xFF0F1410) : Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'profile.submitFood'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: ordered.isEmpty
          ? _EmptyState(
              onSubmit: () => _openSubmitFood(context),
              isDark: isDark,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentColor,
            )
          : ListView.separated(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              itemCount: ordered.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
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
                return _RequestCard(
                  request: ordered[index - 1],
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  dividerColor: dividerColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
    );
  }
}

// ── EMPTY STATE ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onSubmit,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
  });

  final VoidCallback onSubmit;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentColor;

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: dividerColor, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'profile.requestsEmptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
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
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'profile.submitFood'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.accent : const Color(0xFF1B3D22),
                  foregroundColor:
                      isDark ? const Color(0xFF0F1410) : Colors.white,
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

// ── REQUEST CARD ────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final FoodRequest request;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  ({Color color, String label, IconData icon}) _status() {
    switch (request.status) {
      case 'approved':
        return (
          color: isDark ? AppColors.accent : const Color(0xFF2E6319),
          label: 'profile.statusApproved'.tr(),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'rejected':
        return (
          color: AppColors.protein,
          label: 'profile.statusRejected'.tr(),
          icon: Icons.cancel_outlined,
        );
      case 'pending':
      default:
        return (
          color: AppColors.carbs,
          label: 'profile.statusPending'.tr(),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.foodName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: status.color.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 12, color: status.color),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${request.servingLabel} · ${request.calories} kcal',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'P: ${request.proteinG.round()}g · C: ${request.carbsG.round()}g · F: ${request.fatG.round()}g',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textSecondary.withValues(alpha: 0.8),
            ),
          ),
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
