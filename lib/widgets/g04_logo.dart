import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The G04Passwort brand mark: a glossy 3D padlock engraved with "G04"
/// inside a glowing neon ring. Drawn with a [CustomPainter] so it stays
/// razor sharp at any size. With [animate] the ring gently pulses.
class G04Logo extends StatefulWidget {
  const G04Logo({super.key, this.size = 160, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<G04Logo> createState() => _G04LogoState();
}

class _G04LogoState extends State<G04Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _LogoPainter(
            pulse: Curves.easeInOut.transform(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);

    // --- glowing ring ------------------------------------------------------
    final ringR = s * 0.46;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..color = AppColors.neonBlue.withValues(alpha: 0.45 + 0.35 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * (0.04 + 0.03 * pulse));
    canvas.drawCircle(c, ringR, glowPaint);
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..shader = SweepGradient(
          colors: const [
            AppColors.cyan,
            AppColors.neonBlue,
            Color(0xFFBFE6FF),
            AppColors.neonBlue,
            AppColors.cyan,
          ],
          transform: GradientRotation(pulse * math.pi),
        ).createShader(Rect.fromCircle(center: c, radius: ringR)),
    );

    // --- shackle -----------------------------------------------------------
    final bodyW = s * 0.46;
    final bodyH = s * 0.36;
    final bodyTop = c.dy - bodyH * 0.12;
    final shackleR = bodyW * 0.30;
    final shackleW = s * 0.07;
    final shackleCenter = Offset(c.dx, bodyTop - shackleR * 0.55);
    final shacklePath = Path()
      ..moveTo(c.dx - shackleR, bodyTop + 4)
      ..lineTo(c.dx - shackleR, shackleCenter.dy)
      ..arcTo(
        Rect.fromCircle(center: shackleCenter, radius: shackleR),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(c.dx + shackleR, bodyTop + 4);
    final shackleRect = Rect.fromLTWH(
      c.dx - shackleR - shackleW,
      shackleCenter.dy - shackleR,
      (shackleR + shackleW) * 2,
      shackleR * 2,
    );
    canvas.drawPath(
      shacklePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shackleW
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF5A6E92),
            Color(0xFFEAF4FF),
            Color(0xFF8FA3C4),
            Color(0xFFEAF4FF),
            Color(0xFF5A6E92),
          ],
        ).createShader(shackleRect),
    );

    // --- body --------------------------------------------------------------
    final bodyRect = Rect.fromLTWH(c.dx - bodyW / 2, bodyTop, bodyW, bodyH);
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyW * 0.14));
    canvas.drawRRect(
      body.shift(Offset(0, s * 0.02)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.025),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9CC6F8), Color(0xFF3F74C8), Color(0xFF173A84)],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.008
        ..color = const Color(0xFFD7ECFF),
    );
    // glossy highlight
    final hl = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        bodyRect.left + bodyW * 0.07,
        bodyRect.top + bodyH * 0.06,
        bodyW * 0.86,
        bodyH * 0.28,
      ),
      Radius.circular(bodyW * 0.1),
    );
    canvas.drawRRect(hl, Paint()..color = Colors.white.withValues(alpha: 0.22));

    // --- engraved "G04" ----------------------------------------------------
    final tp = TextPainter(
      text: TextSpan(
        text: 'G04',
        style: TextStyle(
          fontSize: bodyH * 0.40,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: const Color(0xFFE8F6FF),
          shadows: [
            Shadow(color: AppColors.cyan, blurRadius: s * 0.03),
            Shadow(
              color: const Color(0xFF051434),
              offset: Offset(s * 0.004, s * 0.006),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(c.dx - tp.width / 2, bodyRect.top + bodyH * 0.56 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
