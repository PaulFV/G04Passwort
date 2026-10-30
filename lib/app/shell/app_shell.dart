import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/auth/application/auth_controller.dart';
import '../routes.dart';

/// Destinations of the bottom navigation (as on the design board).
const _destinations = [
  (icon: Icons.home_rounded, label: 'Start'),
  (icon: Icons.grid_view_rounded, label: 'Kategorien'),
  (icon: Icons.password_rounded, label: 'Generator'),
  (icon: Icons.menu_rounded, label: 'Mehr'),
];

/// Responsive shell:
/// * phone (compact): glass bottom bar,
/// * tablet (medium/expanded): navigation rail,
/// * desktop (large): extended rail with labels.
///
/// On every size the desktop keyboard shortcuts are active:
/// Strg/⌘+K Suche · Strg/⌘+N neuer Eintrag · Strg/⌘+G Generator ·
/// Strg/⌘+L Tresor sperren.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.windowSize;
    void lock() => ref.read(authControllerProvider.notifier).lock();

    final shortcuts = <ShortcutActivator, VoidCallback>{
      for (final ctrl in [true, false]) ...{
        SingleActivator(LogicalKeyboardKey.keyK, control: ctrl, meta: !ctrl): () =>
            context.push(Routes.search),
        SingleActivator(LogicalKeyboardKey.keyN, control: ctrl, meta: !ctrl): () =>
            context.push(Routes.newItem),
        SingleActivator(LogicalKeyboardKey.keyG, control: ctrl, meta: !ctrl): () => _go(2),
        SingleActivator(LogicalKeyboardKey.keyL, control: ctrl, meta: !ctrl): lock,
      },
    };

    final Widget scaffold;
    if (size.isCompact) {
      scaffold = Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: _GlassBottomBar(index: shell.currentIndex, onSelect: _go),
      );
    } else {
      scaffold = Scaffold(
        body: Row(
          children: [
            _GlassRail(
              index: shell.currentIndex,
              onSelect: _go,
              extended: size == WindowSize.large,
              onSearch: () => context.push(Routes.search),
              onNew: () => context.push(Routes.newItem),
              onLock: lock,
            ),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(autofocus: true, child: scaffold),
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
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.backgroundDeep.withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.35)),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppColors.neonBlueLight : accent)
        : AppColors.textMuted;
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
                color: selected
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                shadows: selected
                    ? [Shadow(color: accent, blurRadius: 12)]
                    : null,
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
  const _GlassRail({
    required this.index,
    required this.onSelect,
    required this.extended,
    required this.onSearch,
    required this.onNew,
    required this.onLock,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final bool extended;
  final VoidCallback onSearch;
  final VoidCallback onNew;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0A1636), AppColors.backgroundDeep]
              : [Colors.white, const Color(0xFFE6EEFF)],
        ),
        border: Border(right: BorderSide(color: accent.withValues(alpha: 0.35))),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 24)],
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        extended: extended,
        minExtendedWidth: 232,
        selectedIndex: index,
        onDestinationSelected: onSelect,
        labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
        indicatorColor: accent.withValues(alpha: 0.22),
        selectedIconTheme: IconThemeData(
          color: isDark ? AppColors.neonBlueLight : accent,
          shadows: [Shadow(color: accent, blurRadius: 12)],
        ),
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
          child: Column(
            crossAxisAlignment: extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/branding/logo_mark.png', width: extended ? 44 : 48),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    Text(
                      'G04Passwort',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              if (extended)
                SizedBox(
                  width: 200,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: onNew,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Neuer Eintrag'),
                  ),
                )
              else
                FloatingActionButton.small(
                  heroTag: 'rail-new',
                  tooltip: 'Neuer Eintrag (Strg+N)',
                  onPressed: onNew,
                  child: const Icon(Icons.add_rounded),
                ),
            ],
          ),
        ),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Suche (Strg+K)',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: onSearch,
                  ),
                  IconButton(
                    tooltip: 'Tresor sperren (Strg+L)',
                    icon: const Icon(Icons.lock_outline_rounded),
                    onPressed: onLock,
                  ),
                ],
              ),
            ),
          ),
        ),
        destinations: [
          for (final d in _destinations)
            NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
        ],
      ),
    );
  }
}
