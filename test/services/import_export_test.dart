import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/services/import_export_service.dart';

void main() {
  test('parses quoted fields, escaped quotes and newlines', () {
    final rows = ImportExportService.parseCsv(
      'name,password,notes\n"A, B","p""w","line1\nline2"\nC,x,\n',
    );
    expect(rows, hasLength(3));
    expect(rows[1], ['A, B', 'p"w', 'line1\nline2']);
    expect(rows[2], ['C', 'x', '']);
  });

  test('detects semicolon separated files (German Excel)', () {
    final rows = ImportExportService.parseCsv(
      'Titel;Benutzername;Passwort\nRouter;admin;geheim,1\n',
    );
    expect(rows[1], ['Router', 'admin', 'geheim,1']);
  });

  test('strips UTF-8 BOM', () {
    final rows = ImportExportService.parseCsv('﻿name,password\nx,y');
    expect(rows.first.first, 'name');
  });
}
