import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// 3D building blocks of the dashboard: raised neon slabs that sink in
/// when pressed.
///
/// A [Raised3D] consists of a dark "edge" (the visible side of the slab)
/// and a lit face with a glossy top highlight. Pressing moves the face
/// down onto the edge and shrinks the shadow – like a physical button.
class Raised3D extends StatefulWidget {
  const Raised3D({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.radius = 18,
    this.depth = 6,
    this.padding = const EdgeInsets.all(14),
    this.filled = false,
    this.glow = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Rim / glow colour. Defaults to the theme accent.
  final Color? accent;
  final double radius;

  /// Height of the slab edge in logical pixels.
  final double depth;
  final EdgeInsetsGeometry padding;

  /// `true` paints the face in the accent colour (primary button).
  final bool filled;
  final bool glow;
  final String? semanticLabel;

  @override
  State<Raised3D> createState() => _Raised3DState();
}

class _Raised3DState extends State<Raised3D> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = widget.accent ?? theme.colorScheme.primary;
    final radius = BorderRadius.circular(widget.radius);
    final depth = widget.depth;
    final sink = _down ? depth * 0.8 : 0.0;

    final faceColors = widget.filled
        ? [
            Color.lerp(accent, Colors.white, 0.28)!,
            accent,
            Color.lerp(accent, Colors.black, 0.28)!,
          ]
        : dark
        ? const [Color(0xFF21468A), Color(0xFF142D61), Color(0xFF0A1838)]
        : const [Color(0xFFFFFFFF), Color(0xFFF1F6FF), Color(0xFFDCE8FF)];
    final edgeColors = widget.filled
        ? [
            Color.lerp(accent, Colors.black, 0.45)!,
            Color.lerp(accent, Colors.black, 0.65)!,
          ]
        : dark
        ? [Color.lerp(accent, Colors.black, 0.62)!, const Color(0xFF030814)]
        : [Color.lerp(accent, Colors.white, 0.35)!, Color.lerp(accent, Colors.black, 0.1)!];

    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, sink, 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: faceColors,
          stops: const [0, 0.45, 1],
        ),
        border: Border.all(
          color: widget.filled
              ? Color.lerp(accent, Colors.white, 0.55)!
              : accent.withValues(alpha: dark ? 0.75 : 0.45),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Glossy reflection on the upper half of the face.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 34,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: dark || widget.filled ? 0.22 : 0.7),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              if (widget.glow)
                BoxShadow(
                  color: accent.withValues(alpha: _down ? 0.25 : (dark ? 0.42 : 0.3)),
                  blurRadius: _down ? 10 : 22,
                  spreadRadius: -4,
                  offset: Offset(0, depth + (_down ? 1 : 6)),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.55 : 0.14),
                blurRadius: _down ? 6 : 16,
                offset: Offset(0, depth + (_down ? 1 : 8)),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Side of the slab, visible below the face.
              Positioned.fill(
                top: depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: edgeColors,
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: dark ? 0.35 : 0.3),
                    ),
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: depth), child: face),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round 3D button with an icon (header actions).
class RoundButton3D extends StatelessWidget {
  const RoundButton3D({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 44,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        child: Raised3D(
          onTap: onTap,
          radius: size / 2,
          depth: 4,
          filled: filled,
          padding: EdgeInsets.zero,
          semanticLabel: tooltip,
          child: SizedBox(
            height: size - 4,
            child: Center(
              child: Icon(
                icon,
                size: size * 0.48,
                color: filled ? Colors.white : AppColors.neonBlueLight,
                shadows: const [Shadow(color: AppColors.neonBlue, blurRadius: 10)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3D pill button with label (primary = filled accent, secondary = glass).
class Button3D extends StatelessWidget {
  const Button3D({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Raised3D(
      onTap: onTap,
      filled: primary,
      radius: 14,
      depth: 5,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      semanticLabel: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: primary ? Colors.white : AppColors.neonBlueLight),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
