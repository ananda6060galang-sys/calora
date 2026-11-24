import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/profile_service.dart';
import '../dashboard/providers/profile_provider.dart';

/// Available subscription plan tiers
enum SubscriptionPlan {
  weekly,
  monthly,
  yearly,
}

/// 100% Pixel-faithful, interactive fluid-wave paywall for Calora.
/// Exactly matches the organic S-curve dividers, raised tab header, flush unified sides,
/// and smooth per-folder accordion expansion with zero text collisions.
class PremiumPaywallScreen extends ConsumerStatefulWidget {
  const PremiumPaywallScreen({super.key});

  /// Helper to push the paywall screen smoothly
  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const PremiumPaywallScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends ConsumerState<PremiumPaywallScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  bool _startFreeTrial = true;

  void _selectPlan(SubscriptionPlan plan) {
    if (_selectedPlan != plan) {
      HapticFeedback.mediumImpact();
      setState(() {
        _selectedPlan = plan;
      });
    }
  }

  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();
    final isIndonesian = context.locale.languageCode == 'id';

    // 1. Instantly upgrade Riverpod in-memory state
    ref.read(userProfileProvider.notifier).update(
          (p) => p.copyWith(isPremium: true),
        );

    // 2. Persist to Supabase database if authenticated
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await ProfileService(client).updatePremiumStatus(
          userId: user.id,
          isPremium: true,
        );
      }
    } catch (_) {
      // Graceful offline fallback
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isIndonesian
              ? 'Selamat datang di Calora Pro! Akses penuh aktif.'
              : 'Welcome to Calora Pro! Full access granted.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF141713),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isIndonesian = context.locale.languageCode == 'id';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9FEE6), // Pale creamy lime
              Color(0xFFE2F89A), // Radiant mid lime
              Color(0xFFCEF65A), // Electric chartreuse lime
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── 1. Top Bar & Title ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: SizedBox(
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Floating circular back button
                      Positioned(
                        left: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).maybePop();
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Color(0xFF141713),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Centered 2-line title
                      Center(
                        child: Text(
                          isIndonesian
                              ? 'Dapatkan Akses\nTanpa Batas'
                              : 'Get Unlimited\nAccess',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 22.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141713),
                            height: 1.15,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Scrollable Body with Interactive Fluid Wave Deck ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      // ── The Exact Fluid Wave Deck ──
                      _buildFluidWaveDeck(isIndonesian),
                      const SizedBox(height: 12),

                      // ── 7-Day Free Trial Toggle ──
                      _buildFreeTrialRow(isIndonesian),
                      const SizedBox(height: 10),

                      // ── Bottom Action Button ──
                      _buildBottomCTA(isIndonesian),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fluid Wave Deck with Per-Folder Interactive Expansion ────────────

  Widget _buildFluidWaveDeck(bool isIndonesian) {
    // Dynamic wave boundary targets matching the exact reference ratios
    final double targetWave1Left;
    final double targetWave2Left;
    final double targetDeckHeight;

    switch (_selectedPlan) {
      case SubscriptionPlan.weekly:
        targetWave1Left = 246.0;
        targetWave2Left = 318.0;
        targetDeckHeight = 440.0;
        break;
      case SubscriptionPlan.monthly:
        targetWave1Left = 72.0;
        targetWave2Left = 326.0;
        targetDeckHeight = 444.0;
        break;
      case SubscriptionPlan.yearly:
        targetWave1Left = 72.0;
        targetWave2Left = 144.0;
        targetDeckHeight = 496.0;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      height: targetDeckHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const _DeckOutlineClipper(
          shoulderDrop: 24.0,
          cornerRadius: 32.0,
        ),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          tween: Tween<double>(begin: targetWave1Left, end: targetWave1Left),
          builder: (context, animWave1Left, _) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              tween: Tween<double>(begin: targetWave2Left, end: targetWave2Left),
              builder: (context, animWave2Left, _) {
                final animWave1Right = animWave1Left + 44.0;
                final animWave2Right = animWave2Left + 44.0;

                return Stack(
                  children: [
                    // ── LAYER 3 (BASE): Yearly Obsidian Black ────────
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF141713),
                      ),
                    ),

                    // ── LAYER 2 (MIDDLE): Monthly Crisp White Wave ───
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _WaveFillPainter(
                          fillColor: Colors.white,
                          yLeft: animWave2Left,
                          yRight: animWave2Right,
                        ),
                      ),
                    ),

                    // ── LAYER 1 (TOP): Weekly Vibrant Lime Wave ──────
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _WaveFillPainter(
                          fillColor: const Color(0xFF98E500),
                          yLeft: animWave1Left,
                          yRight: animWave1Right,
                        ),
                      ),
                    ),

                    // ── 1. WEEKLY TIER (TOP GREEN) ───────────────────
                    _buildWeeklySection(
                      isIndonesian: isIndonesian,
                      isExpanded: _selectedPlan == SubscriptionPlan.weekly,
                      wave1Right: animWave1Right,
                    ),

                    // ── 2. MONTHLY TIER (MIDDLE WHITE) ───────────────
                    _buildMonthlySection(
                      isIndonesian: isIndonesian,
                      isExpanded: _selectedPlan == SubscriptionPlan.monthly,
                      wave1Left: animWave1Left,
                      wave1Right: animWave1Right,
                      wave2Left: animWave2Left,
                      wave2Right: animWave2Right,
                    ),

                    // ── 3. YEARLY TIER (BOTTOM BLACK - SCREENSHOT) ───
                    _buildYearlySection(
                      isIndonesian: isIndonesian,
                      isExpanded: _selectedPlan == SubscriptionPlan.yearly,
                      wave2Left: animWave2Left,
                      wave2Right: animWave2Right,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Weekly Section ───────────────────────────────────────────────────

  Widget _buildWeeklySection({
    required bool isIndonesian,
    required bool isExpanded,
    required double wave1Right,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: wave1Right,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectPlan(SubscriptionPlan.weekly),
        child: Stack(
          children: [
            // Left info: Weekly + $2.99
            Positioned(
              top: 14,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIndonesian ? 'Mingguan' : 'Weekly',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF141713),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    r'$2.99',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF141713),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Right "Choose" button (inside right shoulder)
            Positioned(
              top: 48,
              right: 18,
              child: _buildChooseButton(
                plan: SubscriptionPlan.weekly,
                isIndonesian: isIndonesian,
              ),
            ),

            // Benefits list (safely below header with zero collision)
            if (isExpanded)
              Positioned(
                top: 86,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: isExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      _buildCheckItem(
                        text: isIndonesian
                            ? '7 hari scan AI & barcode penuh'
                            : 'Unlimited scans (7 days)',
                        checkBgColor: Colors.white,
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Akses histori & analitik pantry aktif'
                            : 'Pantry access and saved history',
                        checkBgColor: Colors.white,
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'NutriScore lengkap & rincian gizi'
                            : 'Full Clean Score & nutrient breakdown',
                        checkBgColor: Colors.white,
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Konsultasi Coach AI mingguan'
                            : 'Weekly AI Coach consultation',
                        checkBgColor: Colors.white,
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Monthly Section ──────────────────────────────────────────────────

  Widget _buildMonthlySection({
    required bool isIndonesian,
    required bool isExpanded,
    required double wave1Left,
    required double wave1Right,
    required double wave2Left,
    required double wave2Right,
  }) {
    return Positioned(
      top: wave1Left,
      left: 0,
      right: 0,
      height: wave2Right - wave1Left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectPlan(SubscriptionPlan.monthly),
        child: Stack(
          children: [
            // Left info: Monthly + $7.99
            Positioned(
              top: 14,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIndonesian ? 'Bulanan' : 'Monthly',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF141713),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    r'$7.99',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF141713),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 2),
                    Text(
                      isIndonesian ? 'Hemat 25%' : 'Save 25%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E6319),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right "Choose" button (inside right shoulder)
            Positioned(
              top: 14 + (wave1Right - wave1Left) - 10,
              right: 18,
              child: _buildChooseButton(
                plan: SubscriptionPlan.monthly,
                isIndonesian: isIndonesian,
              ),
            ),

            // Benefits list (safely below header with zero collision)
            if (isExpanded)
              Positioned(
                top: 86,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: isExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Scan AI & Barcode tanpa batas (1 bulan)'
                            : 'Unlimited AI & barcode scanning (1 month)',
                        checkBgColor: const Color(0xFF98E500),
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Akses riwayat & analitik pantry lengkap'
                            : 'Full pantry access & saved history',
                        checkBgColor: const Color(0xFF98E500),
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'NutriScore lengkap & rincian gizi'
                            : 'Full Clean Score & macro breakdown',
                        checkBgColor: const Color(0xFF98E500),
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Target kalori & diet personal adaptif'
                            : 'Personalized diet & calorie targets',
                        checkBgColor: const Color(0xFF98E500),
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Konsultasi Coach AI tanpa limit'
                            : 'Unlimited AI Coach consultations',
                        checkBgColor: const Color(0xFF98E500),
                        checkIconColor: const Color(0xFF141713),
                        textColor: const Color(0xFF141713),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Yearly Section (Expanded by Default - Exactly like Screenshot) ───

  Widget _buildYearlySection({
    required bool isIndonesian,
    required bool isExpanded,
    required double wave2Left,
    required double wave2Right,
  }) {
    return Positioned(
      top: wave2Left,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectPlan(SubscriptionPlan.yearly),
        child: Stack(
          children: [
            // Left info: Yearly + $49.99 + Save 48%
            Positioned(
              top: 14,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIndonesian ? 'Tahunan' : 'Yearly',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    r'$49.99',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isIndonesian ? 'Hemat 48%' : 'Save 48%',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD6FA55),
                    ),
                  ),
                ],
              ),
            ),

            // Right "Choose" button (in neon lime)
            Positioned(
              top: 14 + (wave2Right - wave2Left) - 6,
              right: 18,
              child: _buildChooseButton(
                plan: SubscriptionPlan.yearly,
                isIndonesian: isIndonesian,
              ),
            ),

            // ── 7 FEATURE CHECKLIST ITEMS (22px safe clearance below header) ──
            if (isExpanded)
              Positioned(
                top: 104,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: isExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Scan AI & Barcode tanpa batas'
                            : 'Unlimited scans',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Akses histori & analitik pantry lengkap'
                            : 'Pantry access and saved history',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'NutriScore lengkap & rincian gizi'
                            : 'Full Clean Score & flagged breakdown',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Target kalori & diet personal adaptif'
                            : 'Personalized diet compatibility',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Tanya Coach AI tanpa batas'
                            : 'Unlimited label/ingredient questions',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Badge eksklusif, streak & milestone'
                            : 'Gamification features unlocked',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _buildCheckItem(
                        text: isIndonesian
                            ? 'Dukungan prioritas 24/7'
                            : 'Priority support',
                        checkBgColor: const Color(0xFFD6FA55),
                        checkIconColor: const Color(0xFF141713),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── "Choose" Pill Button ─────────────────────────────────────────────

  Widget _buildChooseButton({
    required SubscriptionPlan plan,
    required bool isIndonesian,
  }) {
    final isSelected = _selectedPlan == plan;

    final Color bgColor;
    final Color textColor;

    if (isSelected) {
      bgColor = const Color(0xFFD6FA55); // Neon chartreuse lime
      textColor = const Color(0xFF141713);
    } else {
      bgColor = Colors.white;
      textColor = const Color(0xFF141713);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectPlan(plan),
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.98,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 96,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(19),
            border: !isSelected && plan == SubscriptionPlan.monthly
                ? Border.all(color: const Color(0xFFEEEEEE), width: 0.8)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.05),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            isIndonesian ? 'Pilih' : 'Choose',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── Checklist Item ───────────────────────────────────────────────────

  Widget _buildCheckItem({
    required String text,
    required Color checkBgColor,
    required Color checkIconColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: checkBgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            size: 13,
            color: checkIconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.2,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  // ── 7-Day Free Trial Toggle Row ──────────────────────────────────────

  Widget _buildFreeTrialRow(bool isIndonesian) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isIndonesian ? 'Mulai coba gratis 7 hari' : 'Start 7-day free trial',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF141713),
            ),
          ),
          Transform.scale(
            scale: 0.88,
            child: CupertinoSwitch(
              value: _startFreeTrial,
              activeTrackColor: const Color(0xFF98E500),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _startFreeTrial = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Button ─────────────────────────────────────────────

  Widget _buildBottomCTA(bool isIndonesian) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleContinue,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF141713),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          _startFreeTrial
              ? (isIndonesian
                  ? 'Mulai Coba Gratis 7 Hari'
                  : 'Start 7-Day Free Trial')
              : (isIndonesian
                  ? 'Berlangganan Calora Pro'
                  : 'Subscribe to Calora Pro'),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ── Organic Deck Outline Clipper ──────────────────────────────────────

/// Clips the entire deck to match the exact organic fluid wave header profile from the screenshot:
/// Top-left starts high with a rounded corner, smoothly curves down to the right shoulder,
/// and has large smooth rounded corners at the bottom.
class _DeckOutlineClipper extends CustomClipper<Path> {
  final double shoulderDrop;
  final double cornerRadius;

  const _DeckOutlineClipper({
    required this.shoulderDrop,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final startX = w * 0.32;
    final endX = w * 0.66;
    final dx = endX - startX;

    // Top-left corner
    path.moveTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.lineTo(startX, 0);

    // Smooth organic S-curve down to the right shoulder
    path.cubicTo(
      startX + dx * 0.45,
      0,
      endX - dx * 0.45,
      shoulderDrop,
      endX,
      shoulderDrop,
    );

    // Right shoulder and top-right corner
    path.lineTo(w - r, shoulderDrop);
    path.arcToPoint(Offset(w, shoulderDrop + r), radius: Radius.circular(r));

    // Right vertical edge down to bottom-right corner
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // Bottom horizontal edge to bottom-left corner
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));

    // Left vertical edge up to start
    path.lineTo(0, r);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _DeckOutlineClipper oldClipper) => false;
}

// ── Continuous Seamless Wave Painter ──────────────────────────────────

/// Draws parallel organic S-curve dividers that match the exact fluid wave profile.
class _WaveFillPainter extends CustomPainter {
  final Color fillColor;
  final double yLeft;
  final double yRight;

  const _WaveFillPainter({
    required this.fillColor,
    required this.yLeft,
    required this.yRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final startX = size.width * 0.32;
    final endX = size.width * 0.66;
    final dx = endX - startX;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    // Right vertical line down to yRight
    path.lineTo(size.width, yRight);
    // Flat horizontal edge on the right
    path.lineTo(endX, yRight);

    // Smooth cubic S-curve inflection up to (startX, yLeft)
    path.cubicTo(
      endX - dx * 0.45,
      yRight,
      startX + dx * 0.45,
      yLeft,
      startX,
      yLeft,
    );

    // Flat horizontal edge on the left
    path.lineTo(0, yLeft);
    path.close();

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveFillPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.yLeft != yLeft ||
        oldDelegate.yRight != yRight;
  }
}
