import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/calora_avatar.dart';
import '../../models/food_request.dart';
import '../../models/user_profile.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import '../diary/food_request_sheet.dart';
import '../diary/providers/food_request_provider.dart';
import 'settings_screen.dart';

/// Redesigned Calora Profile Screen.
///
/// Faithfully reproduces the Figma reference image design with the `profile-banner`
/// illustration asset, overlapping circular avatar, edit pencil badge, user metadata,
/// edit profile pill button, and grouped Personal section card, finished with a matching
/// Account & Preferences continuation section.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _goalLabel(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'dashboard.goals.loseWeight'.tr();
      case Goal.maintainWeight:
        return 'dashboard.goals.maintainWeight'.tr();
      case Goal.gainWeight:
        return 'dashboard.goals.gainWeight'.tr();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final foodRequests = ref.watch(foodRequestProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    final displayName = profile.name.isNotEmpty ? profile.name : 'Minji';
    final userEmail = currentUser?.email ?? 'NJZ2@gmail.com';

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. TOP BANNER & OVERLAPPING AVATAR ─────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Organic Curved Banner Background Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                  child: Container(
                    height: 195,
                    width: double.infinity,
                    color: const Color(0xFFC7F464),
                    child: Image.asset(
                      'assets/profile-banner.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: 195,
                    ),
                  ),
                ),

                // Top Navigation Bar (Profile title, ENG/ID pill, Settings gear)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'profile.title'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Row(
                          children: [
                            // Quick Language Pill Indicator (1-tap instant switch)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                final currentLang = context.locale.languageCode;
                                final nextLocale = currentLang == 'en'
                                    ? const Locale('id')
                                    : const Locale('en');
                                context.setLocale(nextLocale);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'ENG/ID',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Settings Icon Button (Single Home for Settings)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openSettings(context),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.settings_outlined,
                                  size: 17,
                                  color: Color(0xFF111111),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Overlapping Circular Avatar
                Positioned(
                  bottom: -39,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openEditProfile(context, profile),
                          child: CaloraAvatar(
                            avatarUrl: profile.avatarUrl,
                            displayName: displayName,
                            size: 78,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openEditProfile(context, profile),
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceAlt
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dividerColor,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.08,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E6319),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vertical Offset for lower half of overlapping avatar
            const SizedBox(height: 48),

            // ── 2. USER PROFILE DETAILS ────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userEmail,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Outlined "Edit Profile" Pill Button (Hug-content compact pill)
                  Material(
                    color: surfaceColor,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFD4D4D4),
                        width: 1.0,
                      ),
                    ),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => _openEditProfile(context, profile),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                        child: Text(
                          'profile.editProfile'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── 3. BODY METRICS QUICK STRIP ───────────────────────────
            _BodyMetricsStrip(
              profile: profile,
              isDark: isDark,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => _openPersonalInformation(context, profile),
            ),

            const SizedBox(height: 16),

            // ── 4. NUTRITION & METABOLIC BLUEPRINT CARD ───────────────
            _NutritionBlueprintCard(
              profile: profile,
              isDark: isDark,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              goalLabel: _goalLabel(profile.goal),
              onTap: () => _openGoalsAndNutrition(context, profile),
            ),

            const SizedBox(height: 22),

            // ── 5. PERSONAL SECTION ───────────────────────────────────
            _SectionHeader(
              'Personal',
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor, width: 0.8),
                  boxShadow: AppShadows.card(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ProfileNavRow(
                      icon: Icons.person_outline_rounded,
                      title: 'onboarding.personalInfoTitle'.tr(),
                      subtitle:
                          '${profile.gender == Gender.male ? 'onboarding.male'.tr() : 'onboarding.female'.tr()} • ${profile.age} ${'profile.yearsOld'.tr(args: ['']).trim()} • ${profile.weightKg.toStringAsFixed(1)} kg',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openPersonalInformation(context, profile),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: dividerColor,
                      ),
                    ),
                    _ProfileNavRow(
                      icon: Icons.track_changes_rounded,
                      title: 'profile.goalsAndNutrition'.tr(),
                      subtitle:
                          '${_goalLabel(profile.goal)} • ${profile.dailyCalorieTarget.round()} kcal/day',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openGoalsAndNutrition(context, profile),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── 6. FOOD CONTRIBUTIONS SECTION (PRD ERD food_request) ──
            _SectionHeader(
              'profile.foodContributions'.tr(),
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor, width: 0.8),
                  boxShadow: AppShadows.card(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ProfileNavRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'profile.myFoodRequests'.tr(),
                      subtitle:
                          '${foodRequests.length} submissions • ${foodRequests.where((r) => r.status == 'approved').length} approved',
                      badge: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2E6319))
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${foodRequests.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                          ),
                        ),
                      ),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openFoodRequests(context, ref, foodRequests),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: dividerColor,
                      ),
                    ),
                    _ProfileNavRow(
                      icon: Icons.add_circle_outline_rounded,
                      iconColor: isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319),
                      title: 'profile.submitFood'.tr(),
                      subtitle: 'profile.submitFoodSubtitle'.tr(),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openSubmitFood(context, ref),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── 7. PREFERENCES & SECURITY SECTION ─────────────────────
            _SectionHeader(
              'profile.preferencesAndSettings'.tr(),
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor, width: 0.8),
                  boxShadow: AppShadows.card(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ProfileNavRow(
                      icon: Icons.tune_rounded,
                      title: 'profile.settings'.tr(),
                      subtitle: 'profile.managePreferences'.tr(),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openSettings(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: dividerColor,
                      ),
                    ),
                    _ProfileNavRow(
                      icon: Icons.shield_outlined,
                      title: 'profile.privacySecurity'.tr(),
                      subtitle: 'profile.privacySecuritySubtitle'.tr(),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openPrivacySecurity(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── 8. CALORA MEMBERSHIP FOOTER BADGE ─────────────────────
            _CaloraMembershipFooter(
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dividerColor: dividerColor,
              surfaceColor: surfaceColor,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers & Navigation ────────────────────────────────────

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openEditProfile(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  void _openPersonalInformation(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PersonalInformationSheet(profile: profile),
    );
  }

  void _openGoalsAndNutrition(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalsAndNutritionSheet(profile: profile),
    );
  }

  void _openSubmitFood(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodRequestSheet(ref: ref),
    );
  }

  void _openFoodRequests(
    BuildContext context,
    WidgetRef ref,
    List<FoodRequest> requests,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FoodRequestsSheet(
        requests: requests,
        onNewRequest: () => _openSubmitFood(context, ref),
      ),
    );
  }

  void _openPrivacySecurity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PrivacySecuritySheet(),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SECTION HEADER
// ════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.textSecondary});

  final String title;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// BODY METRICS QUICK STRIP
// ════════════════════════════════════════════════════════════════

class _BodyMetricsStrip extends StatelessWidget {
  const _BodyMetricsStrip({
    required this.profile,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final UserProfile profile;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final genderStr = profile.gender == Gender.male
        ? 'onboarding.male'.tr()
        : 'onboarding.female'.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Row(
              children: [
                _buildMetricItem(
                  label: 'profile.weight'.tr(),
                  value: '${profile.weightKg.toStringAsFixed(1)} kg',
                ),
                _buildDivider(),
                _buildMetricItem(
                  label: 'profile.height'.tr(),
                  value: '${profile.heightCm.round()} cm',
                ),
                _buildDivider(),
                _buildMetricItem(
                  label: 'profile.age'.tr(),
                  value:
                      '${profile.age} ${'profile.yearsOld'.tr(args: ['']).trim()}',
                ),
                _buildDivider(),
                _buildMetricItem(
                  label: 'profile.gender'.tr(),
                  value: genderStr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({required String label, required String value}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 0.8,
      color: dividerColor,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// NUTRITION & METABOLIC BLUEPRINT CARD
// ════════════════════════════════════════════════════════════════

class _NutritionBlueprintCard extends StatelessWidget {
  const _NutritionBlueprintCard({
    required this.profile,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.goalLabel,
    required this.onTap,
  });

  final UserProfile profile;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final String goalLabel;
  final VoidCallback onTap;

  String _activityShortLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Light';
      case ActivityLevel.moderate:
        return 'Moderate';
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Macro proportions for segmented bar
    final proteinCals = profile.proteinTargetG * 4;
    final carbsCals = profile.carbsTargetG * 4;
    final fatCals = profile.fatTargetG * 9;
    final totalCals =
        (proteinCals + carbsCals + fatCals).clamp(1.0, 10000.0);

    final pRatio = (proteinCals / totalCals).clamp(0.1, 0.7);
    final cRatio = (carbsCals / totalCals).clamp(0.1, 0.7);
    final fRatio = (fatCals / totalCals).clamp(0.1, 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Flame icon, Energy Budget, Calories & Goal Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.protein.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.protein,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.energyBudget'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${profile.dailyCalorieTarget.round()}',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'kcal / day',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Goal Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.accent.withValues(alpha: 0.18)
                            : const Color(0xFFE8F8D0),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isDark
                              ? AppColors.accent.withValues(alpha: 0.35)
                              : const Color(0xFFC7F464),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        goalLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.accent
                              : const Color(0xFF2E6319),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Atwater Proportional Macro Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (pRatio * 100).round(),
                          child: Container(color: AppColors.protein),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: (cRatio * 100).round(),
                          child: Container(color: AppColors.carbs),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: (fRatio * 100).round(),
                          child: Container(color: AppColors.fat),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Macro Target Chips (Protein, Carbs, Fat)
                Row(
                  children: [
                    _buildMacroChip(
                      label: 'dashboard.protein'.tr(),
                      grams: '${profile.proteinTargetG.round()}g',
                      pct: '${(pRatio * 100).round()}%',
                      color: AppColors.protein,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      label: 'dashboard.carbs'.tr(),
                      grams: '${profile.carbsTargetG.round()}g',
                      pct: '${(cRatio * 100).round()}%',
                      color: AppColors.carbs,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      label: 'dashboard.fat'.tr(),
                      grams: '${profile.fatTargetG.round()}g',
                      pct: '${(fRatio * 100).round()}%',
                      color: AppColors.fat,
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(height: 1, thickness: 0.6, color: dividerColor),
                const SizedBox(height: 12),

                // Mifflin-St Jeor Metabolic Baselines (BMR, TDEE, Activity)
                Row(
                  children: [
                    _buildMetabolicStat(
                      label: 'BMR',
                      sublabel: 'Basal Burn',
                      value: '${profile.bmr.round()} kcal',
                    ),
                    Container(height: 28, width: 0.8, color: dividerColor),
                    _buildMetabolicStat(
                      label: 'TDEE',
                      sublabel: 'Maintenance',
                      value: '${profile.tdee.round()} kcal',
                    ),
                    Container(height: 28, width: 0.8, color: dividerColor),
                    _buildMetabolicStat(
                      label: 'Activity',
                      sublabel: _activityShortLabel(profile.activityLevel),
                      value: 'Level',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip({
    required String label,
    required String grams,
    required String pct,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.20),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  grams,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  pct,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetabolicStat({
    required String label,
    required String sublabel,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FOOD REQUESTS BOTTOM SHEET
// ════════════════════════════════════════════════════════════════

class _FoodRequestsSheet extends StatelessWidget {
  const _FoodRequestsSheet({
    required this.requests,
    required this.onNewRequest,
  });

  final List<FoodRequest> requests;
  final VoidCallback onNewRequest;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: divider, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.myFoodRequests'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'profile.myFoodRequestsSubtitle'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  onNewRequest();
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                tooltip: 'profile.submitFood'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (requests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: divider, width: 0.8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 38,
                    color: textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No food submissions yet',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help expand Calora\'s food catalog by submitting foods that are not in the database.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNewRequest();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'profile.submitFood'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F1410),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF0F1410),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final req = requests[idx];
                  Color statusColor;
                  String statusLabel;
                  IconData statusIcon;

                  switch (req.status) {
                    case 'approved':
                      statusColor = isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319);
                      statusLabel = 'Approved';
                      statusIcon = Icons.check_circle_outline_rounded;
                      break;
                    case 'rejected':
                      statusColor = AppColors.protein;
                      statusLabel = 'Rejected';
                      statusIcon = Icons.cancel_outlined;
                      break;
                    case 'pending':
                    default:
                      statusColor = AppColors.carbs;
                      statusLabel = 'Pending Review';
                      statusIcon = Icons.hourglass_top_rounded;
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: divider, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                req.foodName,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${req.servingLabel} • ${req.calories} kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'P: ${req.proteinG.round()}g • C: ${req.carbsG.round()}g • F: ${req.fatG.round()}g',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                        if (req.notes != null && req.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            req.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PRIVACY & SECURITY SHEET
// ════════════════════════════════════════════════════════════════

class _PrivacySecuritySheet extends StatelessWidget {
  const _PrivacySecuritySheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: divider, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'profile.privacySecurity'.tr(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How Calora safeguards your personal health & nutrition data.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildSecurityCard(
            icon: Icons.lock_outline_rounded,
            title: 'Row-Level Security (RLS)',
            description:
                'Your diary entries, workouts, and biometrics are bound to your user ID. No other user or administrator can access your private logs.',
            surfaceAlt: surfaceAlt,
            divider: divider,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSecurityCard(
            icon: Icons.verified_user_outlined,
            title: 'Catalog Moderation',
            description:
                'Public food items are read-only. User-contributed foods are moderated through food_requests to maintain accurate nutritional data.',
            surfaceAlt: surfaceAlt,
            divider: divider,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSecurityCard(
            icon: Icons.fingerprint_rounded,
            title: 'Local First & Zero Ads',
            description:
                'Calora does not include advertisement SDKs or telemetry trackers. All calculations run strictly client-side.',
            surfaceAlt: surfaceAlt,
            divider: divider,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkSurfaceAlt
                    : const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Got It',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String description,
    required Color surfaceAlt,
    required Color divider,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.accent : const Color(0xFF2E6319))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.accent : const Color(0xFF2E6319),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CALORA MEMBERSHIP FOOTER
// ════════════════════════════════════════════════════════════════

class _CaloraMembershipFooter extends StatelessWidget {
  const _CaloraMembershipFooter({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.surfaceColor,
  });

  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dividerColor.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withValues(alpha: 0.20)
                    : const Color(0xFFE8F8D0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.spa_rounded,
                size: 15,
                color: isDark ? AppColors.accent : const Color(0xFF2E6319),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Calora Nutrition & Wellness • v1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'School PjBL Project • Single Student Developer',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MACRO TARGET ITEM
// ════════════════════════════════════════════════════════════════

class _MacroTargetItem extends StatelessWidget {
  const _MacroTargetItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.40),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PROFILE NAVIGATION ROW
// ════════════════════════════════════════════════════════════════

class _ProfileNavRow extends StatelessWidget {
  const _ProfileNavRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.iconColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final Color? iconColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              badge!,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: textSecondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PERSONAL INFORMATION SHEET
// ════════════════════════════════════════════════════════════════

class _PersonalInformationSheet extends StatelessWidget {
  const _PersonalInformationSheet({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

    final genderText = profile.gender == Gender.male
        ? 'onboarding.male'.tr()
        : 'onboarding.female'.tr();

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: divider, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'onboarding.personalInfoTitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'onboarding.personalInfoSubtitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Details Grid Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divider, width: 0.8),
            ),
            child: Column(
              children: [
                _InfoDetailRow(
                  label: 'auth.fullName'.tr(),
                  value: profile.name.isNotEmpty ? profile.name : 'Minji',
                  icon: Icons.person_outline_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(height: 24, thickness: 0.6, color: divider),
                _InfoDetailRow(
                  label: 'profile.gender'.tr(),
                  value: genderText,
                  icon: profile.gender == Gender.male
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(height: 24, thickness: 0.6, color: divider),
                _InfoDetailRow(
                  label: 'profile.age'.tr(),
                  value: '${profile.age} ${'profile.yearsOld'.tr(args: [''])}',
                  icon: Icons.calendar_today_outlined,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(height: 24, thickness: 0.6, color: divider),
                _InfoDetailRow(
                  label: 'profile.height'.tr(),
                  value: '${profile.heightCm.round()} cm',
                  icon: Icons.straighten_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(height: 24, thickness: 0.6, color: divider),
                _InfoDetailRow(
                  label: 'profile.weight'.tr(),
                  value: '${profile.weightKg.toStringAsFixed(1)} kg',
                  icon: Icons.scale_outlined,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Edit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditProfileSheet(profile: profile),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0F1410),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'profile.editProfile'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// GOALS & NUTRITION SHEET
// ════════════════════════════════════════════════════════════════

class _GoalsAndNutritionSheet extends StatelessWidget {
  const _GoalsAndNutritionSheet({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

    String goalTitle;
    switch (profile.goal) {
      case Goal.loseWeight:
        goalTitle = 'dashboard.goals.loseWeight'.tr();
        break;
      case Goal.maintainWeight:
        goalTitle = 'dashboard.goals.maintainWeight'.tr();
        break;
      case Goal.gainWeight:
        goalTitle = 'dashboard.goals.gainWeight'.tr();
        break;
    }

    String paceTitle;
    switch (profile.goalPace) {
      case GoalPace.gentle:
        paceTitle = 'Gentle pace (0.25 kg/wk)';
        break;
      case GoalPace.moderate:
        paceTitle = 'Moderate pace (0.5 kg/wk)';
        break;
      case GoalPace.faster:
        paceTitle = 'Faster pace (0.75 kg/wk)';
        break;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: divider, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'profile.goalsAndNutrition'.tr(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'onboarding.goalSubtitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Goals Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divider, width: 0.8),
            ),
            child: Column(
              children: [
                _InfoDetailRow(
                  label: 'profile.goal'.tr(),
                  value: goalTitle,
                  icon: Icons.track_changes_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(height: 24, thickness: 0.6, color: divider),
                _InfoDetailRow(
                  label: 'profile.goalPaceLabel'.tr(),
                  value: paceTitle,
                  icon: Icons.speed_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                if (profile.targetWeightKg != null) ...[
                  Divider(height: 24, thickness: 0.6, color: divider),
                  _InfoDetailRow(
                    label: 'onboarding.targetWeightLabel'.tr(),
                    value: '${profile.targetWeightKg!.toStringAsFixed(1)} kg',
                    icon: Icons.flag_rounded,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
                Divider(height: 24, thickness: 0.6, color: divider),
                _InfoDetailRow(
                  label: 'profile.dailyTarget'.tr(),
                  value: '${profile.dailyCalorieTarget.round()} kcal',
                  icon: Icons.local_fire_department_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Macros Summary Row
          Row(
            children: [
              _MacroTargetItem(
                label: 'dashboard.protein'.tr(),
                value: '${profile.proteinTargetG.round()} g',
                color: AppColors.protein,
                isDark: isDark,
                surfaceColor: surfaceAlt,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(width: 8),
              _MacroTargetItem(
                label: 'dashboard.carbs'.tr(),
                value: '${profile.carbsTargetG.round()} g',
                color: AppColors.carbs,
                isDark: isDark,
                surfaceColor: surfaceAlt,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(width: 8),
              _MacroTargetItem(
                label: 'dashboard.fat'.tr(),
                value: '${profile.fatTargetG.round()} g',
                color: AppColors.fat,
                isDark: isDark,
                surfaceColor: surfaceAlt,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Edit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditProfileSheet(profile: profile),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0F1410),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'profile.editProfile'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDetailRow extends StatelessWidget {
  const _InfoDetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// EDIT PROFILE SHEET (REFINED FOR IDENTITY & TARGETS)
// ════════════════════════════════════════════════════════════════

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _targetWeightCtrl;
  late Goal _selectedGoal;
  late GoalPace _selectedGoalPace;
  String? _currentAvatarUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _currentAvatarUrl = widget.profile.avatarUrl;
    _heightCtrl = TextEditingController(
      text: widget.profile.heightCm.round().toString(),
    );
    _weightCtrl = TextEditingController(
      text: widget.profile.weightKg.toStringAsFixed(1),
    );
    _targetWeightCtrl = TextEditingController(
      text: widget.profile.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
    _selectedGoal = widget.profile.goal;
    _selectedGoalPace = widget.profile.goalPace;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close photo action sheet
    if (_isUploadingPhoto) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked == null) return; // User cancelled picker

      final bytes = await picked.readAsBytes();
      if (bytes.length > ProfileService.maxAvatarSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.fileTooLarge'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';

      if (!ProfileService.allowedAvatarExtensions.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.unsupportedFileType'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      setState(() => _isUploadingPhoto = true);

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.photoUploadFailed'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final oldAvatarUrl = _currentAvatarUrl;
      final profileService = ref.read(profileServiceProvider);

      // 1. Upload new image bytes to Supabase Storage
      final newAvatarUrl = await profileService.uploadAvatar(
        userId: currentUser.id,
        bytes: bytes,
        fileExtension: ext,
      );

      // 2. Persist new avatar URL to profiles.avatar_url in Supabase
      await profileService.updateAvatarUrl(
        userId: currentUser.id,
        avatarUrl: newAvatarUrl,
      );

      // 3. Immediately refresh local profile state
      final updatedProfile = widget.profile.copyWith(
        avatarUrl: newAvatarUrl,
      );
      ref.read(userProfileProvider.notifier).state = updatedProfile;

      if (mounted) {
        setState(() {
          _currentAvatarUrl = newAvatarUrl;
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.photoUpdated'.tr()),
            backgroundColor: const Color(0xFF1B2A18),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 4. Safely clean up old avatar file from storage after new upload & DB update succeed
      if (oldAvatarUrl != null &&
          oldAvatarUrl.isNotEmpty &&
          oldAvatarUrl != newAvatarUrl) {
        try {
          await profileService.deleteAvatarFile(
            oldAvatarUrl,
            userId: currentUser.id,
          );
        } catch (_) {
          // Graceful fallback: old avatar cleanup failure does not break the updated profile
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.photoUploadFailed'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    Navigator.of(context).pop(); // Close action sheet
    if (_isUploadingPhoto) return;

    final oldAvatarUrl = _currentAvatarUrl;
    if (oldAvatarUrl == null || oldAvatarUrl.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final profileService = ref.read(profileServiceProvider);

      // 1. Delete image file from Supabase Storage FIRST
      await profileService.deleteAvatarFile(
        oldAvatarUrl,
        userId: currentUser.id,
      );

      // 2. Only after storage deletion succeeds, set avatar_url = null in Supabase
      await profileService.updateAvatarUrl(
        userId: currentUser.id,
        avatarUrl: null,
      );

      // 3. Refresh local profile state
      final updatedProfile = widget.profile.copyWith(
        clearAvatarUrl: true,
      );
      ref.read(userProfileProvider.notifier).state = updatedProfile;

      if (mounted) {
        setState(() {
          _currentAvatarUrl = null;
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.photoRemoved'.tr()),
            backgroundColor: const Color(0xFF1B2A18),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.photoUploadFailed'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showPhotoActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final hasPhoto =
        _currentAvatarUrl != null && _currentAvatarUrl!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: divider, width: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'profile.changeProfilePhoto'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 18),

              // Choose from Gallery
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : const Color(0xFFF3F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: textPrimary,
                  ),
                ),
                title: Text(
                  'profile.chooseFromGallery'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                onTap: () => _pickAndUploadImage(ImageSource.gallery),
              ),

              // Take Photo (Camera)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : const Color(0xFFF3F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 20,
                    color: textPrimary,
                  ),
                ),
                title: Text(
                  'profile.takePhoto'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                onTap: () => _pickAndUploadImage(ImageSource.camera),
              ),

              // Remove Photo (if photo exists)
              if (hasPhoto)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.danger,
                    ),
                  ),
                  title: Text(
                    'profile.removePhoto'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  onTap: _removePhoto,
                ),

              const SizedBox(height: 8),

              // Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    'profile.cancel'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final size = MediaQuery.sizeOf(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: divider, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'profile.editProfile'.tr(),
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Interactive Profile Photo Section ──
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : () => _showPhotoActionSheet(context),
                              child: CaloraAvatar(
                                avatarUrl: _currentAvatarUrl,
                                displayName: _nameCtrl.text.trim().isNotEmpty
                                    ? _nameCtrl.text.trim()
                                    : widget.profile.name,
                                size: 84,
                                isDark: isDark,
                                isUploading: _isUploadingPhoto,
                              ),
                            ),
                            if (!_isUploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showPhotoActionSheet(context),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceAlt
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: divider,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.35 : 0.08,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.accent
                                          : const Color(0xFF2E6319),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isUploadingPhoto
                              ? null
                              : () => _showPhotoActionSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              _isUploadingPhoto
                                  ? 'profile.uploadingPhoto'.tr()
                                  : 'profile.changeProfilePhoto'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isUploadingPhoto
                                    ? textSecondary
                                    : (isDark
                                        ? AppColors.accent
                                        : const Color(0xFF2E6319)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Full Name
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'auth.fullName'.tr(),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Height & Weight
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'profile.heightCmLabel'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'profile.weightKgLabel'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Goal Dropdown
                  DropdownButtonFormField<Goal>(
                    initialValue: _selectedGoal,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'profile.goal'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: Goal.loseWeight,
                        child: Text('dashboard.goals.loseWeight'.tr()),
                      ),
                      DropdownMenuItem(
                        value: Goal.maintainWeight,
                        child: Text('dashboard.goals.maintainWeight'.tr()),
                      ),
                      DropdownMenuItem(
                        value: Goal.gainWeight,
                        child: Text('dashboard.goals.gainWeight'.tr()),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedGoal = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Target Weight & Goal Pace
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetWeightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'profile.targetWeightKgLabel'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<GoalPace>(
                          initialValue: _selectedGoalPace,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          dropdownColor:
                              isDark ? AppColors.darkSurface : Colors.white,
                          decoration: InputDecoration(
                            labelText: 'profile.goalPaceLabel'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: GoalPace.gentle,
                              child: Text('Gentle'),
                            ),
                            DropdownMenuItem(
                              value: GoalPace.moderate,
                              child: Text('Moderate'),
                            ),
                            DropdownMenuItem(
                              value: GoalPace.faster,
                              child: Text('Faster'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedGoalPace = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Target calories & macros will automatically update.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isUploadingPhoto
                  ? null
                  : () {
                      final parsedTargetWeight =
                          double.tryParse(_targetWeightCtrl.text);

                      final updatedProfile = widget.profile.copyWith(
                        name: _nameCtrl.text.trim().isNotEmpty
                            ? _nameCtrl.text.trim()
                            : widget.profile.name,
                        avatarUrl: _currentAvatarUrl,
                        clearAvatarUrl: _currentAvatarUrl == null,
                        heightCm: double.tryParse(_heightCtrl.text) ??
                            widget.profile.heightCm,
                        weightKg: double.tryParse(_weightCtrl.text) ??
                            widget.profile.weightKg,
                        targetWeightKg: parsedTargetWeight,
                        goal: _selectedGoal,
                        goalPace: _selectedGoalPace,
                      );

                      ref.read(userProfileProvider.notifier).state =
                          updatedProfile;

                      final currentUser = ref.read(currentUserProvider);
                      if (currentUser != null) {
                        ref.read(profileServiceProvider).saveProfile(
                              userId: currentUser.id,
                              profile: updatedProfile,
                            );
                      }

                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0F1410),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'profile.save'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F1410),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
