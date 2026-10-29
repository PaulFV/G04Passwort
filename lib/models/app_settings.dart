import 'package:flutter/foundation.dart';

/// Available background artworks (Design & Personalisierung).
/// Selectable backgrounds – artwork taken 1:1 from the design files
/// (docs/design/asset_sheet.png & design_board.png).
enum AppBackgroundStyle {
  dashboard('Wellen', 'assets/images/bg_dashboard.jpg'),
  login('Horizont', 'assets/images/bg_login.jpg'),
  earth('Erde', 'assets/images/bg_earth.jpg'),
  mountains('Berge', 'assets/images/bg_mountains.jpg'),
  summit('Gipfel', 'assets/images/bg_summit.jpg'),
  waves('Glow', 'assets/images/bg_waves.jpg'),
  shield('Schild', 'assets/images/bg_shield.jpg'),
  flow('Flow', 'assets/images/bg_flow.jpg'),
  circuit('Circuit', 'assets/images/bg_circuit.jpg'),
  hex('Hexagon', 'assets/images/bg_hex.jpg'),
  curve('Kurve', 'assets/images/bg_curve.jpg');

  const AppBackgroundStyle(this.label, this.asset);

  final String label;
  final String asset;
}

/// User preferences. Non-secret, stored as JSON in secure storage so they
/// are readable before the vault is unlocked.
@immutable
class AppSettings {
  const AppSettings({
    this.onboardingDone = false,
    this.darkMode = true,
    this.accentIndex = 0,
    this.background = AppBackgroundStyle.dashboard,
    this.autoLockSeconds = 30,
    this.lockOnBackground = true,
    this.clipboardClearSeconds = 30,
    this.biometricEnabled = false,
    this.screenshotProtection = true,
    this.autoSaveEnabled = false,
    this.languageCode = 'de',
    this.displayName = '',
    this.email = '',
    this.syncProviders = const {},
    this.lastBackupAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        onboardingDone: j['onboardingDone'] as bool? ?? false,
        darkMode: j['darkMode'] as bool? ?? true,
        accentIndex: j['accentIndex'] as int? ?? 0,
        background: AppBackgroundStyle.values.firstWhere(
          (b) => b.name == j['background'],
          orElse: () => AppBackgroundStyle.dashboard,
        ),
        autoLockSeconds: j['autoLockSeconds'] as int? ?? 30,
        lockOnBackground: j['lockOnBackground'] as bool? ?? true,
        clipboardClearSeconds: j['clipboardClearSeconds'] as int? ?? 30,
        biometricEnabled: j['biometricEnabled'] as bool? ?? false,
        screenshotProtection: j['screenshotProtection'] as bool? ?? true,
        autoSaveEnabled: j['autoSaveEnabled'] as bool? ?? false,
        languageCode: j['languageCode'] as String? ?? 'de',
        displayName: j['displayName'] as String? ?? '',
        email: j['email'] as String? ?? '',
        syncProviders: (j['syncProviders'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as bool)),
        lastBackupAt: j['lastBackupAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['lastBackupAt'] as int),
      );

  /// Selectable auto-lock delays in seconds (0 = immediately, -1 = never).
  static const autoLockOptions = [0, 30, 60, 300, 900, -1];

  /// Selectable clipboard clear delays in seconds (-1 = never).
  static const clipboardOptions = [15, 30, 60, 120, -1];

  final bool onboardingDone;
  final bool darkMode;
  final int accentIndex;
  final AppBackgroundStyle background;
  final int autoLockSeconds;
  final bool lockOnBackground;
  final int clipboardClearSeconds;
  final bool biometricEnabled;
  final bool screenshotProtection;
  final bool autoSaveEnabled;
  final String languageCode;
  final String displayName;
  final String email;

  /// Enabled state per cloud sync provider id.
  final Map<String, bool> syncProviders;
  final DateTime? lastBackupAt;

  static String durationLabel(int seconds) {
    if (seconds < 0) return 'Nie';
    if (seconds == 0) return 'Sofort';
    if (seconds < 60) return '$seconds Sekunden';
    final m = seconds ~/ 60;
    return m == 1 ? '1 Minute' : '$m Minuten';
  }

  AppSettings copyWith({
    bool? onboardingDone,
    bool? darkMode,
    int? accentIndex,
    AppBackgroundStyle? background,
    int? autoLockSeconds,
    bool? lockOnBackground,
    int? clipboardClearSeconds,
    bool? biometricEnabled,
    bool? screenshotProtection,
    bool? autoSaveEnabled,
    String? languageCode,
    String? displayName,
    String? email,
    Map<String, bool>? syncProviders,
    DateTime? lastBackupAt,
  }) =>
      AppSettings(
        onboardingDone: onboardingDone ?? this.onboardingDone,
        darkMode: darkMode ?? this.darkMode,
        accentIndex: accentIndex ?? this.accentIndex,
        background: background ?? this.background,
        autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
        lockOnBackground: lockOnBackground ?? this.lockOnBackground,
        clipboardClearSeconds: clipboardClearSeconds ?? this.clipboardClearSeconds,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        screenshotProtection: screenshotProtection ?? this.screenshotProtection,
        autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
        languageCode: languageCode ?? this.languageCode,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        syncProviders: syncProviders ?? this.syncProviders,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );

  Map<String, dynamic> toJson() => {
        'onboardingDone': onboardingDone,
        'darkMode': darkMode,
        'accentIndex': accentIndex,
        'background': background.name,
        'autoLockSeconds': autoLockSeconds,
        'lockOnBackground': lockOnBackground,
        'clipboardClearSeconds': clipboardClearSeconds,
        'biometricEnabled': biometricEnabled,
        'screenshotProtection': screenshotProtection,
        'autoSaveEnabled': autoSaveEnabled,
        'languageCode': languageCode,
        'displayName': displayName,
        'email': email,
        'syncProviders': syncProviders,
        if (lastBackupAt != null) 'lastBackupAt': lastBackupAt!.millisecondsSinceEpoch,
      };
}
