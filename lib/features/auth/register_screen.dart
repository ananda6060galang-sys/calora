import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_toggle_pill.dart';
import '../onboarding/onboarding_screen.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _loading = false;

  // =========================================================
  // REGISTER
  // =========================================================
  void _register() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    String? nameErr;
    if (name.isEmpty) {
      nameErr = 'auth.nameRequired'.tr();
    }

    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'auth.emailRequired'.tr();
    } else if (!emailRegExp.hasMatch(email)) {
      emailErr = 'auth.invalidEmail'.tr();
    }

    String? passwordErr;
    if (password.isEmpty) {
      passwordErr = 'auth.passwordRequired'.tr();
    } else if (password.length < 6) {
      passwordErr = 'auth.passwordTooShort'.tr();
    }

    String? confirmErr;
    if (confirm.isEmpty) {
      confirmErr = 'auth.passwordRequired'.tr();
    } else if (confirm != password) {
      confirmErr = 'auth.passwordsDoNotMatch'.tr();
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passwordErr;
      _confirmError = confirmErr;
    });

    if (nameErr != null) {
      _nameFocus.requestFocus();
      return;
    }
    if (emailErr != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordErr != null) {
      _passwordFocus.requestFocus();
      return;
    }
    if (confirmErr != null) {
      _confirmFocus.requestFocus();
      return;
    }

    // Prevent duplicate submissions
    setState(() => _loading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      if (!mounted) return;

      setState(() => _loading = false);

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.registrationSuccessful'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already in use') ||
          msg.contains('user already exists')) {
        setState(() {
          _emailError = 'auth.emailAlreadyInUse'.tr();
        });
        _emailFocus.requestFocus();
      } else if (msg.contains('least 6') ||
          msg.contains('password should be at least')) {
        setState(() {
          _passwordError = 'auth.passwordTooShort'.tr();
        });
        _passwordFocus.requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // =========================================================
  // BACK TO LOGIN
  // =========================================================
  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // =========================================================
    // MANUAL POSITION
    // SAMA SEPERTI LOGIN
    // =========================================================
    //
    // Angka lebih kecil = form makin NAIK
    // Angka lebih besar = form makin TURUN
    //
    // 200 = naik
    // 219 = posisi sekarang
    // 235 = turun
    // =========================================================
    const double formTopPosition = 219.0;

    // Tinggi banner dibuat sama dengan Login
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
            // 1. BANNER
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
            // 2. SCROLLABLE FORM
            // =====================================================
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  // =================================================
                  // MANUAL FORM POSITION
                  // =================================================
                  const SizedBox(height: formTopPosition),

                  // =================================================
                  // FORM CONTAINER
                  // =================================================
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
                      20 + MediaQuery.of(context).viewInsets.bottom,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        // =================================================
                        // TITLE
                        // =================================================
                        Text(
                          'auth.createAccount'.tr(),

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

                        const SizedBox(height: 20),

                        // =================================================
                        // SUBTITLE
                        // =================================================
                        Text(
                          'auth.registerSubtitle'.tr(),

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,

                            color: isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF76655C),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // =================================================
                        // FULL NAME
                        // =================================================
                        _AuthField(
                          hint: 'auth.fullName'.tr(),
                          isDark: isDark,
                          controller: _name,
                          focusNode: _nameFocus,
                          errorText: _nameError,
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                          prefixIcon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 12),

                        // =================================================
                        // EMAIL
                        // =================================================
                        _AuthField(
                          hint: 'auth.email'.tr(),
                          isDark: isDark,
                          controller: _email,
                          focusNode: _emailFocus,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                        ),

                        const SizedBox(height: 12),

                        // =================================================
                        // PASSWORD
                        // =================================================
                        _AuthField(
                          hint: 'auth.password'.tr(),
                          isDark: isDark,
                          controller: _password,
                          focusNode: _passwordFocus,
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                        ),

                        const SizedBox(height: 12),

                        // =================================================
                        // CONFIRM PASSWORD
                        // =================================================
                        _AuthField(
                          hint: 'auth.confirmPassword'.tr(),
                          isDark: isDark,
                          controller: _confirm,
                          focusNode: _confirmFocus,
                          errorText: _confirmError,
                          onChanged: (_) {
                            if (_confirmError != null) {
                              setState(() => _confirmError = null);
                            }
                          },
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                        ),

                        const SizedBox(height: 20),

                        // =================================================
                        // CREATE ACCOUNT BUTTON
                        // =================================================
                        SizedBox(
                          height: 52,

                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB8FF3B),

                              foregroundColor: const Color(0xFF1E1E1E),

                              disabledBackgroundColor: const Color(0xFFB8FF3B),

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
                                    'auth.createAccountButton'.tr(),

                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =================================================
                        // DIVIDER
                        // =================================================
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE5E7EB),
                                thickness: 1,
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),

                              child: Text(
                                'auth.or'.tr(),

                                style: TextStyle(
                                  fontSize: 13,

                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),

                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE5E7EB),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // =================================================
                        // GOOGLE BUTTON
                        // =================================================
                        SizedBox(
                          height: 52,

                          child: OutlinedButton(
                            onPressed: () {},

                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,

                              elevation: 0,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),

                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE0E0E0),
                                width: 1.2,
                              ),
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                // Google logo
                                // dari icons_plus
                                Brand(Brands.google, size: 21),

                                const SizedBox(width: 12),

                                Text(
                                  'auth.continueWithGoogle'.tr(),

                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,

                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =================================================
                        // FOOTER
                        // =================================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Text(
                              'auth.alreadyHaveAccount'.tr(),

                              style: TextStyle(
                                fontSize: 14,

                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF76655C),
                              ),
                            ),

                            const SizedBox(width: 4),

                            GestureDetector(
                              onTap: _goBack,

                              child: Text(
                                'auth.logIn'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF85C500),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // 3. BACK BUTTON
            // =====================================================
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,

              left: 16,

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: _goBack,

                  borderRadius: BorderRadius.circular(50),

                  child: Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),

                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),
              ),
            ),

            // =====================================================
            // 4. LANGUAGE TOGGLE (ENG / ID)
            // =====================================================
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
}

// =============================================================
// AUTH FIELD
// =============================================================

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.hint,
    required this.isDark,
    this.controller,
    this.focusNode,
    this.errorText,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
  });

  final String hint;
  final bool isDark;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : const Color(0xFFD1D5DB);

    final errorColor = Colors.red;

    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: borderColor,
        width: 1.2,
      ),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: errorColor,
        width: 1.4,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,

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

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),

              borderSide: BorderSide(
                color: hasError ? errorColor : const Color(0xFF85C500),
                width: 1.6,
              ),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),

            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: hasError
                        ? errorColor
                        : (widget.isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF6B7280)),
                  )
                : null,

            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      size: 20,

                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF6B7280),
                    ),

                    onPressed: () {
                      setState(() => _obscure = !_obscure);
                    },
                  )
                : null,
          ),
        ),

        if (hasError) ...[
          const SizedBox(height: 5),

          Padding(
            padding: const EdgeInsets.only(left: 12),

            child: Text(
              widget.errorText!,

              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: errorColor,
                height: 1.15,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
