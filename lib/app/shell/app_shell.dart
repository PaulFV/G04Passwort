import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Destinations of the bottom navigation (as on the design board).
const _destinations = [
  (icon: Icons.home_rounded, label: 'Start'),
  (icon: Icons.grid_view_rounded, label: 'Kategorien'),
  (icon: Icons.password_rounded, label: 'Generator'),
  (icon: Icons.menu_rounded, label: 'Mehr'),
];

/// Responsive shell: glass bottom bar on phones, navigation rail on
/// tablets / desktop.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _GlassRail(index: shell.currentIndex, onSelect: _go),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: _GlassBottomBar(index: shell.currentIndex, onSelect: _go),
    );
  }
}

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDeep.withValues(alpha: 0.78),
            border: Border(top: BorderSide(color: accent.withValues(alpha: 0.35))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < _destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _destinations[i].icon,
                        label: _destinations[i].label,
                        selected: i == index,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final color = selected ? AppColors.neonBlueLight : AppColors.textMuted;
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
                boxShadow: [
                  if (selected) BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 14),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                shadows: selected ? [Shadow(color: accent, blurRadius: 12)] : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassRail extends StatelessWidget {
  const _GlassRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.backgroundDeep,
      selectedIndex: index,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Image.asset('assets/branding/logo_mark.png', width: 48),
      ),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
      ],
    );
  }
}
