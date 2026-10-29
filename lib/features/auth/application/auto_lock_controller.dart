import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_controller.dart';
import 'auth_controller.dart';

/// Auto-lock logic: locks the vault after inactivity in the foreground and
/// after the app has been in the background for the configured time.
///
/// The state (`bool`) tells whether the privacy shield should cover the UI
/// (app inactive / in app switcher).
class AutoLockController extends Notifier<bool> {
  Timer? _timer;
  DateTime? _backgroundSince;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(authControllerProvider.select((s) => s.status), (_, status) {
      if (status == AuthStatus.unlocked) {
        onUserActivity();
      } else {
        _timer?.cancel();
      }
    });
    return false;
  }

  bool get _unlocked => ref.read(authControllerProvider).status == AuthStatus.unlocked;

  /// Called on every pointer/keyboard interaction – restarts the timer.
  void onUserActivity() {
    _timer?.cancel();
    final seconds = ref.read(settingsControllerProvider).autoLockSeconds;
    if (!_unlocked || seconds <= 0) return;
    _timer = Timer(Duration(seconds: seconds), _lock);
  }

  void onLifecycleChanged(AppLifecycleState lifecycle) {
    final settings = ref.read(settingsControllerProvider);
    switch (lifecycle) {
      case AppLifecycleState.inactive:
        state = settings.screenshotProtection && _unlocked;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        state = settings.screenshotProtection && _unlocked;
        _backgroundSince ??= DateTime.now();
        if (_unlocked && settings.lockOnBackground && settings.autoLockSeconds == 0) {
          _lock();
        }
      case AppLifecycleState.resumed:
        state = false;
        final since = _backgroundSince;
        _backgroundSince = null;
        if (since != null && _unlocked && settings.lockOnBackground && settings.autoLockSeconds >= 0) {
          final away = DateTime.now().difference(since).inSeconds;
          if (away >= settings.autoLockSeconds) {
            _lock();
            return;
          }
        }
        onUserActivity();
      case AppLifecycleState.detached:
        _lock();
    }
  }

  void _lock() {
    _timer?.cancel();
    ref.read(authControllerProvider.notifier).lock();
  }
}

final autoLockControllerProvider =
    NotifierProvider<AutoLockController, bool>(AutoLockController.new);
