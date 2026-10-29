import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'core/theme/app_colors.dart';
import 'repositories/settings_repository.dart';
import 'services/secure_storage_service.dart';

/// Entry point of G04Passwort.
///
/// Loads the (non-secret) settings before the first frame so theme and
/// onboarding state are available synchronously, then starts the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'de_DE';
  await initializeDateFormatting('de_DE');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDeep,
    ),
  );

  final storage = SecureStorageService();
  final settings = await SettingsRepositoryImpl(storage).load();

  runApp(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const G04PasswortApp(),
    ),
  );
}
