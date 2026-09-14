import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The atmospheric organic gradient composition occupying the upper portion of the screen.
/// Recreates the reference's exact composition:
/// - Top: Deeper, saturated Calora green (#173B2B / #0E2419)
/// - Middle: Soft transition between green tones with blurred organic forms & subtle lime glow
/// - Lower edge: Soft, misty transition fading seamlessly into the white/neutral content area
/// Atmospheric gradient using Calora's signature lime accent and botanical palette from AGENTS.md.
/// - Light mode: Luminous fresh Calora lime wash (#B8FF3B / #D4FA7E) fading down into lightBg (#FAFAF8)
/// - Dark mode: Deep botanical green (#142416) with subtle lime glow fading into darkBg (#0F1410)
class ScreenBackgroundMesh extends StatelessWidget {
  const ScreenBackgroundMesh({
    super.key,
    this.isDark = false,
    this.height = 460,
  });

  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFFAF9F6);

    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. BASE DEEP BOTANICAL FOREST GRADIENT (Top-Left to Bottom-Right)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-0.8, -1.0),
                    end: const Alignment(0.6, 1.0),
                    colors: isDark
                        ? [
                            const Color(0xFF0F1E14),
                            const Color(0xFF142C1C),
                            const Color(0xFF1A3824).withValues(alpha: 0.70),
                            const Color(0xFF122317).withValues(alpha: 0.30),
                            bgColor.withValues(alpha: 0.0),
                          ]
                        : [
                            const Color(0xFF163C29), // Deep rich forest green (top-left)
                            const Color(0xFF1E4E36), // Saturated botanical emerald
                            const Color(0xFF336C4E).withValues(alpha: 0.90),
                            const Color(0xFF6B9F84).withValues(alpha: 0.45),
                            bgColor.withValues(alpha: 0.0),
                          ],
                    stops: const [0.0, 0.28, 0.58, 0.82, 1.0],
                  ),
                ),
              ),

              // 2. LARGE ORGANIC AMBIENT GLOW TOWARD THE RIGHT (Matching Image 1)
              Positioned(
                top: -60,
                right: -50,
                width: 380,
                height: 420,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(0.1, -0.1),
                        radius: 0.75,
                        colors: isDark
                            ? [
                                AppColors.accent.withValues(alpha: 0.08),
                                const Color(0xFF1F432A).withValues(alpha: 0.45),
                                const Color(0xFF163220).withValues(alpha: 0.15),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF4A946D).withValues(alpha: 0.70), // Luminous sage
                                AppColors.accent.withValues(alpha: 0.15),       // Subtle Calora lime glow
                                const Color(0xFF2C6345).withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. VELVETY DEEP CORNER ACCENT (Top-Left richness)
              Positioned(
                top: -40,
                left: -40,
                width: 260,
                height: 260,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                              ? const Color(0xFF0A150D)
                              : const Color(0xFF0F2B1D)).withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. DOWNWARD SOFT MIST (Seamless bleed into white content background)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bgColor.withValues(alpha: 0.0),
                        bgColor.withValues(alpha: 0.40),
                        bgColor.withValues(alpha: 0.85),
                        bgColor,
                      ],
                      stops: const [0.0, 0.40, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



/// The circular aura with white sparkle button for Screen 2 (Trends)
/// Infused with Calora's signature lime green and deep emerald aesthetic.
class CompactAuraOrb extends StatelessWidget {
  const CompactAuraOrb({
    super.key,
    this.size = 110,
    this.isDark = false,
  });

  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient blurred lime glow
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: size * 0.90,
              height: size * 0.90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0.1, -0.1),
                  radius: 0.85,
                  colors: isDark
                      ? [
                          AppColors.accent.withValues(alpha: 0.28),
                          const Color(0xFF064E3B).withValues(alpha: 0.60),
                          Colors.transparent,
                        ]
                      : [
                          AppColors.accent.withValues(alpha: 0.55),
                          const Color(0xFF86EFAC).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ),

          // Inner dark vortex (matching deep center)
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF052E16) : const Color(0xFF064E3B))
                      .withValues(alpha: isDark ? 0.92 : 0.70),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          // Floating circular sparkle button with lime accent
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }
}

// Backwards compatibility alias
class OrganicAura extends StatelessWidget {
  const OrganicAura({
    super.key,
    this.size = 110,
    this.showSparkle = true,
  });

  final double size;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CompactAuraOrb(size: size, isDark: isDark);
  }
}
