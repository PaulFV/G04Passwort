import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_settings.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../application/settings_controller.dart';

/// Design & Personalisierung (design screen 17): theme, accent colour and
/// background artwork.
class DesignScreen extends ConsumerWidget {
  const DesignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final c = ref.read(settingsControllerProvider.notifier);

    return G04Scaffold(
      title: 'Design',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(6),
            borderRadius: 30,
            child: Row(
              children: [
                for (final dark in const [false, true])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => c.setDarkMode(dark),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: s.darkMode == dark
                              ? context.colors.primary
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              dark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(dark ? 'Dunkel' : 'Hell'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader('Hintergrund'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
            children: [
              for (final bg in AppBackgroundStyle.values)
                _BackgroundTile(
                  style: bg,
                  selected: s.background == bg,
                  onTap: () => c.setBackground(bg),
                ),
            ],
          ),
          const SectionHeader('Akzentfarbe'),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < AppColors.accents.length; i++)
                Semantics(
                  button: true,
                  selected: s.accentIndex == i,
                  label: 'Akzentfarbe ${i + 1}',
                  child: GestureDetector(
                    onTap: () => c.setAccent(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accents[i],
                        border: Border.all(
                          color: Colors.white,
                          width: s.accentIndex == i ? 3 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accents[i].withValues(
                              alpha: s.accentIndex == i ? 0.8 : 0.35,
                            ),
                            blurRadius: s.accentIndex == i ? 18 : 8,
                          ),
                        ],
                      ),
                      child: s.accentIndex == i
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AppBackgroundStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : AppColors.glassBorder,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 16),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(style.asset, fit: BoxFit.cover, cacheWidth: 300),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.black54,
                  child: Text(
                    style.label,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (selected)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
