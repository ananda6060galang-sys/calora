import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/empty_state.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/diary/food_diary_screen.dart';

/// The main authenticated app shell. Workout and Profile are stubbed with
/// "coming soon" empty states here — they're next in line to be built out
/// following the same component system already established.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    FoodDiaryScreenNoAppBar(),
    _ComingSoonTab(icon: Icons.fitness_center_rounded, label: 'Workout'),
    _ComingSoonTab(icon: Icons.person_rounded, label: 'Profile'),
  ];

  static const _destinations = [
    _NavDestination(icon: Icons.dashboard_rounded, label: 'Home'),
    _NavDestination(icon: Icons.restaurant_menu_rounded, label: 'Diary'),
    _NavDestination(icon: Icons.fitness_center_rounded, label: 'Workout'),
    _NavDestination(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _PillBottomNavigation(
        currentIndex: _index,
        destinations: _destinations,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _PillBottomNavigation extends StatelessWidget {
  const _PillBottomNavigation({
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int currentIndex;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onSelected;

  static const _duration = Duration(milliseconds: 360);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 12),
      child: SizedBox(
        height: 58,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemGap = 6.0;
            const horizontalPadding = 7.0;
            const inactiveWidth = 44.0;
            const maxActiveWidth = 104.0;
            final available = constraints.maxWidth - (horizontalPadding * 2);
            final activeWidth =
                (available -
                        (inactiveWidth * (destinations.length - 1)) -
                        (itemGap * (destinations.length - 1)))
                    .clamp(104.0, maxActiveWidth);

            return Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(horizontalPadding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < destinations.length; i++) ...[
                        _PillNavigationItem(
                          destination: destinations[i],
                          isSelected: i == currentIndex,
                          activeWidth: activeWidth,
                          inactiveWidth: inactiveWidth,
                          activeFill: AppColors.accent,
                          selectedColor: AppColors.lightTextPrimary,
                          inactiveColor: Colors.white,
                          textStyle: theme.textTheme.labelSmall,
                          duration: _duration,
                          onTap: () => onSelected(i),
                        ),
                        if (i != destinations.length - 1)
                          const SizedBox(width: itemGap),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PillNavigationItem extends StatelessWidget {
  const _PillNavigationItem({
    required this.destination,
    required this.isSelected,
    required this.activeWidth,
    required this.inactiveWidth,
    required this.activeFill,
    required this.selectedColor,
    required this.inactiveColor,
    required this.textStyle,
    required this.duration,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isSelected;
  final double activeWidth;
  final double inactiveWidth;
  final Color activeFill;
  final Color selectedColor;
  final Color inactiveColor;
  final TextStyle? textStyle;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : inactiveColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: isSelected ? activeWidth : inactiveWidth,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? activeFill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.02 : 1,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: Icon(destination.icon, size: 20, color: color),
              ),
              ClipRect(
                child: AnimatedAlign(
                  widthFactor: isSelected ? 1 : 0,
                  alignment: Alignment.centerLeft,
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: Offset(isSelected ? 0 : -0.25, 0),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: textStyle?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
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

/// Wraps FoodDiaryScreen without pushing a new route — used as a tab.
class FoodDiaryScreenNoAppBar extends StatelessWidget {
  const FoodDiaryScreenNoAppBar({super.key});

  @override
  Widget build(BuildContext context) => const FoodDiaryScreen(showBackButton: false);
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: EmptyState(
          icon: icon,
          title: '$label — coming next',
          message:
              'This part of Calora is being built next, using the '
              'same design system as Dashboard and Diary.',
        ),
      ),
    );
  }
}
