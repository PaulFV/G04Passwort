import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/auto_lock_controller.dart';
import '../features/settings/application/settings_controller.dart';
import '../widgets/g04_logo.dart';
import 'router.dart';

/// Root widget of G04Passwort.
class G04PasswortApp extends ConsumerWidget {
  const G04PasswortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final accent = ref.watch(accentColorProvider);
    final dark = ref.watch(
      settingsControllerProvider.select((s) => s.darkMode),
    );

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) =>
          _SecurityLayer(child: child ?? const SizedBox()),
    );
  }
}

/// Wraps the whole app: reports user activity to the auto-lock timer,
/// forwards lifecycle changes and shows the privacy shield while the app
/// is inactive (hides content in the app switcher / screenshots).
class _SecurityLayer extends ConsumerStatefulWidget {
  const _SecurityLayer({required this.child});

  final Widget child;

  @override
  ConsumerState<_SecurityLayer> createState() => _SecurityLayerState();
}

class _SecurityLayerState extends ConsumerState<_SecurityLayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      ref.read(autoLockControllerProvider.notifier).onLifecycleChanged(state);

  @override
  Widget build(BuildContext context) {
    final shield = ref.watch(autoLockControllerProvider);
    final autoLock = ref.read(autoLockControllerProvider.notifier);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => autoLock.onUserActivity(),
      onPointerSignal: (_) => autoLock.onUserActivity(),
      onPointerHover: (_) => autoLock.onUserActivity(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, _) {
          autoLock.onUserActivity();
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            widget.child,
            if (shield) const Positioned.fill(child: _PrivacyShield()),
          ],
        ),
      ),
    );
  }
}

class _PrivacyShield extends StatelessWidget {
  const _PrivacyShield();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.92),
        child: const Center(child: G04Logo(size: 120, animate: false)),
      ),
    );
  }
}
