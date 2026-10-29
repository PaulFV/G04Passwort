import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Original artwork from the asset sheet.
const String kAppIconAsset = 'assets/branding/app_icon.png';
const String kLogoAsset = 'assets/branding/logo.png';
const String kLogoMarkAsset = 'assets/branding/logo_mark.png';
const String kLock3dAsset = 'assets/branding/lock_3d.png';

/// The G04Passwort brand mark: the original 3D padlock icon from the design
/// board with a softly pulsing neon glow behind it.
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
    final size = widget.size;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonBlue.withValues(alpha: 0.35 + 0.3 * t),
                  blurRadius: size * (0.18 + 0.12 * t),
                  spreadRadius: size * 0.01,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            kAppIconAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
