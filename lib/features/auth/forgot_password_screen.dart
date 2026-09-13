import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();

  String? _emailError;
  bool _loading = false;
  bool _submitted = false;
  String _submittedEmail = '';

  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&'
    r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  bool _validate() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'auth.emailRequired'.tr());
      return false;
    }
    if (!_emailRegExp.hasMatch(email)) {
      setState(() => _emailError = 'auth.invalidEmail'.tr());
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final email = _emailController.text.trim();
    setState(() => _loading = true);

    // Simulated async password-reset network call
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _submitted = true;
      _submittedEmail = email;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _submitted
                  ? _buildSuccessState(context, isDark)
                  : _buildFormState(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. FORM INPUT STATE ──────────────────────────────────────────────────

  Widget _buildFormState(BuildContext context, bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final hasError = _emailError != null && _emailError!.isNotEmpty;

    return KeyedSubtree(
      key: const ValueKey('FormState'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Header Icon Badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.accentSoft.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 28,
                color: isDark ? AppColors.accent : const Color(0xFF65A30D),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Headline
          Text(
            'auth.forgotPasswordTitle'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            'auth.forgotPasswordSubtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Email Input Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailController,
                focusNode: _focusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  hintText: 'auth.email'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.danger : borderColor,
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.danger : borderColor,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.danger : AppColors.accent,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    _emailError!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Primary CTA: Send reset link
          AppButton(
            label: 'auth.sendResetLink'.tr(),
            onPressed: _loading ? null : _submit,
            loading: _loading,
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Secondary Action: Back to login
          AppButton(
            label: 'auth.backToLogin'.tr(),
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.secondary,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ── 2. SUCCESS STATE ─────────────────────────────────────────────────────

  Widget _buildSuccessState(BuildContext context, bool isDark) {
    return KeyedSubtree(
      key: const ValueKey('SuccessState'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Header Icon Badge — Success Mail
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.accentSoft.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 28,
                color: isDark ? AppColors.accent : const Color(0xFF65A30D),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Headline: Check your email
          Text(
            'auth.checkYourEmail'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle with target email
          Text(
            'auth.resetEmailSent'.tr(args: [_submittedEmail]),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Primary Action: Back to login
          AppButton(
            label: 'auth.backToLogin'.tr(),
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Secondary Action: Resend email
          Center(
            child: TextButton(
              onPressed: () {
                setState(() => _submitted = false);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                'auth.resendEmail'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : const Color(0xFF65A30D),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
