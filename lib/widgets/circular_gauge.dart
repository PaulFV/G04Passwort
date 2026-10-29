import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Glowing circular progress gauge used for the security score and the
/// TOTP countdown rings. [value] ranges from 0 to 1 and animates.
class CircularGauge extends StatelessWidget {
  const CircularGauge({
    super.key,
    required this.value,
    required this.color,
    this.size = 160,
    this.strokeWidth = 12,
    this.child,
    this.animate = true,
  });

  final double value;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _GaugePainter(value: v, color: color, stroke: strokeWidth),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.stroke,
  });

  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.12),
    );
    if (value <= 0) return;
    final sweep = math.pi * 2 * value;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi * 2,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(arcRect),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
