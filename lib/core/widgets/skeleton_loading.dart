import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A synchronized, high-performance shimmer sweep controller.
/// Provides silky smooth 60/120fps gradient animation across all skeleton children.
class CaloraShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const CaloraShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<CaloraShimmer> createState() => _CaloraShimmerState();

  /// Helper to wrap any widget in a self-contained shimmer effect
  static Widget fromColors({
    Key? key,
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    return CaloraShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      child: child,
    );
  }
}

class _CaloraShimmerState extends State<CaloraShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = widget.baseColor ??
        (isDark ? const Color(0xFF212529) : const Color(0xFFE9ECEF));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF343A40) : const Color(0xFFF8F9FA));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            // Smooth diagonal sweep from left to right with wide soft band
            return LinearGradient(
              begin: const Alignment(-1.5, -0.4),
              end: const Alignment(1.5, 0.4),
              colors: [
                base,
                highlight,
                base,
              ],
              stops: [
                (t - 0.25).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.25).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Primitive skeleton rectangle with customizable radius and dimensions.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF262A2E) : const Color(0xFFEDF0F2);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(10)),
      ),
    );
  }
}

/// Skeleton text line block
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSITE DOMAIN SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

/// Realistic Food Item / Search Result Skeleton Card
class FoodItemSkeleton extends StatelessWidget {
  const FoodItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Food image / icon circle
          const SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          const SizedBox(width: 14),
          // Title, brand and portion lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SkeletonText(width: 140, height: 15),
                const SizedBox(height: 7),
                Row(
                  children: const [
                    SkeletonText(width: 60, height: 11),
                    SizedBox(width: 8),
                    SkeletonText(width: 45, height: 11),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Calories and action pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonText(width: 50, height: 16),
              SizedBox(height: 6),
              SkeletonText(width: 32, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

/// List of Food Item Skeletons for search or database loading
class FoodSearchSkeletonList extends StatelessWidget {
  final int itemCount;

  const FoodSearchSkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return CaloraShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemCount,
        itemBuilder: (_, index) => const FoodItemSkeleton(),
      ),
    );
  }
}

/// Meal Section Skeleton for Food Diary (Breakfast, Lunch, Dinner, Snack)
class MealSectionSkeleton extends StatelessWidget {
  const MealSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  SkeletonBox.circle(size: 28),
                  SizedBox(width: 10),
                  SkeletonText(width: 90, height: 16),
                ],
              ),
              SkeletonText(width: 55, height: 15),
            ],
          ),
          const SizedBox(height: 16),
          // Meal item rows
          const FoodItemSkeleton(),
          const SizedBox(height: 4),
          // Add food pill button placeholder
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonBox(
              width: 90,
              height: 32,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard Hero & Nutrition Summary Skeleton
class DashboardSummarySkeleton extends StatelessWidget {
  const DashboardSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CaloraShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calorie Hero Card Skeleton
          Container(
            height: 190,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SkeletonText(width: 80, height: 13),
                      SizedBox(height: 12),
                      SkeletonText(width: 120, height: 32),
                      SizedBox(height: 12),
                      SkeletonText(width: 150, height: 14),
                    ],
                  ),
                ),
                const SkeletonBox.circle(size: 110),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 3 Macro Cards Row
          Row(
            children: const [
              Expanded(
                child: SkeletonBox(
                  height: 96,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonBox(
                  height: 96,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonBox(
                  height: 96,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
