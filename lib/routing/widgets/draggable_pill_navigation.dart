import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A precision-engineered draggable pill bottom navigation bar.
///
/// Features:
/// - 100% overflow-safe layout (zero RenderFlex overflow warnings during drag).
/// - 1:1 real-time drag tracking with soft rubber-band resistance.
/// - Exact geometry and spacing identical to the original Calora navbar.
/// - Fluid animated sliding pill with haptic feedback on boundary crossing.
class DraggablePillNavigation extends StatefulWidget {
  const DraggablePillNavigation({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int currentIndex;
  final List<NavDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  State<DraggablePillNavigation> createState() => _DraggablePillNavigationState();
}

class _DraggablePillNavigationState extends State<DraggablePillNavigation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _anim;

  double _progress = 0.0;
  bool _isDragging = false;
  double _dragStartX = 0.0;
  double _dragStartProgress = 0.0;
  int _lastHapticIndex = 0;

  // Exact metrics matching original Calora _PillBottomNavigation
  static const double _itemGap = 6.0;
  static const double _horizontalPadding = 7.0;
  static const double _inactiveWidth = 44.0;
  static const double _activeWidth = 104.0;
  static const double _tabHeight = 44.0; // 44 + (7*2) = 58 total height. Zero overflow!
  static const double _step = _inactiveWidth + _itemGap; // exactly 50.0

  @override
  void initState() {
    super.initState();
    _progress = widget.currentIndex.toDouble();
    _lastHapticIndex = widget.currentIndex;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.addListener(() {
      setState(() {
        _progress = _anim.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant DraggablePillNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(int targetIndex) {
    final target = targetIndex.clamp(0, widget.destinations.length - 1).toDouble();
    _anim = Tween<double>(begin: _progress, end: target).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward(from: 0.0);
  }

  void _snapTo(int targetIndex) {
    final clamped = targetIndex.clamp(0, widget.destinations.length - 1);
    _lastHapticIndex = clamped;
    _animateTo(clamped);
    if (clamped != widget.currentIndex) {
      widget.onSelected(clamped);
    }
  }

  /// Calculates the exact X position of tab [k] at progress [p]
  double _tabLeft(int k, double p) {
    final clampedP = p.clamp(0.0, (widget.destinations.length - 1).toDouble());
    double shift;
    if (clampedP <= k - 1) {
      shift = 60.0;
    } else if (clampedP >= k) {
      shift = 0.0;
    } else {
      final t = clampedP - (k - 1);
      shift = 60.0 * (1.0 - t);
    }
    return (k * _step) + shift;
  }

  /// Calculates the exact width of tab [k] at progress [p]
  double _tabWidth(int k, double p) {
    final clampedP = p.clamp(0.0, (widget.destinations.length - 1).toDouble());
    if (clampedP <= k - 1 || clampedP >= k + 1) {
      return _inactiveWidth;
    } else if (clampedP < k) {
      final t = clampedP - (k - 1);
      return _inactiveWidth + (60.0 * t);
    } else {
      final t = clampedP - k;
      return _activeWidth - (60.0 * t);
    }
  }

  /// Determines which tab was touched based on local coordinate
  int _tabAtLocalX(double localX) {
    final contentX = localX - _horizontalPadding;
    for (int k = 0; k < widget.destinations.length; k++) {
      final left = _tabLeft(k, _progress);
      final width = _tabWidth(k, _progress);
      if (contentX >= left - (_itemGap / 2) &&
          contentX <= left + width + (_itemGap / 2)) {
        return k;
      }
    }
    return (contentX / _step).round().clamp(0, widget.destinations.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final numDestinations = widget.destinations.length;
    final maxP = (numDestinations - 1).toDouble();

    // Total content width: 3 * 50 + 104 = 254.0
    const totalContentWidth = (_inactiveWidth * 3) + (_itemGap * 3) + _activeWidth;
    // Total bar width: 254 + 14 = 268.0
    const totalBarWidth = totalContentWidth + (_horizontalPadding * 2);

    // Green pill slider position: clamped between 0 and maxP
    final clampedP = _progress.clamp(0.0, maxP);
    final pillLeft = clampedP * _step;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 12),
      child: SizedBox(
        height: 58,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final target = _tabAtLocalX(details.localPosition.dx);
              HapticFeedback.selectionClick();
              _snapTo(target);
            },
            onHorizontalDragStart: (details) {
              _isDragging = true;
              _dragStartX = details.localPosition.dx;
              _dragStartProgress = _progress;
              _animController.stop();
            },
            onHorizontalDragUpdate: (details) {
              final dx = details.localPosition.dx - _dragStartX;
              final deltaP = dx / _step;
              var rawP = _dragStartProgress + deltaP;

              // Soft rubber-band resistance beyond boundaries
              if (rawP < 0.0) {
                rawP = rawP * 0.25;
              } else if (rawP > maxP) {
                rawP = maxP + (rawP - maxP) * 0.25;
              }

              // Haptic tick on crossing tab boundaries
              final roundedP = rawP.round().clamp(0, numDestinations - 1);
              if (roundedP != _lastHapticIndex &&
                  (rawP - roundedP).abs() < 0.18) {
                _lastHapticIndex = roundedP;
                HapticFeedback.selectionClick();
              }

              setState(() {
                _progress = rawP;
              });
            },
            onHorizontalDragEnd: (details) {
              _isDragging = false;
              final velocity = details.primaryVelocity ?? 0.0;
              int targetIndex;

              if (velocity.abs() > 220) {
                targetIndex = velocity > 0 ? _progress.ceil() : _progress.floor();
              } else {
                targetIndex = _progress.round();
              }

              _snapTo(targetIndex);
            },
            onHorizontalDragCancel: () {
              _isDragging = false;
              _snapTo(_progress.round());
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: isDark
                    ? Border.all(color: AppColors.darkBorder, width: 1)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                width: totalBarWidth,
                height: 58,
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: _horizontalPadding,
                ),
                child: SizedBox(
                  width: totalContentWidth,
                  height: _tabHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── 1. FLUID SLIDING LIME-GREEN PILL ─────────────────
                      Positioned(
                        left: pillLeft,
                        top: 0,
                        width: _activeWidth,
                        height: _tabHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),

                      // ── 2. FOREGROUND TAB ICONS & LABELS ──────────────────
                      for (int k = 0; k < numDestinations; k++) ...[
                        _buildTabItem(
                          k: k,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int k,
    required bool isDark,
    required ThemeData theme,
  }) {
    final destination = widget.destinations[k];
    final left = _tabLeft(k, _progress);
    final width = _tabWidth(k, _progress);

    // Closeness to this tab (1.0 = fully active, 0.0 = inactive)
    final closeness = (1.0 - (_progress - k).abs()).clamp(0.0, 1.0);
    final smoothCloseness = Curves.easeOutCubic.transform(closeness);

    // Color transition: dark #0F1410 on lime pill, white / secondary on dark track
    final inactiveColor = isDark ? AppColors.darkTextSecondary : Colors.white;
    const selectedColor = Color(0xFF0F1410);
    final itemColor = Color.lerp(inactiveColor, selectedColor, smoothCloseness)!;

    return Positioned(
      left: left,
      top: 0,
      width: width,
      height: _tabHeight,
      child: IgnorePointer(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: 0,
            maxWidth: _activeWidth,
            minHeight: _tabHeight,
            maxHeight: _tabHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1.0 + (0.02 * smoothCloseness),
                  child: Icon(
                    destination.icon,
                    size: 20,
                    color: itemColor,
                  ),
                ),
                if (closeness > 0.08) ...[
                  ClipRect(
                    child: Align(
                      widthFactor: smoothCloseness,
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: smoothCloseness,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: itemColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
