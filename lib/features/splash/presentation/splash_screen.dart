import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/g04_logo.dart';

/// Splash (design: logo with glow above the glowing earth horizon).
/// Navigation happens automatically through the router redirect once the
/// auth state is resolved.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/bg_splash.jpg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.backgroundDeep, Color(0x0002040C)],
                stops: [0.45, 0.75],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutBack,
                  builder: (context, v, child) => Opacity(
                    opacity: ((v - 0.6) / 0.4).clamp(0, 1),
                    child: Transform.scale(scale: v, child: child),
                  ),
                  child: Image.asset(
                    kLogoAsset,
                    width: 260,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Spacer(flex: 4),
                const SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.cyan,
                    backgroundColor: Color(0x332F8CFF),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'v${AppConstants.version}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
