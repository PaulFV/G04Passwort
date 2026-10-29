import 'package:flutter/material.dart';

import '../models/password_strength.dart';

/// Animated, glowing bar visualising a [PasswordStrength].
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({
    super.key,
    required this.strength,
    this.showLabel = true,
  });

  final PasswordStrength strength;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = strength.level.color;
    final fraction = strength.isEmpty ? 0.0 : (strength.score + 1) / 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('Stärke', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  child: Text(strength.isEmpty ? '–' : strength.level.label),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                height: 7,
                width: c.maxWidth * fraction,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.7), color],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
