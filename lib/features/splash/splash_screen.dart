import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/root_shell.dart';
import '../auth/login_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/profile_provider.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(milliseconds: 1800);

  late final AnimationController _controller;

  late final Animation<double> _background;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlide;
  late final Animation<double> _logoFadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );

    // Gradient bergerak dari atas ke bawah
    _background = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.75,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Logo fade in
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.05,
        0.28,
        curve: Curves.easeOut,
      ),
    );

    // Logo pop up
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.70,
          end: 1.10,
        ).chain(
          CurveTween(
            curve: Curves.easeOutBack,
          ),
        ),
        weight: 75,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.10,
          end: 1.0,
        ).chain(
          CurveTween(
            curve: Curves.easeOut,
          ),
        ),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.05,
          0.45,
        ),
      ),
    );

    // Logo sedikit naik saat pop up
    _logoSlide = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.05,
          0.42,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // Fade out menjelang pindah halaman
    _logoFadeOut = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.82,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });

    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user != null) {
      final profile =
          await ref.read(profileServiceProvider).getProfile(user.id);

      if (!mounted) return;

      if (profile != null) {
        ref.read(userProfileProvider.notifier).state = profile;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (
              context,
              animation,
              secondaryAnimation,
            ) {
              return const RootShell();
            },
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(
              milliseconds: 450,
            ),
          ),
        );

        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (
            context,
            animation,
            secondaryAnimation,
          ) {
            return const OnboardingScreen();
          },
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(
            milliseconds: 450,
          ),
        ),
      );

      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const LoginScreen();
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(
          milliseconds: 450,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final movement = _background.value;

            return DecoratedBox(
              // Background gradient bergerak vertikal
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    0.0,
                    -1.0 + movement * 0.55,
                  ),
                  end: Alignment(
                    0.0,
                    1.0 + movement * 0.55,
                  ),
                  colors: const [
                    Color(0xFFB6FF00),
                    Color(0xFFBFFF28),
                    Color(0xFFDDE7C9),
                  ],
                  stops: const [
                    0.0,
                    0.48,
                    1.0,
                  ],
                ),
              ),

              child: child,
            );
          },

          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final opacity =
                  (_logoFade.value * _logoFadeOut.value).clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    _logoSlide.value + 12,
                  ),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                ),
              );
            },

            child: Center(
              child: Image.asset(
                'assets/logo.png',
                width: 215,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}