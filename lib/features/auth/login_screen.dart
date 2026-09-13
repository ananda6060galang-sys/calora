import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../routing/root_shell.dart';
import '../dashboard/providers/profile_provider.dart';
import 'forgot_password_screen.dart';
import 'providers/auth_provider.dart';
import 'register_screen.dart';
import '../onboarding/onboarding_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;

  void _login() async {
    final email = _email.text.trim();
    final password = _password.text;

    // Validation: Email not empty
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.emailRequired'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: Password not empty
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.passwordRequired'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prevent duplicate submissions
    setState(() => _loading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.session != null && response.user != null) {
        final profile = await ref
            .read(profileServiceProvider)
            .getProfile(response.user!.id);

        if (!mounted) return;
        setState(() => _loading = false);

        if (profile != null) {
          ref.read(userProfileProvider.notifier).state = profile;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RootShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
        return;
      }

      setState(() => _loading = false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // =========================================================
    // MANUAL FORM POSITION
    // =========================================================
    // Angka lebih kecil = form makin NAIK
    // Angka lebih besar = form makin TURUN
    //
    // 200 = lebih naik
    // 219 = posisi sekarang
    // 240 = sedikit turun
    // 260 = lebih turun
    // =========================================================
    const double formTopPosition = 219.0;

    // Tinggi banner
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
            // BANNER
            // =====================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroPanelHeight,
              child: Container(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF0F391),
                child: Image.asset(
                  'assets/banner.png',
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
            // FORM
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
                  // CONTAINER FORM
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
                          'auth.welcomeBack'.tr(),
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
                          'auth.loginSubtitle'.tr(),
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
                        // EMAIL
                        // =================================================
                        _AuthField(
                          hint: 'auth.email'.tr(),
                          isDark: isDark,
                          controller: _email,
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
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                        ),

                        const SizedBox(height: 20),

                        // =================================================
                        // FORGOT PASSWORD
                        // =================================================
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'auth.forgotPassword'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF85C500),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // =================================================
                        // LOGIN BUTTON
                        // =================================================
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,

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
                                    'auth.logIn'.tr(),
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
                                // =================================================
                                // GOOGLE LOGO — LIBRARY
                                // =================================================
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
                        // REGISTER
                        // =================================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.dontHaveAccount'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF76655C),
                              ),
                            ),

                            const SizedBox(width: 4),

                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),

                              child: const Text(
                                'Sign up',
                                style: TextStyle(
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
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
  });

  final String hint;
  final bool isDark;
  final TextEditingController? controller;
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

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor, width: 1.2),
    );

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,

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

        border: border,

        enabledBorder: border,

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF85C500), width: 1.6),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 20,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280),
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
    );
  }
}
