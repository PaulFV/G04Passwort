import 'package:flutter/material.dart';

/// Central colour palette of the G04Passwort design language
/// ("Night Glass": deep night blue, neon blue glow, cyan highlights).
abstract final class AppColors {
  // --- Backgrounds ---------------------------------------------------------
  static const Color background = Color(0xFF050A1A);
  static const Color backgroundDeep = Color(0xFF02040C);
  static const Color surface = Color(0xFF0B1A3A);
  static const Color surfaceHigh = Color(0xFF12254D);

  /// Translucent fill used by glass cards.
  static const Color glass = Color(0x990C1C40);
  static const Color glassStrong = Color(0xCC0E2148);

  // --- Neon accents --------------------------------------------------------
  static const Color neonBlue = Color(0xFF2F8CFF);
  static const Color neonBlueLight = Color(0xFF62AEFF);
  static const Color cyan = Color(0xFF38D6FF);
  static const Color glassBorder = Color(0x664FA3FF);

  // --- Semantic ------------------------------------------------------------
  static const Color success = Color(0xFF2EE59D);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color info = cyan;

  // --- Text ----------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF2F7FF);
  static const Color textSecondary = Color(0xFF9FB3D9);
  static const Color textMuted = Color(0xFF6A7FA8);

  /// Selectable accent colours (Design & Personalisierung).
  static const List<Color> accents = [
    neonBlue,
    Color(0xFF2EE59D),
    Color(0xFFFFC857),
    Color(0xFF38D6FF),
    Color(0xFFA26BFF),
    Color(0xFFFF5C93),
  ];

  /// Gradient for primary call-to-action buttons.
  static LinearGradient primaryGradient(Color accent) => LinearGradient(
        colors: [
          Color.lerp(accent, Colors.white, 0.18)!,
          accent,
          Color.lerp(accent, Colors.black, 0.25)!,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
