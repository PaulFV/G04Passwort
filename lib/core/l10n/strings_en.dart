/// English translations, keyed by the German source text.
///
/// Placeholders in `{braces}` must be kept. Generated from the German
/// texts in lib/ – `test/l10n/translations_test.dart` checks completeness.
const Map<String, String> kEn = {
  'Start':
      'Home',
  'Kategorien':
      'Categories',
  'Generator':
      'Generator',
  'Mehr':
      'More',
  'Neuer Eintrag':
      'New entry',
  'Neuer Eintrag (Strg+N)':
      'New entry (Ctrl+N)',
  'Suche (Strg+K)':
      'Search (Ctrl+K)',
  'Tresor sperren (Strg+L)':
      'Lock vault (Ctrl+L)',
  '© 2026 PaulFV · Alle Rechte vorbehalten':
      '© 2026 PaulFV · All rights reserved',
  'Kopieren nicht möglich – Zwischenablage ist blockiert.':
      'Copying not possible – the clipboard is blocked.',
  'Abbrechen':
      'Cancel',
  'Bestätigen':
      'Confirm',
  'Entsperren mit {bio} …':
      'Unlocking with {bio} …',
  'Über':
      'About',
  'Version {version} ({buildNumber})':
      'Version {version} ({buildNumber})',
  'Sicherheitsarchitektur':
      'Security architecture',
  '• Zero-Knowledge: Alle Daten werden ausschließlich lokal ver- und entschlüsselt.\n• AES-256-GCM (authentifizierte Verschlüsselung) für jeden Eintrag, Ordner und jede Datei.\n• Argon2id (19 MiB, t=2) leitet den Schlüssel aus dem Master-Passwort ab; PBKDF2-SHA256 als Fallback.\n• Zufälliger 256-Bit-Tresorschlüssel, gekapselt mit dem Master-Schlüssel.\n• Schlüssel nur im Arbeitsspeicher; Auto-Lock, Zwischenablage-Löschung, Screenshot-Schutz.':
      '• Zero knowledge: all data is encrypted and decrypted exclusively on your device.\n• AES-256-GCM (authenticated encryption) for every entry, folder and file.\n• Argon2id (19 MiB, t=2) derives the key from the master password; PBKDF2-SHA256 as fallback.\n• Random 256-bit vault key, wrapped with the master key.\n• Keys only in memory; auto-lock, clipboard clearing, screenshot protection.',
  'Rechtliches':
      'Legal',
  'Datenschutzerklärung':
      'Privacy policy',
  'Copyright':
      'Copyright',
  'Open-Source-Lizenzen':
      'Open-source licenses',
  'Quellcode':
      'Source code',
  'Speicher konnte nicht geöffnet werden: {e}':
      'Storage could not be opened: {e}',
  'Der sichere Speicher konnte nicht geöffnet werden. Bitte schließe die App ganz und öffne sie erneut.':
      'The secure storage could not be opened. Please close the app completely and open it again.',
  'Tresor konnte nicht erstellt werden: {e}':
      'Vault could not be created: {e}',
  'Zu viele Fehlversuche. Bitte warte {v} s.':
      'Too many failed attempts. Please wait {v} s.',
  '{message} ({v} Versuche bis zur Sperre)':
      '{message} ({v} attempts left before lockout)',
  'Zu viele Fehlversuche – gesperrt für {v} s.':
      'Too many failed attempts – locked for {v} s.',
  'Entsperren fehlgeschlagen: {e}':
      'Unlock failed: {e}',
  'Biometrie-Schlüssel ungültig. Bitte mit dem Master-Passwort entsperren und Biometrie in den Einstellungen erneut aktivieren.':
      'Biometric key invalid. Please unlock with your master password and enable biometrics again in the settings.',
  'Einrichtung abgelaufen. Bitte erneut aktivieren.':
      'Setup expired. Please enable it again.',
  'Passwort vergessen?':
      'Forgot password?',
  'Dein Hinweis: „{hint}“':
      'Your hint: “{hint}”',
  'G04Passwort ist Zero-Knowledge: Dein Master-Passwort wird nirgends gespeichert und kann nicht wiederhergestellt werden.\n\nDu kannst den Tresor zurücksetzen – dabei werden alle Daten gelöscht. Danach kannst du ein Backup wiederherstellen.':
      'G04Passwort is zero-knowledge: your master password is not stored anywhere and cannot be recovered.\n\nYou can reset the vault – this deletes all data. Afterwards you can restore a backup.',
  'Tresor zurücksetzen':
      'Reset vault',
  'Wirklich alles löschen?':
      'Really delete everything?',
  'Alle Einträge, Dokumente und Schlüssel werden unwiderruflich gelöscht.':
      'All entries, documents and keys will be deleted permanently.',
  'Endgültig löschen':
      'Delete permanently',
  'Erneut mit {bioName} versuchen':
      'Try {bioName} again',
  'Mit {bioName} entsperren':
      'Unlock with {bioName}',
  'Fingerabdruck':
      'Fingerprint',
  'Face ID':
      'Face ID',
  'Entsperren mit {bioName} …':
      'Unlocking with {bioName} …',
  '{bioName} nicht erkannt. Gib dein Master-Passwort ein oder versuche es erneut.':
      '{bioName} not recognised. Enter your master password or try again.',
  'Entsperre mit {bioName} oder deinem Master-Passwort.':
      'Unlock with {bioName} or your master password.',
  'Gib dein Master-Passwort ein.':
      'Enter your master password.',
  'Willkommen zurück!':
      'Welcome back!',
  'Master-Passwort':
      'Master password',
  'Entsperren':
      'Unlock',
  'Mindestens {minMasterPasswordLength} Zeichen':
      'At least {minMasterPasswordLength} characters',
  'Bitte wähle ein stärkeres Passwort':
      'Please choose a stronger password',
  'Bitte bestätige den Hinweis zur Wiederherstellung.':
      'Please confirm the note about recovery.',
  'Dein Master-Passwort wurde geändert.':
      'Your master password has been changed.',
  'Master-Passwort ändern':
      'Change master password',
  'Master-Passwort erstellen':
      'Create master password',
  'Das einzige Passwort, das du dir merken musst. Es verschlüsselt deinen gesamten Tresor.':
      'The only password you need to remember. It encrypts your entire vault.',
  'Aktuelles Master-Passwort':
      'Current master password',
  'Bitte eingeben':
      'Please enter',
  'Neues Master-Passwort':
      'New master password',
  'Passwort bestätigen':
      'Confirm password',
  'Passwörter stimmen nicht überein':
      'Passwords do not match',
  'Hinweis (optional, unverschlüsselt)':
      'Hint (optional, not encrypted)',
  'Der Hinweis darf das Passwort nicht enthalten':
      'The hint must not contain the password',
  'Ich verstehe, dass mein Master-Passwort nicht wiederhergestellt werden kann.':
      'I understand that my master password cannot be recovered.',
  'Passwort ändern':
      'Change password',
  'Tresor erstellen':
      'Create vault',
  'Datenschutz · Copyright':
      'Privacy · Copyright',
  'Schlüssel wird sicher abgeleitet …':
      'Deriving key securely …',
  '2FA Authenticator':
      '2FA authenticator',
  'Keine 2FA-Codes':
      'No 2FA codes',
  'Füge bei einem Login den TOTP-Schlüssel (Base32 oder otpauth://-Link) hinzu.':
      'Add the TOTP key (Base32 or otpauth:// link) to a login.',
  'Neu hinzufügen':
      'Add new',
  'Code kopiert':
      'Code copied',
  'Fehler: {e}':
      'Error: {e}',
  'Backup entschlüsseln':
      'Decrypt backup',
  'Master-Passwort des Backups':
      'Master password of the backup',
  'Wiederherstellen':
      'Restore',
  'Backup':
      'Backup',
  'Letztes Backup':
      'Last backup',
  'Noch kein Backup erstellt':
      'No backup created yet',
  'Sichern':
      'Back up',
  'Verschlüsseltes Backup erstellen':
      'Create encrypted backup',
  '.g04vault – nur mit deinem Master-Passwort lesbar':
      '.g04vault – readable only with your master password',
  'Backup gespeichert':
      'Backup saved',
  'Backup wiederherstellen':
      'Restore backup',
  'Einträge werden zusammengeführt (neuere Version gewinnt)':
      'Entries are merged (newer version wins)',
  '{imported} Einträge wiederhergestellt, {skipped} übersprungen':
      '{imported} entries restored, {skipped} skipped',
  'Import':
      'Import',
  'Passwörter importieren (CSV)':
      'Import passwords (CSV)',
  'Bitwarden, 1Password, KeePass, Chrome, Edge, Firefox, LastPass':
      'Bitwarden, 1Password, KeePass, Chrome, Edge, Firefox, LastPass',
  '{imported} Einträge importiert, {skipped} übersprungen':
      '{imported} entries imported, {skipped} skipped',
  'Export':
      'Export',
  'Unverschlüsselt exportieren (CSV)':
      'Export unencrypted (CSV)',
  'Nur für den Umzug zu einem anderen Manager':
      'Only for moving to another manager',
  'Unverschlüsselter Export':
      'Unencrypted export',
  'Die CSV-Datei enthält alle Passwörter im Klartext. Lösche sie sofort nach dem Import in die Ziel-App.':
      'The CSV file contains all passwords in plain text. Delete it right after importing it into the target app.',
  'Trotzdem exportieren':
      'Export anyway',
  'CSV exportiert':
      'CSV exported',
  'Kreditkarten':
      'Credit cards',
  'Keine Karten':
      'No cards',
  'Speichere Kredit-, Debit- und Kundenkarten sicher verschlüsselt.':
      'Store credit, debit and loyalty cards securely encrypted.',
  'Abgelaufen':
      'Expired',
  'Neue Kreditkarte':
      'New credit card',
  'Neuer Ordner':
      'New folder',
  'Ordner umbenennen':
      'Rename folder',
  'Name':
      'Name',
  'Speichern':
      'Save',
  'Suche':
      'Search',
  'Ordner':
      'Folders',
  'Neu':
      'New',
  'Noch keine Ordner – erstelle z. B. „Arbeit“, „Kunden“ oder „Anlage Halle 2“.':
      'No folders yet – create e.g. “Work”, “Customers” or “Plant hall 2”.',
  'Ordner löschen?':
      'Delete folder?',
  'Die Einträge bleiben erhalten und werden keinem Ordner mehr zugeordnet.':
      'The entries are kept and no longer assigned to a folder.',
  'Löschen':
      'Delete',
  'Umbenennen':
      'Rename',
  'Tags':
      'Tags',
  'Alle':
      'All',
  'Favoriten':
      'Favorites',
  'Schnellzugriff':
      'Quick access',
  'Analyse':
      'Analysis',
  'Dein Tresor ist bereit':
      'Your vault is ready',
  'Lege deinen ersten Eintrag an oder importiere Passwörter aus einem anderen Manager.':
      'Create your first entry or import passwords from another manager.',
  'Importieren':
      'Import',
  'Passwort':
      'Password',
  'Sicherheitszentrum':
      'Security center',
  'Sperren':
      'Lock',
  'Sicherheitszentrum öffnen':
      'Open security center',
  'Tresor gesichert':
      'Vault secured',
  'Bereit für deine Daten':
      'Ready for your data',
  'AES-256-GCM · Zero-Knowledge':
      'AES-256-GCM · zero knowledge',
  'Einträge':
      'Entries',
  'Sicherheit':
      'Security',
  'Dokumente':
      'Documents',
  'Keine Dokumente':
      'No documents',
  'Reisepass, Führerschein, Verträge – Daten und PDFs verschlüsselt ablegen.':
      'Passport, driving licence, contracts – store data and PDFs encrypted.',
  'Datei':
      'File',
  'Neues Dokument':
      'New document',
  'Passwort kopiert':
      'Password copied',
  'Passwort-Generator':
      'Password generator',
  'Kopieren':
      'Copy',
  'Knackzeit (offline): {crackTimeLabel} · {round} Bit':
      'Time to crack (offline): {crackTimeLabel} · {round} bits',
  'Wörter':
      'Words',
  'Wörter großschreiben':
      'Capitalise words',
  'Zahl einfügen':
      'Add a number',
  'Trennzeichen':
      'Separator',
  'Länge':
      'Length',
  'Großbuchstaben (A-Z)':
      'Uppercase (A-Z)',
  'Kleinbuchstaben (a-z)':
      'Lowercase (a-z)',
  'Zahlen (0-9)':
      'Numbers (0-9)',
  'Sonderzeichen (!@#…)':
      'Symbols (!@#…)',
  'Ähnliche Zeichen vermeiden (l, 1, O, 0)':
      'Avoid similar characters (l, 1, O, 0)',
  'Neues Passwort generieren':
      'Generate new password',
  'Zuletzt generiert':
      'Recently generated',
  'Datenschutz':
      'Privacy',
  'Flutter, Pakete und Schriftart Roboto':
      'Flutter, packages and the Roboto font',
  'Passwort-Import':
      'Password import',
  'Bitwarden, KeePass, 1Password':
      'Bitwarden, KeePass, 1Password',
  'Passwort-Verlauf':
      'Password history',
  'Letzte Änderungen':
      'Recent changes',
  'Sichere Notizen':
      'Secure notes',
  'TOTP Generator':
      'TOTP generator',
  'Passwort-Analyse':
      'Password analysis',
  'Cloud Sync':
      'Cloud sync',
  'Einstellungen':
      'Settings',
  'Profil':
      'Profile',
  'Über G04Passwort':
      'About G04Passwort',
  'Notizen':
      'Notes',
  'Keine Notizen':
      'No notes',
  'WLAN-Zugänge, PINs, Wiederherstellungscodes – alles sicher verschlüsselt.':
      'Wi-Fi access, PINs, recovery codes – all securely encrypted.',
  'Neue Notiz':
      'New note',
  'Überspringen':
      'Skip',
  'Maximale Sicherheit':
      'Maximum security',
  'Alle Daten werden lokal mit AES-256-GCM verschlüsselt. Dein Master-Passwort wird mit Argon2id geschützt und verlässt nie dein Gerät.':
      'All data is encrypted locally with AES-256-GCM. Your master password is protected with Argon2id and never leaves your device.',
  'Schnell & komfortabel':
      'Fast & convenient',
  'Entsperre mit Fingerabdruck oder Face ID. Auto-Lock, Zwischenablage-Löschung und Screenshot-Schutz arbeiten automatisch für dich.':
      'Unlock with fingerprint or Face ID. Auto-lock, clipboard clearing and screenshot protection work for you automatically.',
  'Alles an einem Ort':
      'Everything in one place',
  'Passwörter, 2FA-Codes, Kreditkarten, Dokumente und sichere Notizen – auch Zugänge zu Geräten, HMIs, Routern und Portalen.':
      'Passwords, 2FA codes, credit cards, documents and secure notes – including access to devices, HMIs, routers and portals.',
  'Jetzt starten':
      'Get started',
  'Los geht\'s':
      'Let\'s go',
  'Anmelden':
      'Sign in',
  'Profil gespeichert':
      'Profile saved',
  'E-Mail':
      'Email',
  'Diese Angaben bleiben lokal auf deinem Gerät.':
      'This information stays on your device.',
  'Statistik':
      'Statistics',
  'Sicherheits-Score':
      'Security score',
  'Nie':
      'Never',
  '{length} Einträge':
      '{length} entries',
  '{length} Treffer':
      '{length} results',
  'Keine Treffer':
      'No results',
  'Starke Passwörter':
      'Strong passwords',
  'Mittlere Passwörter':
      'Medium passwords',
  'Schwache Passwörter':
      'Weak passwords',
  'Doppelte Passwörter':
      'Reused passwords',
  'Noch nichts zu analysieren':
      'Nothing to analyse yet',
  'Sobald du Logins speicherst, erscheint hier die Analyse.':
      'As soon as you save logins, the analysis appears here.',
  'Schwach':
      'Weak',
  'Doppelt verwendet':
      'Reused',
  'Doppelt':
      'Reused',
  'Älter als 1 Jahr':
      'Older than 1 year',
  'Alt':
      'Old',
  'Mittel':
      'Medium',
  'Leckage-Warnungen':
      'Breach warnings',
  'Online-Prüfung (Have I Been Pwned, k-Anonymität) in Vorbereitung':
      'Online check (Have I Been Pwned, k-anonymity) coming soon',
  '2FA aktiviert':
      '2FA enabled',
  'Details anzeigen':
      'Show details',
  'Auto-Save':
      'Auto-save',
  'Logins automatisch speichern':
      'Save logins automatically',
  'Bei der Anmeldung auf Websites und in Apps werden neue Zugangsdaten erkannt und sicher in deinem Tresor gespeichert.':
      'When you sign in on websites and in apps, new credentials are detected and saved securely in your vault.',
  'Auto-Save aktiv':
      'Auto-save active',
  'System-Autofill (Android Autofill-Dienst, iOS Passwort-Autofill) ist in Vorbereitung. Bis dahin kannst du Zugangsdaten per Kopieren übernehmen – die Zwischenablage wird automatisch geleert.':
      'System autofill (Android autofill service, iOS password autofill) is coming soon. Until then you can copy credentials – the clipboard is cleared automatically.',
  'Design':
      'Design',
  'Dunkel':
      'Dark',
  'Hell':
      'Light',
  'Hintergrund':
      'Background',
  'Akzentfarbe':
      'Accent color',
  'Akzentfarbe {v}':
      'Accent color {v}',
  'Mein Profil':
      'My profile',
  'Premium':
      'Premium',
  'Aktiv':
      'Active',
  'Cloud-Synchronisation':
      'Cloud sync',
  'Aus':
      'Off',
  'Sprache':
      'Language',
  'Auto-Lock':
      'Auto-lock',
  'Automatisch sperren nach':
      'Lock automatically after',
  'Beim Verlassen der App sperren':
      'Lock when leaving the app',
  'App-Sperre (Face ID / Passkey)':
      'App lock (Face ID / passkey)',
  'App-Sperre (Biometrie)':
      'App lock (biometrics)',
  'Mit Face ID / Fingerabdruck entsperren':
      'Unlock with Face ID / fingerprint',
  'Fingerabdruck / Face ID':
      'Fingerprint / Face ID',
  'Dieser Browser unterstützt keine Passkeys':
      'This browser does not support passkeys',
  'Keine Biometrie auf diesem Gerät':
      'No biometrics on this device',
  'Screenshots blockieren':
      'Block screenshots',
  'Verbirgt Inhalte in Screenshots und App-Übersicht':
      'Hides content in screenshots and the app switcher',
  'Zwischenablage leeren':
      'Clear clipboard',
  'Kopierte Passwörter löschen nach':
      'Delete copied passwords after',
  'Backup, Import & Export':
      'Backup, import & export',
  'Kein Konto, kein Tracking – deine Daten bleiben verschlüsselt auf dem Gerät.':
      'No account, no tracking – your data stays encrypted on your device.',
  'Tresor jetzt sperren':
      'Lock vault now',
  'Löscht alle Daten auf diesem Gerät':
      'Deletes all data on this device',
  'Tresor zurücksetzen?':
      'Reset vault?',
  'Alle Einträge, Dokumente und Schlüssel werden unwiderruflich gelöscht. Erstelle vorher ein Backup!':
      'All entries, documents and keys will be deleted permanently. Create a backup first!',
  'Alles löschen':
      'Delete everything',
  'Fast fertig':
      'Almost done',
  'Der Passkey wurde angelegt. Bestätige jetzt einmal mit Face ID / Fingerabdruck, um das Entsperren zu aktivieren.':
      'The passkey has been created. Confirm once with Face ID / fingerprint to enable unlocking.',
  'Face ID / Passkey aktiviert':
      'Face ID / passkey enabled',
  'Biometrie aktiviert':
      'Biometrics enabled',
  'Systemsprache':
      'System language',
  'Wie auf deinem Gerät eingestellt':
      'As set on your device',
  'Automatisch synchronisieren':
      'Sync automatically',
  'Ihre Daten sicher in der Cloud – Ende-zu-Ende verschlüsselt. Der Anbieter sieht nur verschlüsselte Daten.':
      'Your data safely in the cloud – end-to-end encrypted. The provider only sees encrypted data.',
  'Anbieter':
      'Providers',
  'In Vorbereitung':
      'Coming soon',
  'Jetzt synchronisieren':
      'Sync now',
  'Synchronisation erfolgreich':
      'Sync successful',
  'Synchronisation fehlgeschlagen':
      'Sync failed',
  'Kein aktiver Anbieter verfügbar':
      'No active provider available',
  'Noch keine Änderungen':
      'No changes yet',
  '{changes} frühere':
      '{changes} earlier',
  'Eintrag':
      'Entry',
  'Eintrag nicht gefunden':
      'Entry not found',
  'Aus Favoriten entfernen':
      'Remove from favorites',
  'Zu Favoriten':
      'Add to favorites',
  'Kategorie':
      'Category',
  'Ordner: {name}':
      'Folder: {name}',
  'Erstellt {v} · Geändert {v2}':
      'Created {v} · Modified {v2}',
  'Bearbeiten':
      'Edit',
  'Benutzername':
      'Username',
  'Webseite':
      'Website',
  'Host / IP-Adresse':
      'Host / IP address',
  'Kartennummer':
      'Card number',
  'Karteninhaber':
      'Cardholder',
  'Gültig bis':
      'Valid until',
  'Dokumenttyp':
      'Document type',
  'Nummer':
      'Number',
  'Ausstellende Behörde':
      'Issuing authority',
  '{extension} · {v} · verschlüsselt':
      '{extension} · {v} · encrypted',
  'Datei konnte nicht gespeichert werden: {e}':
      'File could not be saved: {e}',
  'Eintrag löschen?':
      'Delete entry?',
  '„{title}“ wird endgültig gelöscht.':
      '“{title}” will be deleted permanently.',
  'Eintrag gelöscht':
      'Entry deleted',
  'Ungültiger TOTP-Schlüssel':
      'Invalid TOTP key',
  '2FA-Code (TOTP)':
      '2FA code (TOTP)',
  'Passwort-Verlauf ({v})':
      'Password history ({v})',
  'Bis {v}':
      'Until {v}',
  '{v} KB':
      '{v} KB',
  '{v} MB':
      '{v} MB',
  'Ihr Passwort wurde sicher gespeichert.':
      'Your password has been saved securely.',
  'Ihre Karte wurde sicher gespeichert.':
      'Your card has been saved securely.',
  'Ihr Dokument wurde sicher gespeichert.':
      'Your document has been saved securely.',
  'Ihre Notiz wurde sicher gespeichert.':
      'Your note has been saved securely.',
  'Speichern fehlgeschlagen: {e}':
      'Saving failed: {e}',
  'Titel':
      'Title',
  'z. B. Google, Router Büro, HMI Linie 3':
      'e.g. Google, office router, HMI line 3',
  'z. B. Visa Privat':
      'e.g. Visa personal',
  'z. B. Reisepass':
      'e.g. passport',
  'z. B. WLAN-Passwort':
      'e.g. Wi-Fi password',
  'Bitte Titel eingeben':
      'Please enter a title',
  'Kein Ordner':
      'No folder',
  'Eigenes Feld hinzufügen':
      'Add custom field',
  'Favorit':
      'Favorite',
  'Benutzername / E-Mail':
      'Username / email',
  'z. B. paul@example.com':
      'e.g. paul@example.com',
  'Passwort generieren':
      'Generate password',
  'Webseite / URL':
      'Website / URL',
  'Host / IP-Adresse (Geräte, HMI, Router)':
      'Host / IP address (devices, HMI, router)',
  '2FA-Schlüssel (TOTP)':
      '2FA key (TOTP)',
  'Base32-Secret oder otpauth://-Link':
      'Base32 secret or otpauth:// link',
  'Gültig bis (MM/JJ)':
      'Valid until (MM/YY)',
  'Format MM/JJ':
      'Format MM/YY',
  'Dokumentnummer':
      'Document number',
  'Nicht gesetzt':
      'Not set',
  'Entfernen':
      'Remove',
  'Datei anhängen (PDF, Bild – verschlüsselt, max. 10 MB)':
      'Attach file (PDF, image – encrypted, max. 10 MB)',
  'Feldname':
      'Field name',
  'Wert':
      'Value',
  'Geheim':
      'Secret',
  'Tag eingeben und Enter drücken':
      'Type a tag and press Enter',
  'Alle Einträge':
      'All entries',
  'Sortieren':
      'Sort',
  'Name (A–Z)':
      'Name (A–Z)',
  'Zuletzt geändert':
      'Recently modified',
  'Noch keine Einträge':
      'No entries yet',
  'Tippe auf +, um einen neuen Eintrag anzulegen.':
      'Tap + to create a new entry.',
  'Verbergen':
      'Hide',
  'Anzeigen':
      'Show',
  '{label} kopiert – wird automatisch gelöscht':
      '{label} copied – will be cleared automatically',
  'Passwort kopieren':
      'Copy password',
  'Suche im Tresor …':
      'Search the vault …',
  'Roboto (Schriftart)':
      'Roboto (font)',
  'Sofort':
      'Immediately',
  '{seconds} Sekunden':
      '{seconds} seconds',
  '1 Minute':
      '1 minute',
  '{m} Minuten':
      '{m} minutes',
  '{round} Sekunden':
      '{round} seconds',
  '{v} Minuten':
      '{v} minutes',
  '{v} Stunden':
      '{v} hours',
  '{v} Tage':
      '{v} days',
  '{round} Jahre':
      '{round} years',
  '{v} Tsd. Jahre':
      '{v} thousand years',
  'Jahrhunderte+':
      'Centuries+',
  'Sehr sicher':
      'Very secure',
  'Sicher':
      'Secure',
  'Verbesserungswürdig':
      'Needs improvement',
  'Gefährdet':
      'At risk',
  'Karte':
      'Card',
  '{v} Datei(en)':
      '{v} file(s)',
  'Kein Tresor vorhanden.':
      'No vault found.',
  'Ohne Titel':
      'Untitled',
  'Die Datei ist größer als 10 MB.':
      'The file is larger than 10 MB.',
  'Dieser Browser unterstützt Face ID für Web-Apps noch nicht. Benötigt wird iOS/iPadOS 18 oder neuer bzw. ein aktuelles Chrome, Edge oder Safari mit Passkey-Unterstützung.':
      'This browser does not support Face ID for web apps yet. It requires iOS/iPadOS 18 or later, or a current Chrome, Edge or Safari with passkey support.',
  'Entsperre deinen G04Passwort-Tresor':
      'Unlock your G04Passwort vault',
  'Biometrische Bestätigung fehlgeschlagen':
      'Biometric verification failed',
  'Biometrisches Entsperren für G04Passwort aktivieren':
      'Enable biometric unlock for G04Passwort',
  'Face ID funktioniert nur über eine sichere Verbindung (https).':
      'Face ID only works over a secure connection (https).',
  'Für diese Web-App ist bereits ein Passkey vorhanden.':
      'A passkey already exists for this web app.',
  'Face ID konnte nicht verwendet werden. Bitte erneut versuchen.':
      'Face ID could not be used. Please try again.',
  'Die CSV-Datei ist leer.':
      'The CSV file is empty.',
  'Spalten „username“/„password“ nicht gefunden.':
      'Columns “username”/“password” not found.',
  'Sehr häufiges Passwort – leicht zu erraten.':
      'Very common password – easy to guess.',
  'Vermeide Folgen wie „abc“, „123“ oder Tastaturreihen.':
      'Avoid sequences like “abc”, “123” or keyboard rows.',
  'Vermeide wiederholte Zeichen.':
      'Avoid repeated characters.',
  'Jahreszahlen sind leicht zu erraten.':
      'Years are easy to guess.',
  'Nutze mindestens 12 Zeichen.':
      'Use at least 12 characters.',
  'Füge Sonderzeichen hinzu.':
      'Add symbols.',
  'Kombiniere Groß- und Kleinbuchstaben.':
      'Combine uppercase and lowercase letters.',
  'Muster „Wort + Zahl“ ist sehr verbreitet.':
      'The pattern “word + number” is very common.',
  '{name}-Synchronisation':
      '{name} sync',
  'WebDAV / Nextcloud':
      'WebDAV / Nextcloud',
  'Stärke':
      'Strength',
  'Erledigt!':
      'Done!',
  'Dein Passwort wurde sicher gespeichert.':
      'Your password has been saved securely.',
  'Schließen':
      'Close',
  'Passwörter':
      'Passwords',
  'Biometrie':
      'Biometrics',
  '2FA / TOTP':
      '2FA / TOTP',
  'Import / Export':
      'Import / export',
  'Wellen':
      'Waves',
  'Horizont':
      'Horizon',
  'Erde':
      'Earth',
  'Berge':
      'Mountains',
  'Gipfel':
      'Summit',
  'Glow':
      'Glow',
  'Schild':
      'Shield',
  'Flow':
      'Flow',
  'Circuit':
      'Circuit',
  'Hexagon':
      'Hexagon',
  'Kurve':
      'Curve',
  'Logins':
      'Logins',
  'WLAN':
      'Wi-Fi',
  'Software-Lizenzen':
      'Software licenses',
  'Identitäten':
      'Identities',
  'Geräte':
      'Devices',
  'HMI / Steuerungen':
      'HMI / controllers',
  'Router & Netzwerk':
      'Router & network',
  'Portale':
      'Portals',
  'Sonstiges':
      'Other',
  'Login':
      'Login',
  'Kreditkarte':
      'Credit card',
  'Dokument':
      'Document',
  'Sichere Notiz':
      'Secure note',
  'Sehr schwach':
      'Very weak',
  'Stark':
      'Strong',
  'Sehr stark':
      'Very strong',
  'Passphrase':
      'Passphrase',
  'PIN':
      'PIN',
  'Der Tresor ist gesperrt.':
      'The vault is locked.',
  'Das Master-Passwort ist falsch.':
      'The master password is incorrect.',
  'Zu viele Fehlversuche. Bitte warte kurz.':
      'Too many failed attempts. Please wait a moment.',
  'Daten sind beschädigt oder wurden manipuliert.':
      'Data is corrupted or has been tampered with.',
  'Die Datei ist kein gültiges Backup.':
      'The file is not a valid backup.',
  '{feature} ist in Vorbereitung und bald verfügbar.':
      '{feature} is in preparation and will be available soon.',
  'Reisepass':
      'Passport',
  'Personalausweis':
      'ID card',
  'Führerschein':
      'Driving licence',
  'Vertrag':
      'Contract',
  'Versicherung':
      'Insurance',
  'Zeugnis':
      'Certificate',
  'Sonstige':
      'Other',
};
