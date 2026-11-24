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
import '../../core/widgets/language_toggle_pill.dart';
import '../../core/utils/input_validators.dart';
import '../../models/food_request.dart';
import '../../models/user_profile.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import '../diary/food_request_screen.dart';
import '../diary/my_food_submissions_screen.dart';
import '../diary/providers/food_request_provider.dart';
import '../premium/premium_paywall_screen.dart';
import 'privacy_security_screen.dart';
import 'goals_and_nutrition_screen.dart';
import 'personal_information_screen.dart';
import 'providers/weight_log_provider.dart';
import 'settings_screen.dart';
import 'widgets/weight_journey_chart.dart';

/// Redesigned Calora Profile Screen.
///
/// Faithfully reproduces the Figma reference image design with the `profile-banner`
/// illustration asset, overlapping circular avatar, edit pencil badge, user metadata,
/// edit profile pill button, and grouped Personal section card, finished with a matching
/// Account & Preferences continuation section.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final foodRequests = ref.watch(foodRequestProvider);
    final weightLogs = ref.watch(weightLogProvider);
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
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      if (profile.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF98E500),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF98E500).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 12,
                                color: Color(0xFF141713),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'PRO',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF141713),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

                  // ── Calora Pro Upgrade Banner (if not premium) ───────
                  if (!profile.isPremium) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => PremiumPaywallScreen.show(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF182010), Color(0xFF2A3A1B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF98E500).withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF98E500),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFF141713),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Calora Pro',
                                          style: GoogleFonts.inter(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF98E500).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '7 Hari Gratis',
                                            style: GoogleFonts.inter(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF98E500),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Akses AI Scanner & analitik nutrisi tanpa batas',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFFC7DE98),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF98E500),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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

            // ── 4. WEIGHT PROGRESS CHART ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: WeightJourneyChart(
                logs: weightLogs,
                profile: profile,
                isDark: isDark,
                onTap: () => _openGoalsAndNutrition(context, profile),
              ),
            ),

            const SizedBox(height: 22),

            // ── 5. PERSONAL SECTION ───────────────────────────────────
            _SectionHeader(
              'profile.personal'.tr(),
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
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _openPrivacySecurity(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _StickyProfileHeader(
          scrollController: _scrollController,
          isDark: isDark,
          bgColor: bgColor,
          dividerColor: dividerColor,
          textPrimary: textPrimary,
          onSettingsTap: () => _openSettings(context),
        ),
      ),
    ],
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
    PersonalInformationScreen.openEditSheet(context, profile);
  }

  void _openPersonalInformation(BuildContext context, UserProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PersonalInformationScreen(),
      ),
    );
  }

  void _openGoalsAndNutrition(BuildContext context, UserProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GoalsAndNutritionScreen(),
      ),
    );
  }

  void _openSubmitFood(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FoodRequestScreen(),
      ),
    );
  }

  void _openFoodRequests(
    BuildContext context,
    WidgetRef ref,
    List<FoodRequest> requests,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MyFoodSubmissionsScreen(),
      ),
    );
  }

  void _openPrivacySecurity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacySecurityScreen(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// STICKY PROFILE HEADER
// ════════════════════════════════════════════════════════════════

class _StickyProfileHeader extends StatelessWidget {
  const _StickyProfileHeader({
    required this.scrollController,
    required this.isDark,
    required this.bgColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.onSettingsTap,
  });

  final ScrollController scrollController;
  final bool isDark;
  final Color bgColor;
  final Color dividerColor;
  final Color textPrimary;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final offset =
            scrollController.hasClients ? scrollController.offset : 0.0;
        final t = (offset / 60.0).clamp(0.0, 1.0);

        final barBgColor = bgColor.withValues(alpha: t * 0.98);
        final titleColor = Color.lerp(Colors.white, textPrimary, t)!;
        final bottomBorderColor = dividerColor.withValues(alpha: t);

        return Container(
          decoration: BoxDecoration(
            color: barBgColor,
            border: Border(
              bottom: BorderSide(
                color: bottomBorderColor,
                width: t > 0 ? 0.8 : 0.0,
              ),
            ),
            boxShadow: t > 0.2
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 * t : 0.06 * t,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'profile.title'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LanguageTogglePill(),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSettingsTap,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceAlt
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: isDark
                                ? Border.all(
                                    color: AppColors.darkBorder,
                                    width: 0.8,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.25 : 0.08,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.settings_outlined,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
// PROFILE NAVIGATION ROW
// ════════════════════════════════════════════════════════════════

class _ProfileNavRow extends StatelessWidget {
  const _ProfileNavRow({
    required this.icon,
    required this.title,
    this.badge,
    this.iconColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
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
  late final FocusNode _heightFocus;
  late final FocusNode _weightFocus;
  late final FocusNode _targetWeightFocus;
  late Goal _selectedGoal;
  late GoalPace _selectedGoalPace;
  String? _currentAvatarUrl;
  bool _isUploadingPhoto = false;

  String? _heightError;
  String? _weightError;
  String? _targetWeightError;

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
    _heightFocus = FocusNode();
    _weightFocus = FocusNode();
    _targetWeightFocus = FocusNode();
    _selectedGoal = widget.profile.goal;
    _selectedGoalPace = widget.profile.goalPace;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    _targetWeightFocus.dispose();
    super.dispose();
  }

  void _validateHeight([String? value]) {
    final text = value ?? _heightCtrl.text;
    final err = InputValidators.validateHeight(text);
    if (_heightError != err) {
      setState(() => _heightError = err);
    }
  }

  void _validateWeight([String? value]) {
    final text = value ?? _weightCtrl.text;
    final err = InputValidators.validateWeight(text);
    if (_weightError != err) {
      setState(() => _weightError = err);
    }
    if (_targetWeightCtrl.text.trim().isNotEmpty) {
      _validateTargetWeight();
    }
  }

  void _validateTargetWeight([String? value]) {
    final text = value ?? _targetWeightCtrl.text;
    if (_selectedGoal == Goal.maintainWeight) {
      if (_targetWeightError != null) {
        setState(() => _targetWeightError = null);
      }
      return;
    }
    final currentW = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final err = InputValidators.validateTargetWeight(
      targetWeightStr: text,
      currentWeight: currentW,
      goal: _selectedGoal,
    );
    if (_targetWeightError != err) {
      setState(() => _targetWeightError = err);
    }
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          focusNode: _heightFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [InputValidators.decimalFormatter],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'profile.heightCmLabel'.tr(),
                            errorText: _heightError,
                            errorMaxLines: 3,
                            errorStyle: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: _validateHeight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          focusNode: _weightFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [InputValidators.decimalFormatter],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'profile.weightKgLabel'.tr(),
                            errorText: _weightError,
                            errorMaxLines: 3,
                            errorStyle: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: _validateWeight,
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
                      if (v != null) {
                        setState(() => _selectedGoal = v);
                        _validateTargetWeight();
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Target Weight & Goal Pace
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetWeightCtrl,
                          focusNode: _targetWeightFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [InputValidators.decimalFormatter],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'profile.targetWeightKgLabel'.tr(),
                            errorText: _targetWeightError,
                            errorMaxLines: 3,
                            errorStyle: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: _validateTargetWeight,
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
                          items: [
                            DropdownMenuItem(
                              value: GoalPace.gentle,
                              child: Text('onboarding.paces.gentle'.tr()),
                            ),
                            DropdownMenuItem(
                              value: GoalPace.moderate,
                              child: Text('onboarding.paces.moderate'.tr()),
                            ),
                            DropdownMenuItem(
                              value: GoalPace.faster,
                              child: Text('onboarding.paces.faster'.tr()),
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
                    'profile.paceAutoUpdateNotice'.tr(),
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
                      _validateHeight();
                      _validateWeight();
                      _validateTargetWeight();

                      if (_heightError != null) {
                        _heightFocus.requestFocus();
                        return;
                      }
                      if (_weightError != null) {
                        _weightFocus.requestFocus();
                        return;
                      }
                      if (_targetWeightError != null) {
                        _targetWeightFocus.requestFocus();
                        return;
                      }

                      final parsedTargetWeight = double.tryParse(
                          _targetWeightCtrl.text.replaceAll(',', '.'));
                      final parsedHeight = double.tryParse(
                              _heightCtrl.text.replaceAll(',', '.')) ??
                          widget.profile.heightCm;
                      final parsedWeight = double.tryParse(
                              _weightCtrl.text.replaceAll(',', '.')) ??
                          widget.profile.weightKg;

                      final updatedProfile = widget.profile.copyWith(
                        name: _nameCtrl.text.trim().isNotEmpty
                            ? _nameCtrl.text.trim()
                            : widget.profile.name,
                        avatarUrl: _currentAvatarUrl,
                        clearAvatarUrl: _currentAvatarUrl == null,
                        heightCm: parsedHeight,
                        weightKg: parsedWeight,
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
