import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/biometric_service.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/neon_button.dart';
import '../../settings/application/settings_controller.dart';
import '../application/auth_controller.dart';

/// Sperrbildschirm.
///
/// * Face ID / Fingerabdruck aktiviert: die Prüfung startet sofort beim
///   Öffnen. Schlägt sie fehl oder wird sie abgebrochen, erscheint das
///   Master-Passwort-Feld und „Erneut mit Face ID versuchen“.
/// * Nicht aktiviert: direkt die Eingabe des Master-Passworts.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _password = TextEditingController();

  /// Face ID prompt is currently shown.
  bool _checking = false;

  /// Face ID failed or was cancelled at least once.
  bool _bioFailed = false;

  bool get _bioEnabled => ref.read(settingsControllerProvider).biometricEnabled;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (_bioEnabled && !auth.lockedManually) {
      _checking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_biometric());
      });
    }
  }

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  /// Starts Face ID / fingerprint. Keep the controller call first (no
  /// `await` before it): browsers need it inside the tap.
  Future<void> _biometric() async {
    final future = ref
        .read(authControllerProvider.notifier)
        .unlockWithBiometrics();
    setState(() => _checking = true);
    final ok = await future;
    if (!mounted || ok) return;
    setState(() {
      _checking = false;
      _bioFailed = true;
    });
  }

  Future<void> _unlock() async {
    if (_password.text.isEmpty) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .unlock(_password.text);
    if (ok) _password.clear();
  }

  Future<void> _forgot() async {
    final hint = ref.read(authControllerProvider).passwordHint;
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passwort vergessen?'),
        content: Text(
          '${hint == null || hint.isEmpty ? '' : 'Dein Hinweis: „$hint“\n\n'}'
          'G04Passwort ist Zero-Knowledge: Dein Master-Passwort wird nirgends gespeichert '
          'und kann nicht wiederhergestellt werden.\n\n'
          'Du kannst den Tresor zurücksetzen – dabei werden alle Daten gelöscht. '
          'Danach kannst du ein Backup wiederherstellen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Tresor zurücksetzen'),
          ),
        ],
      ),
    );
    if (reset != true || !mounted) return;
    final sure = await context.confirm(
      title: 'Wirklich alles löschen?',
      message:
          'Alle Einträge, Dokumente und Schlüssel werden unwiderruflich gelöscht.',
      confirmLabel: 'Endgültig löschen',
      destructive: true,
    );
    if (sure) await ref.read(authControllerProvider.notifier).resetVault();
  }

  String? _getRetryLabel(bool bioEnabled, String bioName) {
    if (!bioEnabled) return null;
    return _bioFailed
        ? 'Erneut mit $bioName versuchen'
        : 'Mit $bioName entsperren';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final bioEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.biometricEnabled),
    );
    final fingerprint = auth.biometricKind == BiometricKind.fingerprint;
    final bioName = fingerprint ? 'Fingerabdruck' : 'Face ID';
    final bioIcon = fingerprint
        ? Icons.fingerprint_rounded
        : Icons.face_retouching_natural_rounded;
    final checking = _checking && auth.error == null;

    final String subtitle;
    if (checking) {
      subtitle = 'Entsperren mit $bioName …';
    } else if (bioEnabled && _bioFailed) {
      subtitle =
          '$bioName nicht erkannt. Gib dein Master-Passwort ein '
          'oder versuche es erneut.';
    } else if (bioEnabled) {
      subtitle = 'Entsperre mit $bioName oder deinem Master-Passwort.';
    } else {
      subtitle = 'Gib dein Master-Passwort ein.';
    }

    return G04Scaffold(
      showAppBar: false,
      backgroundAsset: 'assets/images/bg_login.jpg',
      dim: 0.45,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const G04Logo(size: 104),
                const SizedBox(height: 18),
                Text(AppConstants.appName, style: context.text.headlineMedium),
                const SizedBox(height: 22),
                Text('Willkommen zurück!', style: context.text.titleLarge),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  child: checking
                      ? _BioScanner(key: const ValueKey('scan'), icon: bioIcon)
                      : _PasswordForm(
                          key: const ValueKey('form'),
                          controller: _password,
                          busy: auth.busy,
                          error: auth.error,
                          onUnlock: _unlock,
                          retryLabel: _getRetryLabel(bioEnabled, bioName),
                          retryIcon: bioIcon,
                          onRetry: auth.busy ? null : _biometric,
                          onForgot: _forgot,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Password entry with unlock, optional Face ID retry and "forgot".
class _PasswordForm extends StatelessWidget {
  const _PasswordForm({
    super.key,
    required this.controller,
    required this.busy,
    required this.error,
    required this.onUnlock,
    required this.retryLabel,
    required this.retryIcon,
    required this.onRetry,
    required this.onForgot,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onUnlock;
  final String? retryLabel;
  final IconData retryIcon;
  final VoidCallback? onRetry;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AutofillGroup(
          child: AppTextField(
            controller: controller,
            label: 'Master-Passwort',
            icon: Icons.lock_outline_rounded,
            isSecret: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onUnlock(),
          ),
        ),
        const SizedBox(height: 16),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ),
        NeonButton(label: 'Entsperren', loading: busy, onPressed: onUnlock),
        if (retryLabel != null) ...[
          const SizedBox(height: 14),
          NeonButton.outline(
            label: retryLabel!,
            icon: retryIcon,
            onPressed: onRetry,
          ),
        ],
        const SizedBox(height: 10),
        TextButton(
          onPressed: onForgot,
          child: const Text('Passwort vergessen?'),
        ),
      ],
    );
  }
}

/// Pulsing neon ring shown while Face ID / fingerprint is being checked.
class _BioScanner extends StatefulWidget {
  const _BioScanner({super.key, required this.icon});

  final IconData icon;

  @override
  State<_BioScanner> createState() => _BioScannerState();
}

class _BioScannerState extends State<_BioScanner>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF1B3D7A), Color(0xFF081430)],
                ),
                border: Border.all(
                  color: AppColors.neonBlueLight.withValues(alpha: 0.6 + 0.4 * t),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withValues(alpha: 0.35 + 0.35 * t),
                    blurRadius: 24 + 22 * t,
                    spreadRadius: 2 + 6 * t,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Icon(
            widget.icon,
            size: 68,
            color: AppColors.neonBlueLight,
            shadows: const [Shadow(color: AppColors.neonBlue, blurRadius: 18)],
          ),
        ),
      ),
    );
  }
}
