import '../../core/constants/app_constants.dart';

/// A titled paragraph block of a legal text.
class LegalSection {
  const LegalSection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

/// Datenschutzerklärung (DSGVO) of G04Passwort.
///
/// Keep in sync with PRIVACY.md in the repository root.
abstract final class PrivacyText {
  static const intro =
      'G04Passwort ist ein Passwort-Tresor, der deine Daten ausschließlich auf '
      'deinem Gerät verschlüsselt speichert. Es gibt kein Konto, keinen Server '
      'von G04Passwort, kein Tracking und keine Werbung.';

  static const sections = <LegalSection>[
    LegalSection('1. Verantwortlicher', [
      'Verantwortlich für diese App: ${AppConstants.owner}.\n'
          'Kontakt: über GitHub – ${AppConstants.ownerUrl}',
    ]),
    LegalSection('2. Grundsatz: Deine Daten bleiben bei dir', [
      'Alle Einträge (Passwörter, Kreditkarten, Dokumente, Notizen, 2FA-Schlüssel, '
          'Ordner, Anhänge) werden lokal auf deinem Gerät gespeichert und mit '
          'AES-256-GCM verschlüsselt. Der Schlüssel wird aus deinem Master-Passwort '
          'abgeleitet (Argon2id bzw. PBKDF2) und verlässt dein Gerät nie.',
      '${AppConstants.owner} hat keinen Zugriff auf deine Daten und kann sie weder '
          'einsehen noch wiederherstellen. Es werden keine Inhalte an '
          '${AppConstants.owner} oder Dritte übertragen.',
    ]),
    LegalSection('3. Keine Analyse, kein Tracking, keine Werbung', [
      'G04Passwort verwendet keine Analyse- oder Tracking-Dienste, keine '
          'Werbe-Netzwerke, keine Crash-Reporting-Dienste und keine Cookies zu '
          'Tracking-Zwecken. Schriften und Programmteile sind in der App enthalten '
          'und werden nicht von fremden Servern (z. B. Google Fonts) geladen.',
    ]),
    LegalSection('4. Lokale Speicherung', [
      'Android/iOS/Desktop: verschlüsselte SQLite-Datenbank im App-Speicher sowie '
          'der Schlüsselbund (Keychain/Keystore) für Einstellungen und – nur wenn '
          'du es aktivierst – den Schlüssel für das Entsperren per Biometrie.',
      'Web-App: verschlüsselte Datenbank im Speicher deines Browsers (IndexedDB) '
          'und lokaler Browser-Speicher für Einstellungen. Diese Daten werden nur '
          'für die Funktion der App benötigt (Art. 6 Abs. 1 lit. b DSGVO bzw. '
          '§ 25 Abs. 2 Nr. 2 TDDDG) und verlassen den Browser nicht.',
    ]),
    LegalSection('5. Hosting der Web-App (GitHub Pages)', [
      'Die Web-App wird über GitHub Pages bereitgestellt (GitHub Inc., 88 Colin P. '
          'Kelly Jr. Street, San Francisco, CA 94107, USA; Tochter der Microsoft '
          'Corporation). Beim Aufruf verarbeitet GitHub technisch notwendige '
          'Verbindungsdaten wie IP-Adresse, Zeitpunkt und Browser-Informationen in '
          'Server-Logs, um die Seite auszuliefern und abzusichern '
          '(Art. 6 Abs. 1 lit. f DSGVO). Deine Tresor-Inhalte werden dabei nicht '
          'übertragen.',
      'Die Übermittlung in die USA stützt sich auf das EU-US Data Privacy '
          'Framework. Details: https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement',
      'Die Android-Test-Version wird über GitHub Releases heruntergeladen; '
          'dabei gilt dasselbe.',
    ]),
    LegalSection('6. Biometrie, Zwischenablage, Bildschirm', [
      'Fingerabdruck und Face ID werden vom Betriebssystem geprüft. Die App '
          'erhält nur die Information „erfolgreich“ oder „nicht erfolgreich“ – '
          'niemals biometrische Daten.',
      'Kopierte Passwörter werden nach der eingestellten Zeit automatisch aus der '
          'Zwischenablage gelöscht. Der Screenshot-Schutz verhindert, dass Inhalte '
          'in Bildschirmfotos oder der App-Übersicht erscheinen.',
    ]),
    LegalSection('7. Dateien, Backup und Import', [
      'Backups (.g04vault), CSV-Import und -Export sowie Dokument-Anhänge werden '
          'nur auf dein ausdrückliches Kommando lokal gelesen bzw. gespeichert. '
          'Ein verschlüsseltes Backup kann nur mit deinem Master-Passwort geöffnet '
          'werden. Ein CSV-Export ist unverschlüsselt – bewahre ihn sicher auf und '
          'lösche ihn nach Gebrauch.',
    ]),
    LegalSection('8. Geplante Funktionen', [
      'Cloud-Synchronisation (z. B. Google Drive, OneDrive, iCloud, WebDAV) und '
          'eine Leak-Prüfung sind vorbereitet, aber noch nicht aktiv. Sie werden '
          'nur nach deiner ausdrücklichen Aktivierung genutzt; dabei würden '
          'ausschließlich verschlüsselte Daten übertragen. Diese Erklärung wird '
          'vorher entsprechend ergänzt.',
    ]),
    LegalSection('9. Löschen deiner Daten', [
      'Du kannst alle Daten jederzeit selbst löschen: Einstellungen → „Tresor '
          'zurücksetzen“, App deinstallieren bzw. in der Web-App die Websitedaten '
          'des Browsers löschen.',
    ]),
    LegalSection('10. Deine Rechte', [
      'Du hast nach der DSGVO das Recht auf Auskunft, Berichtigung, Löschung, '
          'Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch '
          'sowie ein Beschwerderecht bei einer Datenschutz-Aufsichtsbehörde. Da '
          '${AppConstants.owner} keine personenbezogenen Daten von dir speichert, '
          'liegen alle Daten ausschließlich in deiner Hand. Für Daten in '
          'Server-Logs von GitHub wende dich an GitHub.',
    ]),
  ];

  static const updated = 'Stand: ${AppConstants.legalDate}';
}

/// Copyright notice of G04Passwort. Keep in sync with LICENSE.
abstract final class CopyrightText {
  static const headline = AppConstants.rightsReserved;

  static const paragraphs = <String>[
    'G04Passwort – Quelltext, Name, App-Icon, Logo und Gestaltung – ist '
        'urheberrechtlich geschützt. Ohne ausdrückliche schriftliche Erlaubnis '
        'von ${AppConstants.owner} darf die Software weder kopiert, verändert, '
        'weitergegeben noch veröffentlicht werden.',
    'Die Nutzung der veröffentlichten App (Web-App und Test-Versionen) zum '
        'privaten Gebrauch ist erlaubt.',
    'Verwendete Open-Source-Komponenten (z. B. Flutter, Riverpod, Drift, '
        'cryptography, Schriftart Roboto) unterliegen ihren eigenen Lizenzen. '
        'Diese sind unter „Open-Source-Lizenzen“ einsehbar.',
  ];
}
