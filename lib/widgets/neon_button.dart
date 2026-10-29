import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Primary call-to-action: gradient pill with neon glow.
/// Use [NeonButton.outline] for the secondary (outlined) variant.
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  }) : outlined = false;

  const NeonButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  }) : outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  /// Overrides the theme accent (e.g. red for destructive actions).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(AppSpacing.radiusSmall + 2);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: outlined ? accent : Colors.white),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: outlined
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: outlined ? null : AppColors.primaryGradient(accent),
          color: outlined ? AppColors.glass.withValues(alpha: 0.4) : null,
          border: Border.all(
            color: outlined
                ? accent.withValues(alpha: 0.8)
                : Color.lerp(accent, Colors.white, 0.4)!,
            width: outlined ? 1.4 : 1,
          ),
          boxShadow: [
            if (!outlined && enabled)
              BoxShadow(
                color: accent.withValues(alpha: 0.55),
                blurRadius: 22,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
