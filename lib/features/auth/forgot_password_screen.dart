import 'dart:async';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_toggle_pill.dart';
import 'providers/auth_provider.dart';

enum _RecoveryStep { email, otp, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _RecoveryStep _currentStep = _RecoveryStep.email;

  // Step 1: Email controller
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  String? _emailError;

  // Step 2: 6-digit OTP controllers and focus nodes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  String? _otpError;

  // Step 3: New password controllers
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _loading = false;
  bool _loadingResend = false;
  String _submittedEmail = '';

  Timer? _cooldownTimer;
  int _resendCooldown = 0;

  static final _emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _email.dispose();
    _emailFocus.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPassword.dispose();
    _confirmPassword.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ===========================================================
  // STEP 1: Send OTP to Email
  // ===========================================================
  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'auth.emailRequired'.tr());
      _emailFocus.requestFocus();
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      setState(() => _emailError = 'auth.invalidEmail'.tr());
      _emailFocus.requestFocus();
      return;
    }

    setState(() {
      _emailError = null;
      _loading = true;
    });

    try {
      await ref
          .read(authServiceProvider)
          .resetPasswordForEmail(email: email);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _submittedEmail = email;
        _currentStep = _RecoveryStep.otp;
        _otpError = null;
      });
      _startCooldown(60);
      // Auto-focus first OTP field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } on AuthException catch (_) {
      // Security best practice: neutral success transition to prevent email enumeration
      if (!mounted) return;
      setState(() {
        _loading = false;
        _submittedEmail = email;
        _currentStep = _RecoveryStep.otp;
        _otpError = null;
      });
      _startCooldown(60);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===========================================================
  // STEP 2: Verify 6-digit OTP
  // ===========================================================
  String get _enteredOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    final otp = _enteredOtp;

    if (otp.length < 6) {
      setState(() => _otpError = 'auth.otpMustBe6Digits'.tr());
      return;
    }

    setState(() {
      _otpError = null;
      _loading = true;
    });

    try {
      await ref.read(authServiceProvider).verifyRecoveryOtp(
            email: _submittedEmail,
            token: otp,
          );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _currentStep = _RecoveryStep.newPassword;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _newPasswordFocus.requestFocus();
        }
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid') || msg.contains('expired') || msg.contains('token')) {
          _otpError = 'auth.invalidOtp'.tr();
        } else {
          _otpError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpError = 'auth.invalidOtp'.tr();
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _loadingResend || _submittedEmail.isEmpty) return;

    setState(() => _loadingResend = true);

    try {
      await ref
          .read(authServiceProvider)
          .resetPasswordForEmail(email: _submittedEmail);

      if (!mounted) return;
      setState(() => _loadingResend = false);
      _startCooldown(60);

      // Clear current OTP inputs
      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() => _otpError = null);
      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes[0].requestFocus();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.codeResent'.tr()),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingResend = false);
      _startCooldown(60);
    }
  }

  // ===========================================================
  // STEP 3: Update to New Password
  // ===========================================================
  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    final newPass = _newPassword.text;
    final confirmPass = _confirmPassword.text;

    String? newErr;
    String? confirmErr;

    if (newPass.isEmpty) {
      newErr = 'auth.passwordRequired'.tr();
    } else if (newPass.length < 6) {
      newErr = 'auth.passwordTooShort'.tr();
    }

    if (confirmPass.isEmpty) {
      confirmErr = 'auth.passwordRequired'.tr();
    } else if (newPass != confirmPass) {
      confirmErr = 'auth.passwordsDoNotMatch'.tr();
    }

    setState(() {
      _newPasswordError = newErr;
      _confirmPasswordError = confirmErr;
    });

    if (newErr != null) {
      _newPasswordFocus.requestFocus();
      return;
    }
    if (confirmErr != null) {
      _confirmPasswordFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(authServiceProvider).updatePassword(
            newPassword: newPass,
          );

      // Sign out to ensure clean re-login state
      await ref.read(authServiceProvider).signOut();

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.passwordResetSuccess'.tr()),
          backgroundColor: const Color(0xFF3DDC84),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Return to Login
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Visual geometry matching Calora Login & Register
    const double formTopPosition = 219.0;
    const double heroPanelHeight = 280.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        body: Stack(
          children: [
            // =====================================================
            // 1. BANNER (Matches Calora Login Hero)
            // =====================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroPanelHeight,
              child: Container(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF0F391),
                child: Image.asset(
                  'assets/banner.webp',
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? AppColors.darkSurface
                          : const Color(0xFFF0F391),
                    );
                  },
                ),
              ),
            ),

            // =====================================================
            // 2. FORM CONTAINER
            // =====================================================
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: formTopPosition),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(60),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.06,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                      27,
                      46,
                      27,
                      32 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _buildCurrentStep(context, isDark),
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // 3. TOP NAVIGATION (Back Button + Language Toggle)
            // =====================================================
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: IconButton(
                onPressed: () {
                  if (_currentStep == _RecoveryStep.otp) {
                    setState(() => _currentStep = _RecoveryStep.email);
                  } else if (_currentStep == _RecoveryStep.newPassword) {
                    setState(() => _currentStep = _RecoveryStep.otp);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: const LanguageTogglePill(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, bool isDark) {
    switch (_currentStep) {
      case _RecoveryStep.email:
        return _buildEmailStep(context, isDark);
      case _RecoveryStep.otp:
        return _buildOtpStep(context, isDark);
      case _RecoveryStep.newPassword:
        return _buildNewPasswordStep(context, isDark);
    }
  }

  // ===========================================================
  // STEP 1 UI: Email Input
  // ===========================================================
  Widget _buildEmailStep(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('step_email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.forgotPasswordTitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.15,
            color: isDark
                ? AppColors.darkTextPrimary
                : const Color(0xFF1E1E1E),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'auth.forgotPasswordSubtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF76655C),
          ),
        ),

        const SizedBox(height: 32),

        _AuthField(
          hint: 'auth.email'.tr(),
          isDark: isDark,
          controller: _email,
          focusNode: _emailFocus,
          isError: _emailError != null,
          errorText: _emailError,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          onChanged: (_) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),

        const SizedBox(height: 32),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8FF3B),
              foregroundColor: const Color(0xFF1E1E1E),
              disabledBackgroundColor:
                  const Color(0xFFB8FF3B).withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1E1E1E),
                    ),
                  )
                : Text(
                    'auth.sendOtpCode'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 26),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'auth.alreadyHaveAccount'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF76655C),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'auth.backToLogin'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF85C500),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  // ===========================================================
  // STEP 2 UI: 6-Digit OTP Verification
  // ===========================================================
  Widget _buildOtpStep(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('step_otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.enterOtpTitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.15,
            color: isDark
                ? AppColors.darkTextPrimary
                : const Color(0xFF1E1E1E),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'auth.enterOtpSubtitle'.tr(args: [_submittedEmail]),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF76655C),
          ),
        ),

        const SizedBox(height: 32),

        // 6-digit OTP input row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final hasError = _otpError != null && _otpError!.isNotEmpty;
            return SizedBox(
              width: 44,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasError
                          ? Colors.red
                          : (isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFD1D5DB)),
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasError
                          ? Colors.red
                          : (isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFD1D5DB)),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : const Color(0xFF85C500),
                      width: 1.6,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (_otpError != null) {
                    setState(() => _otpError = null);
                  }
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      if (_enteredOtp.length == 6) {
                        _verifyOtp();
                      }
                    }
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),

        if (_otpError != null && _otpError!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _otpError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Resend code row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loadingResend)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF85C500),
                ),
              )
            else if (_resendCooldown > 0)
              Text(
                '${'auth.resendCode'.tr()} (${_resendCooldown}s)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : const Color(0xFF9CA3AF),
                ),
              )
            else
              GestureDetector(
                onTap: _resendOtp,
                child: Text(
                  'auth.resendCode'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF85C500),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 28),

        // Verify Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8FF3B),
              foregroundColor: const Color(0xFF1E1E1E),
              disabledBackgroundColor:
                  const Color(0xFFB8FF3B).withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1E1E1E),
                    ),
                  )
                : Text(
                    'auth.verifyCode'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Change Email option
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _currentStep = _RecoveryStep.email;
                _otpError = null;
              });
            },
            child: Text(
              'auth.changeEmail'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF76655C),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  // ===========================================================
  // STEP 3 UI: Create New Password
  // ===========================================================
  Widget _buildNewPasswordStep(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('step_new_password'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.newPasswordTitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.15,
            color: isDark
                ? AppColors.darkTextPrimary
                : const Color(0xFF1E1E1E),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'auth.newPasswordSubtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF76655C),
          ),
        ),

        const SizedBox(height: 32),

        _AuthField(
          hint: 'auth.newPassword'.tr(),
          isDark: isDark,
          controller: _newPassword,
          focusNode: _newPasswordFocus,
          isError: _newPasswordError != null,
          errorText: _newPasswordError,
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
          onChanged: (_) {
            if (_newPasswordError != null) {
              setState(() => _newPasswordError = null);
            }
          },
        ),

        const SizedBox(height: 16),

        _AuthField(
          hint: 'auth.confirmNewPassword'.tr(),
          isDark: isDark,
          controller: _confirmPassword,
          focusNode: _confirmPasswordFocus,
          isError: _confirmPasswordError != null,
          errorText: _confirmPasswordError,
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _updatePassword(),
          onChanged: (_) {
            if (_confirmPasswordError != null) {
              setState(() => _confirmPasswordError = null);
            }
          },
        ),

        const SizedBox(height: 32),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8FF3B),
              foregroundColor: const Color(0xFF1E1E1E),
              disabledBackgroundColor:
                  const Color(0xFFB8FF3B).withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1E1E1E),
                    ),
                  )
                : Text(
                    'auth.updatePassword'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}

// =============================================================
// REUSABLE AUTH FIELD (Identical to Calora Login & Register)
// =============================================================
class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.hint,
    required this.isDark,
    this.controller,
    this.focusNode,
    this.errorText,
    this.isError = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.obscureText = false,
  });

  final String hint;
  final bool isDark;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? errorText;
  final bool isError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final bool obscureText;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final hasError =
        (widget.errorText != null && widget.errorText!.isNotEmpty) ||
            widget.isError;
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : const Color(0xFFD1D5DB);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor, width: 1.2),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.red, width: 1.4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscure,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: widget.isDark ? Colors.white : const Color(0xFF1E1E1E),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.isDark ? AppColors.darkSurface : Colors.white,
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: widget.isDark
                  ? AppColors.darkTextTertiary
                  : const Color(0xFF9CA3AF),
            ),
            border: hasError ? errorBorder : border,
            enabledBorder: hasError ? errorBorder : border,
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.6),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF85C500), width: 1.6),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF6B7280),
                    size: 20,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: widget.isDark
                          ? AppColors.darkTextTertiary
                          : const Color(0xFF9CA3AF),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
        if (hasError && widget.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
