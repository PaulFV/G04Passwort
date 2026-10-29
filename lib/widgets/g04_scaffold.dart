import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/application/settings_controller.dart';

/// Full-screen artwork background with a dark gradient for readability.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.asset,
    this.alignment = Alignment.topCenter,
    this.dim = 0.55,
    this.dark = true,
  });

  final String asset;
  final Alignment alignment;

  /// 0 = image fully visible, 1 = fully covered by the gradient.
  final double dim;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final base = dark ? AppColors.background : const Color(0xFFEAF1FF);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        Opacity(
          opacity: dark ? 1 : 0.35,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: dim * 0.6),
                base.withValues(alpha: dim),
                base.withValues(alpha: (dim + 0.3).clamp(0, 1)),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard page scaffold of G04Passwort: background artwork, transparent
/// app bar, centred content with a max width for tablets / desktop.
class G04Scaffold extends ConsumerWidget {
  const G04Scaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backgroundAsset,
    this.showAppBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.bottom,
    this.leading,
    this.dim = 0.55,
  });

  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  /// Overrides the user selected background (e.g. login).
  final String? backgroundAsset;
  final bool showAppBar;
  final EdgeInsetsGeometry padding;
  final Widget? bottom;
  final Widget? leading;
  final double dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Stack(
      children: [
        Positioned.fill(
          child: AppBackground(
            asset: backgroundAsset ?? settings.background.asset,
            dark: settings.darkMode,
            dim: dim,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: showAppBar
              ? AppBar(
                  title: title == null ? null : Text(title!),
                  actions: actions,
                  leading: leading,
                )
              : null,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottom,
          body: SafeArea(
            top: !showAppBar,
            bottom: bottom == null,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Padding(padding: padding, child: body),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
