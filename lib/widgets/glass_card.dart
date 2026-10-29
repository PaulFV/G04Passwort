import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Frosted-glass container with a subtle neon border – the core surface of
/// the G04Passwort design language.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.onTap,
    this.borderRadius = AppSpacing.radius,
    this.glowColor,
    this.borderColor,
    this.blur = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;

  /// Optional outer glow (e.g. for highlighted cards).
  final Color? glowColor;
  final Color? borderColor;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final border = borderColor ??
        (isDark ? AppColors.glassBorder : const Color(0x332F8CFF));

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: border, width: 1),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xB3132B5C), Color(0x990A1530)]
                        : [
                            Colors.white.withValues(alpha: 0.92),
                            Colors.white.withValues(alpha: 0.75),
                          ],
                  ),
                ),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
