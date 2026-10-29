import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small UI helpers on [BuildContext].
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  bool get isWide => MediaQuery.sizeOf(this).width >= 840;

  /// Shows a themed snackbar.
  void showSnack(
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Color? color,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color ?? AppColors.cyan, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void showError(String message) => showSnack(
    message,
    icon: Icons.error_outline_rounded,
    color: AppColors.danger,
  );

  /// Simple confirmation dialog. Returns `true` if confirmed.
  Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Bestätigen',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size(0, 44),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
