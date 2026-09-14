import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../../models/user_profile.dart';
import '../dashboard/providers/profile_provider.dart';

String _muscleGroupLabel(String mg) {
  switch (mg.toLowerCase()) {
    case 'all':
      return 'workout.muscleGroups.all'.tr();
    case 'chest':
      return 'workout.muscleGroups.chest'.tr();
    case 'back':
      return 'workout.muscleGroups.back'.tr();
    case 'legs':
      return 'workout.muscleGroups.legs'.tr();
    case 'shoulders':
      return 'workout.muscleGroups.shoulders'.tr();
    case 'arms':
      return 'workout.muscleGroups.arms'.tr();
    case 'core':
      return 'workout.muscleGroups.core'.tr();
    default:
      return mg;
  }
}

// ─── Data Models aligned strictly with Calora PRD & ERD Schemas ──────────────
// ERD Tables: workout_session, exercises, workout_sets

/// Master `exercises` table entity
class GymExercise {
  const GymExercise({
    required this.name,
    required this.muscleGroup, // PRD Groups: Chest, Back, Legs, Shoulders, Arms, Core
    required this.targetSets,
    required this.targetReps,
    required this.lastWeightKg,
    required this.icon,
    required this.color,
  });

  final String name;
  final String muscleGroup;
  final int targetSets;
  final String targetReps;
  final double lastWeightKg;
  final IconData icon;
  final Color color;
}

/// `workout_session` table entity
class GymSession {
  const GymSession({
    required this.name,
    required this.muscleGroup,
    required this.note,
    required this.durationMinutes,
    required this.totalSets,
    required this.progressPercent,
    required this.exercises,
    required this.color,
  });

  final String name;
  final String muscleGroup;
  final String note;
  final int durationMinutes;
  final int totalSets;
  final int progressPercent;
  final List<GymExercise> exercises;
  final Color color;
}

/// `workout_sets` table entity
class LoggedWorkoutSet {
  LoggedWorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  final int setNumber;
  int reps;
  double weightKg;
}

// ─── Workout Screen Widget ───────────────────────────────────────────────────

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int _selectedMuscleIndex = 0;

  // PRD Muscle Group Category Filters
  static const _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  // Gym Sessions aligned with ERD workout_session & exercises
  static const _sessions = [
    GymSession(
      name: 'Push Day (Chest & Shoulders)',
      muscleGroup: 'Chest',
      note: 'Hypertrophy & heavy bench pressing focus',
      durationMinutes: 60,
      totalSets: 10,
      progressPercent: 70,
      color: AppColors.accent,
      exercises: [
        GymExercise(
          name: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          targetSets: 4,
          targetReps: '8 - 10 reps',
          lastWeightKg: 75.0,
          icon: Icons.fitness_center_outlined,
          color: AppColors.accent,
        ),
        GymExercise(
          name: 'Incline Dumbbell Press',
          muscleGroup: 'Chest',
          targetSets: 3,
          targetReps: '10 - 12 reps',
          lastWeightKg: 26.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFFFC24B),
        ),
        GymExercise(
          name: 'Overhead Dumbbell Press',
          muscleGroup: 'Shoulders',
          targetSets: 3,
          targetReps: '10 reps',
          lastWeightKg: 20.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFFF6B57),
        ),
      ],
    ),
    GymSession(
      name: 'Pull Day (Back & Biceps)',
      muscleGroup: 'Back',
      note: 'Lat pulldowns, rows & progressive overload',
      durationMinutes: 50,
      totalSets: 10,
      progressPercent: 45,
      color: Color(0xFF7C9CFF),
      exercises: [
        GymExercise(
          name: 'Barbell Bent-Over Row',
          muscleGroup: 'Back',
          targetSets: 4,
          targetReps: '8 reps',
          lastWeightKg: 65.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFF7C9CFF),
        ),
        GymExercise(
          name: 'Lat Pulldown',
          muscleGroup: 'Back',
          targetSets: 3,
          targetReps: '10 - 12 reps',
          lastWeightKg: 55.0,
          icon: Icons.fitness_center_outlined,
          color: AppColors.accent,
        ),
        GymExercise(
          name: 'Barbell Bicep Curl',
          muscleGroup: 'Arms',
          targetSets: 3,
          targetReps: '12 reps',
          lastWeightKg: 30.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFFFC24B),
        ),
      ],
    ),
    GymSession(
      name: 'Leg Day & Glutes',
      muscleGroup: 'Legs',
      note: 'Squats, RDLs & heavy leg presses',
      durationMinutes: 70,
      totalSets: 11,
      progressPercent: 80,
      color: Color(0xFFFFC24B),
      exercises: [
        GymExercise(
          name: 'Barbell Back Squat',
          muscleGroup: 'Legs',
          targetSets: 4,
          targetReps: '8 reps',
          lastWeightKg: 90.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFFFC24B),
        ),
        GymExercise(
          name: 'Romanian Deadlift',
          muscleGroup: 'Legs',
          targetSets: 3,
          targetReps: '10 reps',
          lastWeightKg: 75.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFFF6B57),
        ),
        GymExercise(
          name: 'Leg Press Machine',
          muscleGroup: 'Legs',
          targetSets: 4,
          targetReps: '12 reps',
          lastWeightKg: 140.0,
          icon: Icons.fitness_center_outlined,
          color: AppColors.accent,
        ),
      ],
    ),
    GymSession(
      name: 'Core & Abs Blast',
      muscleGroup: 'Core',
      note: 'Abdominal strength & leg raises',
      durationMinutes: 35,
      totalSets: 6,
      progressPercent: 90,
      color: Color(0xFFFF6B57),
      exercises: [
        GymExercise(
          name: 'Hanging Leg Raise',
          muscleGroup: 'Core',
          targetSets: 3,
          targetReps: '15 reps',
          lastWeightKg: 0.0,
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFFF6B57),
        ),
        GymExercise(
          name: 'Cable Ab Crunch',
          muscleGroup: 'Core',
          targetSets: 3,
          targetReps: '15 reps',
          lastWeightKg: 35.0,
          icon: Icons.fitness_center_outlined,
          color: AppColors.accent,
        ),
      ],
    ),
  ];

  List<GymSession> get _filteredSessions {
    if (_selectedMuscleIndex == 0) return _sessions;
    final selectedGroup = _muscleGroups[_selectedMuscleIndex];
    return _sessions.where((s) {
      return s.muscleGroup.toLowerCase() == selectedGroup.toLowerCase() ||
          s.exercises.any(
            (e) => e.muscleGroup.toLowerCase() == selectedGroup.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroSession = _sessions.first;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // Soft top background gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? const Color(0xFF1C2B1E)
                        : const Color.fromARGB(255, 214, 253, 150),
                    (isDark ? AppColors.darkBg : AppColors.lightBg).withValues(
                      alpha: 0.0,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                // ── 1. Header (Unified AppHeader) ───────────────────────────
                AppHeader(
                  profile: profile,
                  isDark: isDark,
                  onSearchTap: () {
                    // Quick feedback or filter
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('workout.searchExercise'.tr()),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── 2. Hero Gym Workout Session Card ─────────────────────────
                _HeroProgressWorkoutCard(
                  session: heroSession,
                  isDark: isDark,
                  onStart: () =>
                      _openRecordGymSessionSheet(context, heroSession),
                ),
                const SizedBox(height: 24),

                // ── 3. Daily Progress Activity Bento Grid (PRD Gym Volume) ───
                _DailyProgressActivitySection(profile: profile, isDark: isDark),
                const SizedBox(height: 24),

                // ── 4. Muscle Group Workout Sessions (PRD Exercises & Sets) ──
                _SectionHeaderTitle(
                  title: 'workout.gymWorkoutSessions'.tr(),
                  action: 'dashboard.viewAll'.tr(),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // PRD Muscle Group Category Pills
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _muscleGroups.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedMuscleIndex == index;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedMuscleIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : (isDark
                                      ? AppColors.darkSurface
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                            ),
                          ),
                          child: Text(
                            _muscleGroupLabel(_muscleGroups[index]),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF0F1410)
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Gym Workout Program Cards
                ..._filteredSessions.map((sess) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutProgramCard(
                      session: sess,
                      isDark: isDark,
                      onTap: () => _openRecordGymSessionSheet(context, sess),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRecordGymSessionSheet(BuildContext context, GymSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordGymSessionSheet(session: session),
    );
  }
}


// ─── 2. Hero Progress Gym Session Card ────────────────────────────────────────

class _HeroProgressWorkoutCard extends StatelessWidget {
  const _HeroProgressWorkoutCard({
    required this.session,
    required this.isDark,
    required this.onStart,
  });

  final GymSession session;
  final bool isDark;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E241E) : const Color(0xFF181C19),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Muscle Focus Tag & Options Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'workout.muscleFocus'.tr(
                    args: [_muscleGroupLabel(session.muscleGroup)],
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),

              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Middle Row: Workout Name, Note & Progress Ring (70%)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'workout.durationMin'.tr(
                            args: ['${session.durationMinutes}'],
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.fitness_center_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'workout.exercisesAndSets'.tr(
                            args: [
                              '${session.exercises.length}',
                              '${session.totalSets}',
                            ],
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress Indicator Ring
              SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 64,
                      width: 64,
                      child: CircularProgressIndicator(
                        value: session.progressPercent / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${session.progressPercent}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bottom Action Pill Bar ("Log Workout Session")
          GestureDetector(
            onTap: onStart,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'workout.logGymSession'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F1410),
                    ),
                  ),
                  Container(
                    height: 36,
                    width: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.north_east_rounded,
                      size: 18,
                      color: Color(0xFF0F1410),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3. Daily Progress Activity Bento Grid (PRD Gym Metrics) ─────────────────

class _DailyProgressActivitySection extends StatelessWidget {
  const _DailyProgressActivitySection({
    required this.profile,
    required this.isDark,
  });

  final UserProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'workout.dailyProgressActivity'.tr(),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Main Wrapping Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Bento Card (Volume kg Arc Gauge)
              Expanded(
                flex: 5,
                child: Container(
                  height: 184,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fitness_center_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.accent
                                  : const Color(0xFF2C4A26),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'workout.volumeKg'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Semi Circle Gauge
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 60,
                              child: CustomPaint(
                                painter: _SemiCircleGaugePainter(
                                  progress: 0.72,
                                  trackColor: isDark
                                      ? AppColors.darkBorder
                                      : const Color(0xFFE5E7EB),
                                  progressColor: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '2,480',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'workout.kgLiftedToday'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Gauge Min / Target labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'workout.average'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                          Text(
                            '3500 kg',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right Bento Column (Total Sets & Body Weight)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Sets Logged Card (workout_sets count)
                    _BentoStatCard(
                      title: 'workout.setsLogged'.tr(),
                      value: '10',
                      unit: 'workout.setsUnit'.tr(),
                      icon: Icons.checklist_rounded,
                      iconBgColor: AppColors.accent,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Weight Tracker Card (profiles.weight_kg)
                    _BentoStatCard(
                      title: 'workout.bodyWeight'.tr(),
                      value: '${profile.weightKg.toStringAsFixed(1)} kg',
                      unit: '',
                      icon: Icons.monitor_weight_outlined,
                      iconBgColor: const Color(0xFF7C9CFF),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BentoStatCard extends StatelessWidget {
  const _BentoStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconBgColor,
    required this.isDark,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconBgColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconBgColor == AppColors.accent
                  ? (isDark ? AppColors.accent : const Color(0xFF2C4A26))
                  : iconBgColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    children: [
                      TextSpan(text: value),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
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

// ─── Custom Semi-Circle Arc Gauge Painter ────────────────────────────────────

class _SemiCircleGaugePainter extends CustomPainter {
  _SemiCircleGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 6;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Background Arc (Semi-circle: PI to 2 * PI)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Active Progress Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiCircleGaugePainter oldDelegate) => true;
}

// ─── 4. Workout Program Card Item ────────────────────────────────────────────

class _WorkoutProgramCard extends StatelessWidget {
  const _WorkoutProgramCard({
    required this.session,
    required this.isDark,
    required this.onTap,
  });

  final GymSession session;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Standalone image for Leg/Lower and Push/Chest sessions, clean icon for others
            SizedBox(
              height: 96,
              width: 96,
              child: () {
                final name = session.name.toLowerCase();
                final String? assetPath =
                    (name.contains('leg') || name.contains('lower'))
                    ? 'assets/Lower.png'
                    : (name.contains('push') ||
                          name.contains('chest') ||
                          name.contains('upper'))
                    ? 'assets/push.png'
                    : null;

                if (assetPath != null) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft Gen-Z Lime Accent Radial Neon Glow
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withValues(
                                alpha: isDark ? 0.38 : 0.28,
                              ),
                              AppColors.accent.withValues(alpha: 0.0),
                            ],
                            stops: const [0.25, 1.0],
                          ),
                        ),
                      ),
                      // Standalone Image standing tall
                      Image.asset(
                        assetPath,
                        height: 96,
                        width: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fitness_center_outlined,
                            size: 36,
                            color: AppColors.accent,
                          );
                        },
                      ),
                    ],
                  );
                }

                return Center(
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 26,
                      color: isDark
                          ? AppColors.accent
                          : const Color(0xFF2C4A26),
                    ),
                  ),
                );
              }(),
            ),
            const SizedBox(width: 14),

            // Middle: Session info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session name
                  Text(
                    session.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Meta info row
                  Text(
                    'workout.sessionMeta'.tr(
                      args: [
                        '${session.durationMinutes}',
                        '${session.exercises.length}',
                        '${session.totalSets}',
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: session.progressPercent / 100,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightSurfaceAlt,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              session.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${session.progressPercent}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right: Arrow button
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.lightSurfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Icon(
                Icons.north_east_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header Title Helper ─────────────────────────────────────────────

class _SectionHeaderTitle extends StatelessWidget {
  const _SectionHeaderTitle({
    required this.title,
    this.action,
    required this.isDark,
  });

  final String title;
  final String? action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
      ],
    );
  }
}

// ─── Record Gym Session Bottom Sheet (PRD workout_session & workout_sets) ────

class _RecordGymSessionSheet extends StatefulWidget {
  const _RecordGymSessionSheet({required this.session});

  final GymSession session;

  @override
  State<_RecordGymSessionSheet> createState() => _RecordGymSessionSheetState();
}

class _RecordGymSessionSheetState extends State<_RecordGymSessionSheet> {
  late Map<String, List<LoggedWorkoutSet>> _loggedSetsMap;

  @override
  void initState() {
    super.initState();
    // Initialize sets per exercise matching workout_sets ERD schema (set_number, reps, weight_kg)
    _loggedSetsMap = {
      for (var ex in widget.session.exercises)
        ex.name: List.generate(
          ex.targetSets,
          (i) => LoggedWorkoutSet(
            setNumber: i + 1,
            reps: 10,
            weightKg: ex.lastWeightKg,
          ),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Session Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.name,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'workout.focusAndNote'.tr(
                        args: [
                          _muscleGroupLabel(widget.session.muscleGroup),
                          widget.session.note,
                        ],
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // List of Exercises & Logged Sets (workout_sets ERD)
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.session.exercises.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, exIndex) {
                final ex = widget.session.exercises[exIndex];
                final sets = _loggedSetsMap[ex.name] ?? [];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fitness_center_outlined,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ex.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              _muscleGroupLabel(ex.muscleGroup),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.accent
                                    : const Color(0xFF2C4A26),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Set Logger Table Rows (set_number, weight_kg, reps)
                      ...sets.map((setObj) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceAlt
                                      : AppColors.lightSurfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'workout.setItem'.tr(
                                    args: ['${setObj.setNumber}'],
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Weight Kg Input Display
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkBg
                                        : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${setObj.weightKg} kg',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: setObj.weightKg > 2.5
                                                ? () => setState(
                                                    () =>
                                                        setObj.weightKg -= 2.5,
                                                  )
                                                : null,
                                            child: const Icon(
                                              Icons.remove_rounded,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => setState(
                                              () => setObj.weightKg += 2.5,
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Reps Display
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkBg
                                        : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'workout.repsCount'.tr(
                                          args: ['${setObj.reps}'],
                                        ),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: setObj.reps > 1
                                                ? () => setState(
                                                    () => setObj.reps -= 1,
                                                  )
                                                : null,
                                            child: const Icon(
                                              Icons.remove_rounded,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => setState(
                                              () => setObj.reps += 1,
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Save Session Log Button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('workout.sessionLoggedSuccess'.tr()),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                'Save Gym Session Log',
                style: GoogleFonts.inter(
                  fontSize: 15,
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
