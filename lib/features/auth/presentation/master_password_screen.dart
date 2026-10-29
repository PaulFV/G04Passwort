import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/strength_meter.dart';
import '../../../widgets/success_dialog.dart';
import '../../generator/application/generator_controller.dart';
import '../application/auth_controller.dart';

/// Master Passwort – create a new vault ([changeMode] = false) or change
/// the existing master password ([changeMode] = true).
class MasterPasswordScreen extends ConsumerStatefulWidget {
  const MasterPasswordScreen({super.key, this.changeMode = false});

  final bool changeMode;

  @override
  ConsumerState<MasterPasswordScreen> createState() =>
      _MasterPasswordScreenState();
}

class _MasterPasswordScreenState extends ConsumerState<MasterPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _hint = TextEditingController();
  bool _understood = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_current, _password, _confirm, _hint]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < AppConstants.minMasterPasswordLength) {
      return 'Mindestens ${AppConstants.minMasterPasswordLength} Zeichen';
    }
    if (ref.read(passwordStrengthProvider(value)).score < 2) {
      return 'Bitte wähle ein stärkeres Passwort';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!widget.changeMode && !_understood) {
      context.showError('Bitte bestätige den Hinweis zur Wiederherstellung.');
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    if (widget.changeMode) {
      final error = await controller.changeMasterPassword(
        _current.text,
        _password.text,
        hint: _hint.text.trim(),
      );
      if (!mounted) return;
      if (error != null) {
        context.showError(error);
        return;
      }
      await showSuccessDialog(
        context,
        message: 'Dein Master-Passwort wurde geändert.',
      );
      if (mounted) context.pop();
    } else {
      await controller.createVault(_password.text, hint: _hint.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final strength = ref.watch(passwordStrengthProvider(_password.text));

    return G04Scaffold(
      title: widget.changeMode ? 'Master-Passwort ändern' : null,
      showAppBar: widget.changeMode,
      backgroundAsset: widget.changeMode ? null : 'assets/images/bg_login.jpg',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.changeMode) ...[
                    const Center(child: G04Logo(size: 96)),
                    const SizedBox(height: 18),
                    Text(
                      'Master-Passwort erstellen',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Das einzige Passwort, das du dir merken musst. Es verschlüsselt deinen gesamten Tresor.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.changeMode) ...[
                          AppTextField(
                            controller: _current,
                            label: 'Aktuelles Master-Passwort',
                            icon: Icons.lock_clock_outlined,
                            isSecret: true,
                            validator: (v) =>
                                (v ?? '').isEmpty ? 'Bitte eingeben' : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        AppTextField(
                          controller: _password,
                          label: widget.changeMode
                              ? 'Neues Master-Passwort'
                              : 'Master-Passwort',
                          icon: Icons.lock_outline_rounded,
                          isSecret: true,
                          validator: _validatePassword,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 12),
                        StrengthMeter(strength: strength),
                        if (strength.feedback.isNotEmpty &&
                            _password.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              strength.feedback.first,
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _confirm,
                          label: 'Passwort bestätigen',
                          icon: Icons.verified_user_outlined,
                          isSecret: true,
                          validator: (v) => v != _password.text
                              ? 'Passwörter stimmen nicht überein'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _hint,
                          label: 'Hinweis (optional, unverschlüsselt)',
                          icon: Icons.lightbulb_outline_rounded,
                          validator: (v) =>
                              (v ?? '').isNotEmpty &&
                                  _password.text.contains(v!)
                              ? 'Der Hinweis darf das Passwort nicht enthalten'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (!widget.changeMode) ...[
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: _understood,
                      onChanged: (v) =>
                          setState(() => _understood = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Ich verstehe, dass mein Master-Passwort nicht wiederhergestellt werden kann.',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  NeonButton(
                    label: widget.changeMode
                        ? 'Passwort ändern'
                        : 'Tresor erstellen',
                    icon: Icons.shield_rounded,
                    loading: auth.busy,
                    onPressed: _submit,
                  ),
                  if (auth.busy)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Schlüssel wird sicher abgeleitet …',
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
