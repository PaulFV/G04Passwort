import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/master_password_screen.dart';
import '../features/authenticator/presentation/authenticator_screen.dart';
import '../features/backup/presentation/backup_screen.dart';
import '../features/cards/presentation/cards_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/generator/presentation/generator_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/security/presentation/password_analysis_screen.dart';
import '../features/security/presentation/security_center_screen.dart';
import '../features/settings/presentation/autosave_screen.dart';
import '../features/settings/presentation/design_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/sync/presentation/cloud_sync_screen.dart';
import '../features/vault/presentation/history_screen.dart';
import '../features/vault/presentation/item_detail_screen.dart';
import '../features/vault/presentation/item_editor_screen.dart';
import '../features/vault/presentation/password_list_screen.dart';
import '../models/item_category.dart';
import '../models/vault_item_type.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds a fade-through page for a smooth, premium feel.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );

/// The app router. Redirects are driven by [authControllerProvider]: the
/// vault screens are only reachable while the vault is unlocked.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(
    authControllerProvider.select((s) => s.status),
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  GoRoute page(String path, Widget Function(GoRouterState s) builder) =>
      GoRoute(
        path: path,
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _fade(state, builder(state)),
      );

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      String? target(String path) => loc == path ? null : path;
      switch (status) {
        case AuthStatus.initializing:
          return target(Routes.splash);
        case AuthStatus.onboarding:
          return target(Routes.onboarding);
        case AuthStatus.setup:
          return target(Routes.setup);
        case AuthStatus.locked:
          return target(Routes.login);
        case AuthStatus.unlocked:
          return Routes.public.contains(loc) ? Routes.dashboard : null;
      }
    },
    routes: [
      page(Routes.splash, (_) => const SplashScreen()),
      page(Routes.onboarding, (_) => const OnboardingScreen()),
      page(Routes.setup, (_) => const MasterPasswordScreen()),
      page(Routes.login, (_) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.categories,
                builder: (_, _) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.generator,
                builder: (_, _) => const GeneratorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.more, builder: (_, _) => const MoreScreen()),
            ],
          ),
        ],
      ),
      page(
        Routes.vault,
        (s) => PasswordListScreen(
          category: s.uri.queryParameters['category'] == null
              ? null
              : ItemCategory.fromName(s.uri.queryParameters['category']),
          favoritesOnly: s.uri.queryParameters['filter'] == 'favorites',
          folderId: s.uri.queryParameters['folder'],
          tag: s.uri.queryParameters['tag'],
        ),
      ),
      page(
        Routes.newItem,
        (s) => ItemEditorScreen(
          type: VaultItemType.fromName(s.uri.queryParameters['type']),
          category: s.uri.queryParameters['category'] == null
              ? null
              : ItemCategory.fromName(s.uri.queryParameters['category']),
        ),
      ),
      page(
        '/vault/item/:id',
        (s) => ItemDetailScreen(itemId: s.pathParameters['id']!),
      ),
      page(
        '/vault/edit/:id',
        (s) => ItemEditorScreen(itemId: s.pathParameters['id']),
      ),
      page(Routes.history, (_) => const HistoryScreen()),
      page(Routes.security, (_) => const SecurityCenterScreen()),
      page(Routes.analysis, (_) => const PasswordAnalysisScreen()),
      page(Routes.authenticator, (_) => const AuthenticatorScreen()),
      page(Routes.documents, (_) => const DocumentsScreen()),
      page(Routes.cards, (_) => const CardsScreen()),
      page(Routes.notes, (_) => const NotesScreen()),
      page(Routes.search, (_) => const SearchScreen()),
      page(Routes.settings, (_) => const SettingsScreen()),
      page(Routes.design, (_) => const DesignScreen()),
      page(Routes.autoSave, (_) => const AutoSaveScreen()),
      page(Routes.profile, (_) => const ProfileScreen()),
      page(
        Routes.changeMasterPassword,
        (_) => const MasterPasswordScreen(changeMode: true),
      ),
      page(Routes.backup, (_) => const BackupScreen()),
      page(Routes.sync, (_) => const CloudSyncScreen()),
      page(Routes.about, (_) => const AboutScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
