/// Route paths of G04Passwort (single source of truth).
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const setup = '/setup';
  static const login = '/login';

  // Shell branches (bottom navigation)
  static const dashboard = '/dashboard';
  static const categories = '/categories';
  static const generator = '/generator';
  static const more = '/more';

  // Vault
  static const vault = '/vault';
  static const newItem = '/vault/new';
  static String item(String id) => '/vault/item/$id';
  static String editItem(String id) => '/vault/edit/$id';
  static const history = '/history';

  // Features
  static const security = '/security';
  static const analysis = '/security/analysis';
  static const authenticator = '/authenticator';
  static const documents = '/documents';
  static const cards = '/cards';
  static const notes = '/notes';
  static const search = '/search';
  static const settings = '/settings';
  static const design = '/settings/design';
  static const autoSave = '/settings/autosave';
  static const profile = '/profile';
  static const changeMasterPassword = '/profile/master-password';
  static const backup = '/backup';
  static const sync = '/sync';
  static const about = '/about';

  /// Routes reachable without an unlocked vault.
  static const public = {splash, onboarding, setup, login};
}
