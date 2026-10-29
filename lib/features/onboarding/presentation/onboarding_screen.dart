import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/neon_button.dart';
import '../../auth/application/auth_controller.dart';

/// First-start onboarding: welcome screen (design "Splash Screen" with
/// "Los geht's" / "Anmelden") followed by three feature slides.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      ref.read(authControllerProvider.notifier).completeOnboarding();
    }
  }

  void _finish() =>
      ref.read(authControllerProvider.notifier).completeOnboarding();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(
            asset: 'assets/images/bg_login.jpg',
            dim: 0.35,
            alignment: Alignment.center,
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _page == 0 ? 0 : 1,
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text('Überspringen'),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (p) => setState(() => _page = p),
                    children: [
                      const _Welcome(),
                      _Slide(
                        image: Image.asset(kLock3dAsset, height: 220),
                        title: 'Maximale Sicherheit',
                        text:
                            'Alle Daten werden lokal mit AES-256-GCM verschlüsselt. '
                            'Dein Master-Passwort wird mit Argon2id geschützt und verlässt nie dein Gerät.',
                      ),
                      const _Slide(
                        image: _IconRow(
                          icons: [
                            FeatureIcon.biometric,
                            FeatureIcon.security,
                            FeatureIcon.totp,
                          ],
                        ),
                        title: 'Schnell & komfortabel',
                        text:
                            'Entsperre mit Fingerabdruck oder Face ID. Auto-Lock, Zwischenablage-Löschung '
                            'und Screenshot-Schutz arbeiten automatisch für dich.',
                      ),
                      const _Slide(
                        image: _IconGrid(),
                        title: 'Alles an einem Ort',
                        text:
                            'Passwörter, 2FA-Codes, Kreditkarten, Dokumente und sichere Notizen – '
                            'auch Zugänge zu Geräten, HMIs, Routern und Portalen.',
                      ),
                    ],
                  ),
                ),
                _Dots(count: _slides, index: _page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: NeonButton(
                    label: _page == _slides - 1
                        ? 'Jetzt starten'
                        : 'Los geht\'s',
                    onPressed: _next,
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: _page == 0
                      ? TextButton(
                          onPressed: _finish,
                          child: const Text('Anmelden'),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Image.asset(
              kLogoAsset,
              width: 280,
              filterQuality: FilterQuality.high,
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.image, required this.title, required this.text});

  final Widget image;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              image,
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: 14),
              Text(
                text,
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icons});

  final List<FeatureIcon> icons;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final i in icons)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                FeatureIconImage(i, size: 84),
                const SizedBox(height: 8),
                Text(i.label, style: context.text.labelMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid();

  @override
  Widget build(BuildContext context) {
    const icons = [
      FeatureIcon.passwords,
      FeatureIcon.totp,
      FeatureIcon.cards,
      FeatureIcon.documents,
      FeatureIcon.notes,
      FeatureIcon.generator,
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: [for (final i in icons) FeatureIconImage(i, size: 76)],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: i == index
                  ? AppColors.cyan
                  : AppColors.textMuted.withValues(alpha: 0.5),
              boxShadow: [
                if (i == index)
                  const BoxShadow(color: AppColors.cyan, blurRadius: 8),
              ],
            ),
          ),
      ],
    );
  }
}
