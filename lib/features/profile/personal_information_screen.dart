import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/utils/input_validators.dart';
import '../../core/widgets/calora_avatar.dart';
import '../../models/user_profile.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import 'providers/weight_log_provider.dart';

/// CALORA - PERSONAL INFORMATION SCREEN
///
/// Clean overview of personal identity, biological demographics,
/// physical biometrics, and activity level. Editing is done via a
/// keyboard-safe modal bottom sheet triggered from an action card.
class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  /// Opens the edit form directly, without routing through this overview
  /// screen. Used by the profile "Edit Profile" shortcut.
  static void openEditSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPersonalDetailsSheet(profile: profile),
    );
  }

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  bool _isUploadingPhoto = false;

  String _activityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'profile.activity.sedentary'.tr();
      case ActivityLevel.light:
        return 'profile.activity.light'.tr();
      case ActivityLevel.moderate:
        return 'profile.activity.moderate'.tr();
      case ActivityLevel.active:
        return 'profile.activity.active'.tr();
      case ActivityLevel.veryActive:
        return 'profile.activity.veryActive'.tr();
    }
  }

  void _openEditSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPersonalDetailsSheet(profile: profile),
    );
  }

  // ── Photo Picker & Upload ─────────────────────────────────────

  Future<void> _pickAndUploadImage(ImageSource source) async {
    Navigator.of(context).pop();
    if (_isUploadingPhoto) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked == null) return;

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
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final profileService = ref.read(profileServiceProvider);

      final newAvatarUrl = await profileService.uploadAvatar(
        userId: currentUser.id,
        bytes: bytes,
        fileExtension: ext,
      );

      await profileService.updateAvatarUrl(
        userId: currentUser.id,
        avatarUrl: newAvatarUrl,
      );

      ref.read(userProfileProvider.notifier).state =
          ref.read(userProfileProvider).copyWith(avatarUrl: newAvatarUrl);

      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.photoUpdated'.tr()),
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

  Future<void> _removePhoto() async {
    Navigator.of(context).pop();
    final profile = ref.read(userProfileProvider);
    if (profile.avatarUrl == null) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        await ref.read(profileServiceProvider).updateAvatarUrl(
              userId: currentUser.id,
              avatarUrl: null,
            );
      } catch (_) {}
    }

    ref.read(userProfileProvider.notifier).state =
        profile.copyWith(clearAvatarUrl: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.photoRemoved'.tr()),
        backgroundColor: const Color(0xFF1B2A18),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPhotoActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final tp = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final div = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final profile = ref.read(userProfileProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: div, width: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: div,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'profile.changeProfilePhoto'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: tp,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : AppColors.lightSurfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      size: 20, color: tp),
                ),
                title: Text(
                  'profile.chooseFromGallery'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tp,
                  ),
                ),
                onTap: () => _pickAndUploadImage(ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : AppColors.lightSurfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      size: 20, color: tp),
                ),
                title: Text(
                  'profile.takePhoto'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tp,
                  ),
                ),
                onTap: () => _pickAndUploadImage(ImageSource.camera),
              ),
              if (profile.avatarUrl != null)
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.danger),
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
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
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
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : const Color(0xFF8C988F);

    final derivedAge = calculateAge(profile.dateOfBirth);

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
            'onboarding.personalInfoTitle'.tr(),
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
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 48),
        children: [
          // ── SECTION 1: PROFILE & IDENTITY HERO CARD ─────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _isUploadingPhoto
                          ? null
                          : () => _showPhotoActionSheet(context),
                      child: CaloraAvatar(
                        avatarUrl: profile.avatarUrl,
                        displayName: profile.name.isNotEmpty
                            ? profile.name
                            : 'onboarding.defaultUser'.tr(),
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
                                  color: dividerColor, width: 1.2),
                              boxShadow: AppShadows.card(isDark),
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
                const SizedBox(height: 12),

                // Name
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name
                        : 'onboarding.defaultUser'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Member/Email Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: dividerColor, width: 0.8),
                  ),
                  child: Text(
                    currentUser?.email != null &&
                            currentUser!.email!.isNotEmpty
                        ? currentUser.email!
                        : 'profile.caloraMember'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Divider(height: 1, thickness: 0.6, color: dividerColor),
                const SizedBox(height: 18),

                // 4-Point Quick Stats Row
                Row(
                  children: [
                    _QuickStat(
                      label: 'profile.gender'.tr(),
                      value: profile.gender == Gender.male
                          ? 'profile.genderMale'.tr()
                          : 'profile.genderFemale'.tr(),
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                    _StatSeparator(color: textTertiary),
                    _QuickStat(
                      label: 'profile.age'.tr(),
                      value: 'profile.yearsOld'
                          .tr(args: [derivedAge.toString()]),
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                    _StatSeparator(color: textTertiary),
                    _QuickStat(
                      label: 'profile.height'.tr(),
                      value: '${profile.heightCm.round()} cm',
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                    _StatSeparator(color: textTertiary),
                    _QuickStat(
                      label: 'profile.weight'.tr(),
                      value:
                          '${profile.weightKg.toStringAsFixed(1)} kg',
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                      valueColor: isDark
                          ? AppColors.accent
                          : const Color(0xFF2E6319),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 2: PERSONAL DETAILS ──────────────────────────
          Text(
            'profile.personalDetails'.tr(),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'profile.personalDetailsSubtitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'profile.gender'.tr(),
                  value: profile.gender == Gender.male
                      ? 'profile.genderMale'.tr()
                      : 'profile.genderFemale'.tr(),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(
                    height: 1, thickness: 0.6, color: dividerColor),
                _DetailRow(
                  icon: Icons.cake_outlined,
                  label: 'onboarding.dobTitle'.tr(),
                  value:
                      '${DateFormat('d MMMM yyyy').format(profile.dateOfBirth)} (${'profile.yearsOld'.tr(args: [derivedAge.toString()])})',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(
                    height: 1, thickness: 0.6, color: dividerColor),
                _DetailRow(
                  icon: Icons.straighten_rounded,
                  label: 'profile.height'.tr(),
                  value: '${profile.heightCm.round()} cm',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(
                    height: 1, thickness: 0.6, color: dividerColor),
                _DetailRow(
                  icon: Icons.monitor_weight_outlined,
                  label: 'profile.weight'.tr(),
                  value:
                      '${profile.weightKg.toStringAsFixed(1)} kg',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                Divider(
                    height: 1, thickness: 0.6, color: dividerColor),
                _DetailRow(
                  icon: Icons.directions_run_rounded,
                  label: 'profile.activityLevelTitle'.tr(),
                  value:
                      _activityLevelLabel(profile.activityLevel),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 3: EDIT ACTION CARD ──────────────────────────
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dividerColor, width: 0.8),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openEditSheet(context, profile),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.accent
                                  .withValues(alpha: 0.15)
                              : const Color(0xFFE8F8D0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 22,
                          color: isDark
                              ? AppColors.accent
                              : const Color(0xFF2E6319),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'profile.editPersonalInfo'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'profile.editPersonalInfoSubtitle'
                                  .tr(),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── RECALIBRATION NOTICE ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor, width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sync_rounded,
                    size: 16, color: textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'profile.metabolicRecalibrationNote'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
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

// ── QUICK STAT IN HERO CARD ─────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color textPrimary;
  final Color textTertiary;
  final Color? valueColor;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textTertiary,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSeparator extends StatelessWidget {
  final Color color;

  const _StatSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Icon(
        Icons.circle,
        size: 3,
        color: color.withValues(alpha: 0.3),
      ),
    );
  }
}

// ── DETAIL ROW ──────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceAlt
                  : AppColors.lightSurfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
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

// ── EDIT PERSONAL DETAILS BOTTOM SHEET ──────────────────────────

class _EditPersonalDetailsSheet extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _EditPersonalDetailsSheet({required this.profile});

  @override
  ConsumerState<_EditPersonalDetailsSheet> createState() =>
      _EditPersonalDetailsSheetState();
}

class _EditPersonalDetailsSheetState
    extends ConsumerState<_EditPersonalDetailsSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  late FocusNode _nameFocus;
  late FocusNode _heightFocus;
  late FocusNode _weightFocus;

  late Gender _selectedGender;
  late DateTime _selectedDob;
  late ActivityLevel _selectedActivityLevel;

  bool _isSaving = false;
  String? _nameError;
  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _heightCtrl = TextEditingController(
      text: widget.profile.heightCm > 0
          ? widget.profile.heightCm.round().toString()
          : '',
    );
    _weightCtrl = TextEditingController(
      text: widget.profile.weightKg > 0
          ? widget.profile.weightKg.toStringAsFixed(1)
          : '',
    );

    _nameFocus = FocusNode();
    _heightFocus = FocusNode();
    _weightFocus = FocusNode();

    _selectedGender = widget.profile.gender;
    _selectedDob = widget.profile.dateOfBirth;
    _selectedActivityLevel = widget.profile.activityLevel;

    _nameCtrl.addListener(() => setState(() {}));
    _heightCtrl.addListener(() => setState(() {}));
    _weightCtrl.addListener(() => setState(() {}));

    // Rebuild on focus change so fields can show an accent-colored border.
    _nameFocus.addListener(() => setState(() {}));
    _heightFocus.addListener(() => setState(() {}));
    _weightFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _nameFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  int get _derivedAge => calculateAge(_selectedDob);

  double get _parsedHeight {
    final cleaned = _heightCtrl.text.replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get _parsedWeight {
    final cleaned = _weightCtrl.text.replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _validateAll() {
    setState(() {
      if (_nameCtrl.text.trim().isEmpty) {
        _nameError = 'profile.nameRequired'.tr();
      } else {
        _nameError = null;
      }
      _heightError = InputValidators.validateHeight(_heightCtrl.text);
      _weightError = InputValidators.validateWeight(_weightCtrl.text);
    });
  }

  bool get _isValid {
    _validateAll();
    return _nameError == null &&
        _heightError == null &&
        _weightError == null &&
        _parsedHeight >= InputValidators.minHeightCm &&
        _parsedWeight >= InputValidators.minWeightKg;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100, 1, 1);
    final lastDate = DateTime(now.year - 10, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDob.isBefore(lastDate) ? _selectedDob : lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accent,
                    onPrimary: Color(0xFF0F1410),
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF1B3D22),
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                    onSurface: AppColors.lightTextPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  String _activityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'profile.activity.sedentary'.tr();
      case ActivityLevel.light:
        return 'profile.activity.light'.tr();
      case ActivityLevel.moderate:
        return 'profile.activity.moderate'.tr();
      case ActivityLevel.active:
        return 'profile.activity.active'.tr();
      case ActivityLevel.veryActive:
        return 'profile.activity.veryActive'.tr();
    }
  }

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() => _isSaving = true);
    final initialProfile = widget.profile;

    final updatedProfile = initialProfile.copyWith(
      name: _nameCtrl.text.trim(),
      gender: _selectedGender,
      dateOfBirth: _selectedDob,
      heightCm: _parsedHeight,
      weightKg: _parsedWeight,
      activityLevel: _selectedActivityLevel,
    );

    ref.read(userProfileProvider.notifier).state = updatedProfile;

    if ((_parsedWeight - initialProfile.weightKg).abs() > 0.05) {
      ref.read(weightLogProvider.notifier).addWeightLog(
            _parsedWeight,
            date: DateTime.now(),
          );
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        await ref.read(profileServiceProvider).saveProfile(
              userId: currentUser.id,
              profile: updatedProfile,
              dateOfBirth: _selectedDob,
            );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.changesSaved'.tr()),
        backgroundColor: const Color(0xFF1B2A18),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final dividerColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    // Dark-green on light keeps contrast against the bright lime, which is
    // too light to sit under text or as a hairline on white (AGENTS.md).
    final accentColor = isDark ? AppColors.accent : const Color(0xFF2E6319);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: dividerColor, width: 0.8)),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'profile.editPersonalInfo'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: textSecondary),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 0.6, color: dividerColor),

          // Form
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── GROUP 1: IDENTITY ──────────────────────────
                  _SectionLabel(
                    text: 'profile.editGroupIdentity'.tr(),
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    'onboarding.fullNameHint'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _nameError != null
                            ? AppColors.danger
                            : _nameFocus.hasFocus
                                ? accentColor
                                : dividerColor,
                        width: (_nameFocus.hasFocus && _nameError == null)
                            ? 1.5
                            : 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    child: TextField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      scrollPadding: const EdgeInsets.only(
                          bottom: 80.0, top: 20.0),
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'onboarding.fullNameHint'.tr(),
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color:
                              textSecondary.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_nameError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _nameError!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Gender
                  Text(
                    'profile.gender'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _GenderChoiceCard(
                          label: 'profile.genderMale'.tr(),
                          icon: Icons.male_rounded,
                          isSelected:
                              _selectedGender == Gender.male,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          dividerColor: dividerColor,
                          textPrimary: textPrimary,
                          onTap: () => setState(
                              () => _selectedGender = Gender.male),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GenderChoiceCard(
                          label: 'profile.genderFemale'.tr(),
                          icon: Icons.female_rounded,
                          isSelected:
                              _selectedGender == Gender.female,
                          isDark: isDark,
                          surfaceAlt: surfaceAlt,
                          dividerColor: dividerColor,
                          textPrimary: textPrimary,
                          onTap: () => setState(() =>
                              _selectedGender = Gender.female),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Date of Birth + Derived Age
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'onboarding.dobTitle'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.accent
                                  .withValues(alpha: 0.15)
                              : const Color(0xFFE8F8D0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'profile.derivedAgeLabel'
                              .tr(args: [_derivedAge.toString()]),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF2E6319),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: dividerColor, width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    DateFormat('d MMMM yyyy')
                                        .format(_selectedDob),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 22,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── GROUP 2: BODY METRICS ──────────────────────
                  _SectionLabel(
                    text: 'profile.editGroupBody'.tr(),
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),

                  // Height & Weight
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'profile.heightCmLabel'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: surfaceAlt,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: _heightError != null
                                      ? AppColors.danger
                                      : _heightFocus.hasFocus
                                          ? accentColor
                                          : dividerColor,
                                  width: (_heightFocus.hasFocus &&
                                          _heightError == null)
                                      ? 1.5
                                      : 0.8,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 2),
                              child: TextField(
                                controller: _heightCtrl,
                                focusNode: _heightFocus,
                                keyboardType: const TextInputType
                                    .numberWithOptions(
                                    decimal: true),
                                scrollPadding:
                                    const EdgeInsets.only(
                                        bottom: 80.0,
                                        top: 20.0),
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                decoration:
                                    const InputDecoration(
                                  hintText: '175',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_heightError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _heightError!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'profile.weightKgLabel'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: surfaceAlt,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: _weightError != null
                                      ? AppColors.danger
                                      : _weightFocus.hasFocus
                                          ? accentColor
                                          : dividerColor,
                                  width: (_weightFocus.hasFocus &&
                                          _weightError == null)
                                      ? 1.5
                                      : 0.8,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 2),
                              child: TextField(
                                controller: _weightCtrl,
                                focusNode: _weightFocus,
                                keyboardType: const TextInputType
                                    .numberWithOptions(
                                    decimal: true),
                                scrollPadding:
                                    const EdgeInsets.only(
                                        bottom: 80.0,
                                        top: 20.0),
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                decoration:
                                    const InputDecoration(
                                  hintText: '70.0',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_weightError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _weightError!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── GROUP 3: ACTIVITY ──────────────────────────
                  _SectionLabel(
                    text: 'profile.editGroupActivity'.tr(),
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),

                  // Activity Level
                  Text(
                    'profile.activityLevelTitle'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: dividerColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0;
                            i < ActivityLevel.values.length;
                            i++) ...[
                          _ActivityLevelTile(
                            level: ActivityLevel.values[i],
                            label: _activityLevelLabel(
                                ActivityLevel.values[i]),
                            isSelected:
                                _selectedActivityLevel ==
                                    ActivityLevel.values[i],
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => setState(() =>
                                _selectedActivityLevel =
                                    ActivityLevel.values[i]),
                          ),
                          if (i <
                              ActivityLevel.values.length - 1)
                            Divider(
                                height: 1,
                                thickness: 0.6,
                                color: dividerColor),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
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
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? const Color(0xFF0F1410)
                                      : Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'profile.saveChanges'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
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
    );
  }
}

// ── SECTION LABEL ───────────────────────────────────────────────

/// Groups the edit form into Identity / Body / Activity. The short accent
/// bar is the repeated motif that marks each group boundary (it carries
/// grouping meaning, so it is a signal, not decoration).
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color accentColor;
  final Color textSecondary;

  const _SectionLabel({
    required this.text,
    required this.accentColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textSecondary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ── GENDER CHOICE CARD ──────────────────────────────────────────

class _GenderChoiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color surfaceAlt;
  final Color dividerColor;
  final Color textPrimary;
  final VoidCallback onTap;

  const _GenderChoiceCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.surfaceAlt,
    required this.dividerColor,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.accent : const Color(0xFF2E6319);
    final activeBg = isDark
        ? AppColors.accent.withValues(alpha: 0.12)
        : const Color(0xFFE8F8D0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : dividerColor,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? activeColor : textPrimary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeColor : textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ACTIVITY LEVEL TILE ─────────────────────────────────────────

class _ActivityLevelTile extends StatelessWidget {
  final ActivityLevel level;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ActivityLevelTile({
    required this.level,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  String _multiplier(ActivityLevel lvl) {
    switch (lvl) {
      case ActivityLevel.sedentary:
        return '1.2x';
      case ActivityLevel.light:
        return '1.375x';
      case ActivityLevel.moderate:
        return '1.55x';
      case ActivityLevel.active:
        return '1.725x';
      case ActivityLevel.veryActive:
        return '1.9x';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.accent : const Color(0xFF2E6319);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : textSecondary.withValues(alpha: 0.5),
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            Text(
              _multiplier(level),
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
