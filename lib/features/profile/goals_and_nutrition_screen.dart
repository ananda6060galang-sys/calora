import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/input_validators.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import 'providers/weight_log_provider.dart';
import 'widgets/weight_journey_chart.dart';

/// CALORA — GOALS & NUTRITION SCREEN (COMPLETE REDESIGN)
///
/// Follows Calora's "Help the user make a decision, not show a database form" principle:
/// 1. Primary Goal Selection: Lose, Maintain, Gain (Card selector with clear active state)
/// 2. Target Weight: Clear Current vs Target comparison (for Lose/Gain)
/// 3. Goal Pace: Gentle, Moderate (Recommended), Faster with simple human descriptions
/// 4. Calculated Target & Transparency: Clear Calora calculation with BMR safety clamping
/// 5. Supporting Macros: Non-dominant Protein, Carbs, Fat breakdown consistent with Food Diary
/// 6. Primary Action: Sticky bottom "Save Plan" persisting directly to Riverpod & Supabase
class GoalsAndNutritionScreen extends ConsumerStatefulWidget {
  const GoalsAndNutritionScreen({super.key});

  @override
  ConsumerState<GoalsAndNutritionScreen> createState() =>
      _GoalsAndNutritionScreenState();
}

class _GoalsAndNutritionScreenState
    extends ConsumerState<GoalsAndNutritionScreen> {
  late Goal _goal;
  late GoalPace _pace;
  late double _targetWeight;
  late final TextEditingController _customCalorieCtrl;
  bool _isCustomCalorie = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _goal = profile.goal;
    _pace = profile.goalPace;
    _targetWeight = profile.targetWeightKg ?? profile.weightKg;
    _isCustomCalorie = profile.isCustomTarget;
    _customCalorieCtrl = TextEditingController(
      text: profile.customCalorieTarget != null
          ? profile.customCalorieTarget!.round().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _customCalorieCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(num val) {
    return val.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _savePlan(UserProfile currentProfile) async {
    final customVal = double.tryParse(_customCalorieCtrl.text.trim());

    // Validation: if custom calorie enabled, verify >= BMR
    if (_isCustomCalorie && (customVal == null || customVal < currentProfile.bmr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target kalori minimal adalah BMR (${currentProfile.bmr.round()} kcal) demi keamanan metabolisme.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedProfile = currentProfile.copyWith(
      goal: _goal,
      goalPace: _pace,
      targetWeightKg: _goal == Goal.maintainWeight ? currentProfile.weightKg : _targetWeight,
      customCalorieTarget: _isCustomCalorie ? customVal : null,
      clearCustomCalorieTarget: !_isCustomCalorie,
    );

    ref.read(userProfileProvider.notifier).state = updatedProfile;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        await ref.read(profileServiceProvider).saveProfile(
              userId: currentUser.id,
              profile: updatedProfile,
            );
      } catch (_) {
        // Fallback: local state already saved
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Target & rencana nutrisi berhasil diperbarui!'),
        backgroundColor: const Color(0xFF1B2A18),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final weightLogs = ref.watch(weightLogProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Temporary reactive profile to calculate live preview values
    final customVal = double.tryParse(_customCalorieCtrl.text.trim());
    final previewProfile = profile.copyWith(
      goal: _goal,
      goalPace: _pace,
      targetWeightKg: _goal == Goal.maintainWeight ? profile.weightKg : _targetWeight,
      customCalorieTarget: _isCustomCalorie ? customVal : null,
      clearCustomCalorieTarget: !_isCustomCalorie,
    );

    final plan = NutritionCalculator.calculateGoalRoadmap(previewProfile);
    final calculatedTarget = previewProfile.dailyCalorieTarget.round();
    final bmr = previewProfile.bmr.round();
    final tdee = previewProfile.tdee.round();
    final isBmrClamped = calculatedTarget <= bmr && _goal == Goal.loseWeight;

    // Macro proportions
    final pG = previewProfile.proteinTargetG.round();
    final cG = previewProfile.carbsTargetG.round();
    final fG = previewProfile.fatTargetG.round();
    final totalMacroKcal = (pG * 4) + (cG * 4) + (fG * 9);
    final pRatio = totalMacroKcal > 0 ? (pG * 4) / totalMacroKcal : 0.3;
    final cRatio = totalMacroKcal > 0 ? (cG * 4) / totalMacroKcal : 0.45;
    final fRatio = totalMacroKcal > 0 ? (fG * 9) / totalMacroKcal : 0.25;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(10),
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
        title: Text(
          'profile.goalsAndNutrition'.tr(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : const Color(0xFFE8F8D0),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accent.withValues(alpha: 0.3)
                        : const Color(0xFFC7F464),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _goalLabel(_goal),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
            children: [
              // ── 0. WEIGHT JOURNEY & HISTORICAL PROGRESS ──────────────
              _SectionTitleHeader(
                title: 'Perjalanan & Progres Berat',
                subtitle: 'Pantau perubahan berat badanmu menuju target akhir',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                trailing: TextButton.icon(
                  onPressed: () => _openLogWeightSheet(context, ref, profile),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                  label: Text(
                    'Catat Berat',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.accent : const Color(0xFF2E6319),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(44, 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Journey Overview Card (Start -> Current -> Target)
              _WeightProgressOverviewCard(
                logs: weightLogs,
                profile: previewProfile,
                targetWeight: _goal == Goal.maintainWeight ? profile.weightKg : _targetWeight,
                goal: _goal,
                plan: plan,
                isDark: isDark,
                surfaceColor: surfaceColor,
                surfaceAlt: surfaceAlt,
                dividerColor: dividerColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Embedded Apple Health-Style Weight Journey Chart
              if (weightLogs.isNotEmpty) ...[
                WeightJourneyChart(
                  logs: weightLogs,
                  profile: previewProfile,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
              ],

              // ── PLAN CONFIGURATION SECTION HEADER ────────────────────
              _SectionTitleHeader(
                title: 'Rencana & Konfigurasi Target',
                subtitle: 'Sesuaikan tujuan, target berat, dan alokasi kalori harianmu',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 16),

              // ── STEP 1: WHAT IS YOUR GOAL? ──────────────────────────
              _StepHeader(
                step: '1',
                title: 'onboarding.goalTitle'.tr(),
                subtitle: 'onboarding.goalSubtitle'.tr(),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GoalCard(
                      label: 'dashboard.goals.loseWeight'.tr(),
                      subtitle: 'Defisit kalori',
                      icon: Icons.trending_down_rounded,
                      isSelected: _goal == Goal.loseWeight,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () {
                        setState(() {
                          _goal = Goal.loseWeight;
                          if (_targetWeight >= profile.weightKg) {
                            _targetWeight = math.max(25.0, profile.weightKg - 3.0);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GoalCard(
                      label: 'dashboard.goals.maintainWeight'.tr(),
                      subtitle: 'Stabil & seimbang',
                      icon: Icons.balance_rounded,
                      isSelected: _goal == Goal.maintainWeight,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () {
                        setState(() {
                          _goal = Goal.maintainWeight;
                          _targetWeight = profile.weightKg;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GoalCard(
                      label: 'dashboard.goals.gainWeight'.tr(),
                      subtitle: 'Surplus terukur',
                      icon: Icons.trending_up_rounded,
                      isSelected: _goal == Goal.gainWeight,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () {
                        setState(() {
                          _goal = Goal.gainWeight;
                          if (_targetWeight <= profile.weightKg) {
                            _targetWeight = profile.weightKg + 3.0;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── STEP 2: TARGET WEIGHT (If Lose/Gain) ──────────────────
              if (_goal != Goal.maintainWeight) ...[
                _StepHeader(
                  step: '2',
                  title: 'Target Berat Badan',
                  subtitle: 'Tentukan berat badan akhir yang ingin kamu capai',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: dividerColor, width: 0.8),
                    boxShadow: AppShadows.card(isDark),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saat Ini',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile.weightKg.toStringAsFixed(1)} kg',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 0.8,
                            color: dividerColor,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Akhir',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_targetWeight.toStringAsFixed(1)} kg',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.accent
                                        : const Color(0xFF2E6319),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stepper Controls
                          Row(
                            children: [
                              _StepperButton(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  if (_targetWeight > 25.0) {
                                    setState(() {
                                      _targetWeight = double.parse(
                                        (_targetWeight - 0.5).toStringAsFixed(1),
                                      );
                                    });
                                  }
                                },
                                isDark: isDark,
                                surfaceAlt: surfaceAlt,
                                textPrimary: textPrimary,
                              ),
                              const SizedBox(width: 6),
                              _StepperButton(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  if (_targetWeight < 300.0) {
                                    setState(() {
                                      _targetWeight = double.parse(
                                        (_targetWeight + 0.5).toStringAsFixed(1),
                                      );
                                    });
                                  }
                                },
                                isDark: isDark,
                                surfaceAlt: surfaceAlt,
                                textPrimary: textPrimary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, thickness: 0.6, color: dividerColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selisih yang harus dicapai:',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            '${(_targetWeight - profile.weightKg).abs().toStringAsFixed(1)} kg (${_goal == Goal.loseWeight ? 'Turun' : 'Naik'})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
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
                ),
                const SizedBox(height: 28),
              ],

              // ── STEP 3: GOAL PACE ────────────────────────────────────
              _StepHeader(
                step: _goal == Goal.maintainWeight ? '2' : '3',
                title: 'onboarding.preferredPace'.tr(),
                subtitle: 'Pilih seberapa bertahap pendekatan nutrisi harianmu',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _PaceOptionCard(
                    title: 'onboarding.paces.gentle'.tr(),
                    subtitle: 'onboarding.paces.gentleSub'.tr(),
                    offsetKcal: '±250 kcal/hari',
                    isSelected: _pace == GoalPace.gentle,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    dividerColor: dividerColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () => setState(() => _pace = GoalPace.gentle),
                  ),
                  const SizedBox(height: 8),
                  _PaceOptionCard(
                    title: 'onboarding.paces.moderate'.tr(),
                    subtitle: 'onboarding.paces.moderateSub'.tr(),
                    offsetKcal: '±500 kcal/hari',
                    isRecommended: true,
                    isSelected: _pace == GoalPace.moderate,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    dividerColor: dividerColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () => setState(() => _pace = GoalPace.moderate),
                  ),
                  const SizedBox(height: 8),
                  _PaceOptionCard(
                    title: 'onboarding.paces.faster'.tr(),
                    subtitle: 'onboarding.paces.fasterSub'.tr(),
                    offsetKcal: '±750 kcal/hari',
                    isSelected: _pace == GoalPace.faster,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    dividerColor: dividerColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () => setState(() => _pace = GoalPace.faster),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── STEP 4: CALCULATED TARGET & CUSTOMIZATION ─────────────
              _StepHeader(
                step: _goal == Goal.maintainWeight ? '3' : '4',
                title: 'Target Kalori Harian',
                subtitle: 'Calora menghitung target dari BMR, TDEE, & pace yang kamu pilih',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor, width: 0.8),
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
                              Text(
                                _isCustomCalorie
                                    ? 'Target Kustom'
                                    : 'Dihitung Otomatis',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _formatNumber(calculatedTarget),
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'kcal / hari',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Safety BMR Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isBmrClamped
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : (isDark
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : const Color(0xFFE8F8D0)),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isBmrClamped
                                    ? Icons.shield_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 13,
                                color: isBmrClamped
                                    ? AppColors.warning
                                    : (isDark
                                        ? AppColors.accent
                                        : const Color(0xFF2E6319)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isBmrClamped ? 'Batas Aman BMR' : 'Optimal',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isBmrClamped
                                      ? AppColors.warning
                                      : (isDark
                                          ? AppColors.accent
                                          : const Color(0xFF2E6319)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Transparency Breakdown (BMR & TDEE)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'BMR: $bmr kcal • TDEE: $tdee kcal',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            'Mifflin-St Jeor',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(height: 1, thickness: 0.6, color: dividerColor),
                    const SizedBox(height: 12),

                    // Custom Calorie Target Toggle
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isCustomCalorie = !_isCustomCalorie;
                          if (!_isCustomCalorie) {
                            _customCalorieCtrl.clear();
                          } else if (_customCalorieCtrl.text.isEmpty) {
                            _customCalorieCtrl.text = calculatedTarget.toString();
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _isCustomCalorie
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: _isCustomCalorie
                                ? (isDark ? AppColors.accent : const Color(0xFF2E6319))
                                : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Atur target kalori manual (kustom)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isCustomCalorie) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customCalorieCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [InputValidators.integerFormatter],
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Target Kalori Manual (kcal)',
                          hintText: 'Minimal $bmr kcal (BMR)',
                          prefixIcon: const Icon(Icons.tune_rounded, size: 20),
                          suffixText: 'kcal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Target kustom tetap dibatasi minimal senilai BMR agar tidak mengganggu kesehatan hormon.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── STEP 5: SUPPORTING MACRONUTRIENTS ─────────────────────
              _StepHeader(
                step: _goal == Goal.maintainWeight ? '4' : '5',
                title: 'Distribusi Makronutrisi',
                subtitle: 'Rasio protein, karbohidrat, & lemak pendukung metabolisme',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor, width: 0.8),
                  boxShadow: AppShadows.card(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Proportional Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 7,
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
                    const SizedBox(height: 14),

                    // Three Clean Macro Chips (matching Food Diary)
                    Row(
                      children: [
                        _MacroChip(
                          label: 'dashboard.protein'.tr(),
                          value: '${pG}g',
                          pct: '${(pRatio * 100).round()}%',
                          color: AppColors.protein,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _MacroChip(
                          label: 'dashboard.carbs'.tr(),
                          value: '${cG}g',
                          pct: '${(cRatio * 100).round()}%',
                          color: AppColors.carbs,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _MacroChip(
                          label: 'dashboard.fat'.tr(),
                          value: '${fG}g',
                          pct: '${(fRatio * 100).round()}%',
                          color: AppColors.fat,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick action: Log Today's Weight
              Center(
                child: TextButton.icon(
                  onPressed: () => _openLogWeightSheet(context, ref, profile),
                  icon: const Icon(Icons.scale_outlined, size: 16),
                  label: Text(
                    'profile.logWeightToday'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.accent
                        : const Color(0xFF2E6319),
                  ),
                ),
              ),
            ],
          ),

          // ── STICKY BOTTOM SAVE ACTION ─────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _savePlan(profile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF0F1410),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F1410),
                          ),
                        )
                      : Text(
                          'Simpan Target Nutrisi',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F1410),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLogWeightSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _LogWeightSheet(
        currentWeight: profile.weightKg,
        onSave: (newWeight) {
          ref.read(weightLogProvider.notifier).addWeightLog(newWeight);
          Navigator.of(sheetCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile.weightUpdatedSuccess'.tr()),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

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
}

// ════════════════════════════════════════════════════════════════
// REUSABLE LOCAL HELPER WIDGETS
// ════════════════════════════════════════════════════════════════

class _SectionTitleHeader extends StatelessWidget {
  const _SectionTitleHeader({
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _WeightProgressOverviewCard extends StatelessWidget {
  const _WeightProgressOverviewCard({
    required this.logs,
    required this.profile,
    required this.targetWeight,
    required this.goal,
    required this.plan,
    required this.isDark,
    required this.surfaceColor,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<WeightLog> logs;
  final UserProfile profile;
  final double targetWeight;
  final Goal goal;
  final GoalRoadmapPlan plan;
  final bool isDark;
  final Color surfaceColor;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final startWeight =
        logs.isNotEmpty ? logs.first.weightKg : profile.weightKg;
    final currentWeight = profile.weightKg;
    final totalDelta = currentWeight - startWeight;
    final remainingDelta = (targetWeight - currentWeight).abs();

    // Progress percentage calculation
    double progressRatio = 1.0;
    if (goal == Goal.loseWeight) {
      final totalToLose = startWeight - targetWeight;
      if (totalToLose > 0.05) {
        progressRatio =
            ((startWeight - currentWeight) / totalToLose).clamp(0.0, 1.0);
      }
    } else if (goal == Goal.gainWeight) {
      final totalToGain = targetWeight - startWeight;
      if (totalToGain > 0.05) {
        progressRatio =
            ((currentWeight - startWeight) / totalToGain).clamp(0.0, 1.0);
      }
    }

    final String deltaText;
    if (totalDelta.abs() < 0.05) {
      deltaText = 'Stabil (0.0 kg)';
    } else if (totalDelta < 0) {
      deltaText = 'Turun ${(-totalDelta).toStringAsFixed(1)} kg sejauh ini';
    } else {
      deltaText = 'Naik ${totalDelta.toStringAsFixed(1)} kg sejauh ini';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor, width: 0.8),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of 3 stats: Start -> Current -> Target
          Row(
            children: [
              // 1. Start Weight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${startWeight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow / Divider
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: textSecondary.withValues(alpha: 0.4),
              ),

              // 2. Current Weight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Saat Ini',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${currentWeight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow / Divider
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: textSecondary.withValues(alpha: 0.4),
              ),

              // 3. Target Weight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${targetWeight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? AppColors.accent : const Color(0xFF2E6319),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (goal != Goal.maintainWeight) ...[
            const SizedBox(height: 16),

            // Progress Bar Track
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 7,
                child: Stack(
                  children: [
                    Container(color: surfaceAlt),
                    FractionallySizedBox(
                      widthFactor: progressRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.accent
                              : const Color(0xFF2E6319),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Summary Subtitle Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  deltaText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                  ),
                ),
                Text(
                  plan.isMaintenance
                      ? 'Target tercapai'
                      : 'Sisa ${remainingDelta.toStringAsFixed(1)} kg • ~${plan.estimatedWeeks} mg',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  final String step;
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : const Color(0xFFE8F8D0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                step,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.accent : const Color(0xFF2E6319),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.accent : const Color(0xFF2E6319);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : dividerColor,
              width: isSelected ? 1.5 : 0.8,
            ),
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.08 : 0.05)
                : surfaceColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? activeColor : textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaceOptionCard extends StatelessWidget {
  const _PaceOptionCard({
    required this.title,
    required this.subtitle,
    required this.offsetKcal,
    this.isRecommended = false,
    required this.isSelected,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String offsetKcal;
  final bool isRecommended;
  final bool isSelected;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.accent : const Color(0xFF2E6319);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : dividerColor,
              width: isSelected ? 1.5 : 0.8,
            ),
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.08 : 0.05)
                : surfaceColor,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? activeColor : textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.accent.withValues(alpha: 0.18)
                                  : const Color(0xFFE8F8D0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'onboarding.paces.recommendedBadge'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.accent
                                    : const Color(0xFF2E6319),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                offsetKcal,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.surfaceAlt,
    required this.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color surfaceAlt;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: textPrimary),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
    required this.isDark,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final String pct;
  final Color color;
  final bool isDark;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
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
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  pct,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
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
}

/// Sleek bottom sheet to log today's weight measurement.
class _LogWeightSheet extends StatefulWidget {
  const _LogWeightSheet({
    required this.currentWeight,
    required this.onSave,
  });

  final double currentWeight;
  final ValueChanged<double> onSave;

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  late final TextEditingController _controller;
  double _weight = 0.0;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weight = widget.currentWeight;
    _controller = TextEditingController(text: _weight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjustWeight(double delta) {
    final next = (_weight + delta).clamp(25.0, 300.0);
    setState(() {
      _weight = double.parse(next.toStringAsFixed(1));
      _controller.text = _weight.toStringAsFixed(1);
      _errorText = null;
    });
  }

  void _onTextChanged(String val) {
    final err = InputValidators.validateWeight(val);
    setState(() {
      _errorText = err;
      final parsed = double.tryParse(val);
      if (parsed != null && err == null) {
        _weight = parsed;
      }
    });
  }

  void _submit() {
    final err = InputValidators.validateWeight(_controller.text);
    if (err != null) {
      setState(() => _errorText = err);
      return;
    }
    widget.onSave(_weight);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final diff = _weight - widget.currentWeight;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'profile.updateWeightTitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'profile.updateWeightSubtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 24),

          // Stepper & Input Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => _adjustWeight(-0.1),
                icon: const Icon(Icons.remove_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: surfaceAlt,
                  foregroundColor: textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 14),

              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorText != null
                        ? Colors.red
                        : divider.withValues(alpha: 0.6),
                    width: _errorText != null ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [InputValidators.decimalFormatter],
                        onChanged: _onTextChanged,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kg',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              IconButton.filledTonal(
                onPressed: () => _adjustWeight(0.1),
                icon: const Icon(Icons.add_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: surfaceAlt,
                  foregroundColor: textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: diff == 0
                  ? surfaceAlt
                  : (diff < 0
                      ? (isDark
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : const Color(0xFF85C500).withValues(alpha: 0.12))
                      : Colors.orange.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              diff == 0
                  ? 'Sama dengan timbangan sebelumnya'
                  : (diff < 0
                      ? 'Turun ${(-diff).toStringAsFixed(1)} kg dari sebelumnya'
                      : 'Naik ${diff.toStringAsFixed(1)} kg dari sebelumnya'),
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: diff == 0
                    ? textSecondary
                    : (diff < 0
                        ? (isDark ? AppColors.accent : const Color(0xFF5B8A00))
                        : Colors.orange),
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent
                    : const Color(0xFF17382B),
                foregroundColor:
                    isDark ? const Color(0xFF0F1410) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'profile.saveWeight'.tr(),
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
