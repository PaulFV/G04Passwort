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
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../settings/application/settings_controller.dart';
import '../application/auth_controller.dart';

/// Login / Biometrie (design screen 2): "Willkommen zurück!", fingerprint
/// and face tiles, "Entsperren", "Passwort eingeben", "Passwort vergessen?".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Offer biometric unlock right away if enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(settingsControllerProvider).biometricEnabled) unawaited(_biometric());
    });
  }

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    final enabled = ref.read(settingsControllerProvider).biometricEnabled;
    if (!enabled) {
      setState(() => _showPassword = true);
      context.showSnack(
        'Biometrie ist noch nicht aktiviert. Entsperre mit dem Master-Passwort und aktiviere sie in den Einstellungen.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _unlock() async {
    if (!_showPassword) {
      if (ref.read(settingsControllerProvider).biometricEnabled) {
        await _biometric();
      } else {
        setState(() => _showPassword = true);
      }
      return;
    }
    if (_password.text.isEmpty) return;
    final ok = await ref.read(authControllerProvider.notifier).unlock(_password.text);
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
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
      message: 'Alle Einträge, Dokumente und Schlüssel werden unwiderruflich gelöscht.',
      confirmLabel: 'Endgültig löschen',
      destructive: true,
    );
    if (sure) await ref.read(authControllerProvider.notifier).resetVault();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final kind = auth.biometricKind;

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
                const SizedBox(height: 4),
                Text(
                  'Bitte authentifizieren Sie sich.',
                  style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BioTile(
                      icon: Icons.fingerprint_rounded,
                      label: 'Fingerabdruck',
                      highlighted: kind == BiometricKind.fingerprint,
                      onTap: auth.busy ? null : _biometric,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text('oder', style: context.text.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ),
                    _BioTile(
                      icon: Icons.face_retouching_natural_rounded,
                      label: 'Face ID',
                      highlighted: kind == BiometricKind.face,
                      onTap: auth.busy ? null : _biometric,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: _showPassword
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AutofillGroup(
                            child: AppTextField(
                              controller: _password,
                              label: 'Master-Passwort',
                              icon: Icons.lock_outline_rounded,
                              isSecret: true,
                              autofocus: true,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _unlock(),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      auth.error!,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  ),
                NeonButton(label: 'Entsperren', loading: auth.busy, onPressed: _unlock),
                const SizedBox(height: 14),
                if (!_showPassword)
                  NeonButton.outline(
                    label: 'Passwort eingeben',
                    onPressed: () => setState(() => _showPassword = true),
                  ),
                const SizedBox(height: 10),
                TextButton(onPressed: _forgot, child: const Text('Passwort vergessen?')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BioTile extends StatelessWidget {
  const _BioTile({required this.icon, required this.label, required this.onTap, this.highlighted = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GlassCard(
        onTap: onTap,
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        glowColor: highlighted ? AppColors.neonBlue : null,
        borderColor: AppColors.neonBlueLight.withValues(alpha: 0.7),
        child: Icon(
          icon,
          size: 40,
          color: AppColors.neonBlueLight,
          shadows: const [Shadow(color: AppColors.neonBlue, blurRadius: 14)],
        ),
      ),
    );
  }
}
