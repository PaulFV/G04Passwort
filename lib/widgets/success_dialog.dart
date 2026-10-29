import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_colors.dart';
import 'glass_card.dart';
import 'neon_button.dart';

/// "Erledigt!" confirmation with an animated check (Lottie).
Future<void> showSuccessDialog(
  BuildContext context, {
  String title = 'Erledigt!',
  String message = 'Ihr Passwort wurde sicher gespeichert.',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Schließen',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (context, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
    pageBuilder: (context, _, _) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            glowColor: AppColors.success,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 110,
                  child: Lottie.asset(
                    'assets/lottie/success_check.json',
                    repeat: false,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.check_circle_rounded,
                      size: 96,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 22),
                NeonButton(label: 'OK', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
