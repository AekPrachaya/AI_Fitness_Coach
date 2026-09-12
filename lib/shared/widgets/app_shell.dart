import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ── Nav item data ────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    label: 'Home',
    activeIcon: Icons.home_rounded,
    inactiveIcon: Icons.home_outlined,
    route: '/home',
  ),
  _NavItem(
    label: 'Workout',
    activeIcon: Icons.fitness_center_rounded,
    inactiveIcon: Icons.fitness_center_outlined,
    route: '/workout',
  ),
  _NavItem(
    label: 'Progress',
    activeIcon: Icons.bar_chart_rounded,
    inactiveIcon: Icons.bar_chart_outlined,
    route: '/progress',
  ),
  _NavItem(
    label: 'Profile',
    activeIcon: Icons.person_rounded,
    inactiveIcon: Icons.person_outlined,
    route: '/profile',
  ),
];

// ── AppShell ─────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _activeIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workout')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  bool _shouldShowNavBar(String location) {
    const hideOn = ['/session', '/pre', '/summary'];
    return !hideOn.any((suffix) => location.contains(suffix));
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final activeIndex = _activeIndex(location);
    final showNavBar = _shouldShowNavBar(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: showNavBar
          ? _AppBottomNavBar(activeIndex: activeIndex)
          : null,
    );
  }
}

// ── _AppBottomNavBar ─────────────────────────────────────────────────────────

class _AppBottomNavBar extends StatelessWidget {
  final int activeIndex;

  const _AppBottomNavBar({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = index == activeIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isActive) context.go(item.route);
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isActive ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Icon(
                            isActive ? item.activeIcon : item.inactiveIcon,
                            size: 24,
                            color: isActive
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        if (isActive) ...[
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppColors.accent,
                                ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
