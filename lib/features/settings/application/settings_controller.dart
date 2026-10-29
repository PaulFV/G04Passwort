import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_settings.dart';

/// Holds and persists the user's [AppSettings].
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> completeOnboarding() => _update(state.copyWith(onboardingDone: true));

  Future<void> setDarkMode(bool dark) => _update(state.copyWith(darkMode: dark));

  Future<void> setAccent(int index) => _update(state.copyWith(accentIndex: index));

  Future<void> setBackground(AppBackgroundStyle bg) => _update(state.copyWith(background: bg));

  Future<void> setAutoLock(int seconds) => _update(state.copyWith(autoLockSeconds: seconds));

  Future<void> setLockOnBackground(bool value) => _update(state.copyWith(lockOnBackground: value));

  Future<void> setClipboardClear(int seconds) =>
      _update(state.copyWith(clipboardClearSeconds: seconds));

  Future<void> setBiometricFlag(bool enabled) => _update(state.copyWith(biometricEnabled: enabled));

  Future<void> setScreenshotProtection(bool enabled) async {
    await ref.read(screenProtectionProvider).setEnabled(enabled);
    await _update(state.copyWith(screenshotProtection: enabled));
  }

  Future<void> setAutoSave(bool enabled) => _update(state.copyWith(autoSaveEnabled: enabled));

  Future<void> setProfile({required String name, required String email}) =>
      _update(state.copyWith(displayName: name.trim(), email: email.trim()));

  Future<void> setSyncProvider(String id, bool enabled) =>
      _update(state.copyWith(syncProviders: {...state.syncProviders, id: enabled}));

  Future<void> markBackupDone() => _update(state.copyWith(lastBackupAt: DateTime.now()));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Current accent colour (Design & Personalisierung).
final accentColorProvider = Provider<Color>((ref) {
  final index = ref.watch(settingsControllerProvider.select((s) => s.accentIndex));
  return AppColors.accents[index.clamp(0, AppColors.accents.length - 1)];
});

/// Duration after which copied secrets are wiped from the clipboard.
final clipboardClearDurationProvider = Provider<Duration?>((ref) {
  final s = ref.watch(settingsControllerProvider.select((s) => s.clipboardClearSeconds));
  return s < 0 ? null : Duration(seconds: s);
});
