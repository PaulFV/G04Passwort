import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Glossy "3D glass" icon tile with neon glow, modelled after the feature
/// icons of the G04Passwort design board (shield, fingerprint, cloud, …).
///
/// Layers (bottom → top): outer glow, gradient body, neon rim, glossy top
/// highlight, glowing icon.
class NeonIconTile extends StatelessWidget {
  const NeonIconTile({
    super.key,
    required this.icon,
    this.color = AppColors.neonBlue,
    this.size = 56,
    this.iconSize,
    this.glow = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final light = Color.lerp(color, Colors.white, 0.55)!;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            if (glow)
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: size * 0.35,
                spreadRadius: -size * 0.04,
              ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, const Color(0xFF0B1A3A), 0.45)!,
              const Color(0xFF071029),
            ],
          ),
          border: Border.all(color: light.withValues(alpha: 0.85), width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // glossy reflection on the upper half
              Positioned(
                top: -size * 0.35,
                left: -size * 0.2,
                right: -size * 0.2,
                height: size * 0.75,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Icon(
                icon,
                size: iconSize ?? size * 0.5,
                color: light,
                shadows: [
                  Shadow(color: color, blurRadius: size * 0.22),
                  Shadow(color: color.withValues(alpha: 0.8), blurRadius: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
