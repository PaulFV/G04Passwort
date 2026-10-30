import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/generator_options.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/strength_meter.dart';
import '../../vault/application/vault_providers.dart';
import '../application/generator_controller.dart';

/// Passwort-Generator (design screen 5).
class GeneratorScreen extends ConsumerWidget {
  const GeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generatorControllerProvider);
    final controller = ref.read(generatorControllerProvider.notifier);
    final o = state.options;
    final strength = ref.watch(passwordStrengthProvider(state.password));

    Future<void> copy(String value) async {
      final ok = await ref.read(vaultActionsProvider).copy(value);
      if (!context.mounted) return;
      ok ? context.showSnack('Passwort kopiert') : context.showError(kCopyFailed);
    }

    return G04Scaffold(
      title: 'Passwort-Generator',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          GlassCard(
            glowColor: AppColors.neonBlue,
            borderColor: AppColors.neonBlueLight,
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, a) =>
                        FadeTransition(opacity: a, child: c),
                    child: SelectableText(
                      state.password,
                      key: ValueKey(state.password),
                      style: context.text.titleLarge?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kopieren',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => copy(state.password),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StrengthMeter(strength: strength),
                const SizedBox(height: 6),
                Text(
                  'Knackzeit (offline): ${strength.crackTimeLabel} · ${strength.entropyBits.round()} Bit',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<GeneratorMode>(
            segments: [
              for (final m in GeneratorMode.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {o.mode},
            onSelectionChanged: (s) =>
                controller.update((o) => o.copyWith(mode: s.first)),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              children: [
                if (o.mode == GeneratorMode.passphrase) ...[
                  _SliderRow(
                    label: 'Wörter',
                    value: o.wordCount,
                    min: 3,
                    max: 10,
                    onChanged: (v) =>
                        controller.update((o) => o.copyWith(wordCount: v)),
                  ),
                  _Toggle(
                    icon: Icons.text_fields_rounded,
                    label: 'Wörter großschreiben',
                    value: o.capitalizeWords,
                    onChanged: (v) => controller.update(
                      (o) => o.copyWith(capitalizeWords: v),
                    ),
                  ),
                  _Toggle(
                    icon: Icons.pin_outlined,
                    label: 'Zahl einfügen',
                    value: o.includeNumber,
                    onChanged: (v) =>
                        controller.update((o) => o.copyWith(includeNumber: v)),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.horizontal_rule_rounded,
                        color: AppColors.neonBlueLight,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Trennzeichen')),
                      for (final sep in const ['-', '.', '_', ' '])
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(sep == ' ' ? '␣' : sep),
                            selected: o.separator == sep,
                            onSelected: (_) => controller.update(
                              (o) => o.copyWith(separator: sep),
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  _SliderRow(
                    label: 'Länge',
                    value: o.length,
                    min: o.mode == GeneratorMode.pin
                        ? 4
                        : GeneratorOptions.minLength,
                    max: o.mode == GeneratorMode.pin
                        ? 12
                        : GeneratorOptions.maxLength,
                    onChanged: (v) =>
                        controller.update((o) => o.copyWith(length: v)),
                  ),
                  if (o.mode == GeneratorMode.password) ...[
                    _Toggle(
                      icon: Icons.keyboard_capslock_rounded,
                      label: 'Großbuchstaben (A-Z)',
                      value: o.uppercase,
                      onChanged: (v) =>
                          controller.update((o) => o.copyWith(uppercase: v)),
                    ),
                    _Toggle(
                      icon: Icons.text_fields_rounded,
                      label: 'Kleinbuchstaben (a-z)',
                      value: o.lowercase,
                      onChanged: (v) =>
                          controller.update((o) => o.copyWith(lowercase: v)),
                    ),
                    _Toggle(
                      icon: Icons.looks_one_outlined,
                      label: 'Zahlen (0-9)',
                      value: o.digits,
                      onChanged: (v) =>
                          controller.update((o) => o.copyWith(digits: v)),
                    ),
                    _Toggle(
                      icon: Icons.tag_rounded,
                      label: 'Sonderzeichen (!@#…)',
                      value: o.symbols,
                      onChanged: (v) =>
                          controller.update((o) => o.copyWith(symbols: v)),
                    ),
                    _Toggle(
                      icon: Icons.visibility_off_outlined,
                      label: 'Ähnliche Zeichen vermeiden (l, 1, O, 0)',
                      value: o.excludeAmbiguous,
                      onChanged: (v) => controller.update(
                        (o) => o.copyWith(excludeAmbiguous: v),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          NeonButton(
            label: 'Neues Passwort generieren',
            icon: Icons.autorenew_rounded,
            onPressed: controller.regenerate,
          ),
          if (state.history.isNotEmpty) ...[
            const SectionHeader('Zuletzt generiert'),
            for (final p in state.history.take(5))
              GlassTile(
                title: p,
                icon: Icons.history_rounded,
                trailing: IconButton(
                  tooltip: 'Kopieren',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () => copy(p),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: context.text.titleSmall),
            const Spacer(),
            Text(
              '$value',
              style: context.text.titleMedium?.copyWith(
                color: AppColors.neonBlueLight,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
      secondary: Icon(icon, color: AppColors.neonBlueLight),
      title: Text(label),
    );
  }
}
