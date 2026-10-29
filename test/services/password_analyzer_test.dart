import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/services/password_analyzer_service.dart';

void main() {
  const analyzer = PasswordAnalyzerService();

  test('empty password', () => expect(analyzer.analyze('').isEmpty, isTrue));

  test('common passwords are very weak', () {
    for (final p in ['123456', 'password', 'Passwort', 'qwertz', 'hallo123']) {
      expect(analyzer.analyze(p).score, 0, reason: p);
    }
  });

  test('sequences and word+number patterns are penalised', () {
    expect(analyzer.analyze('abcdef123').score, lessThanOrEqualTo(1));
    expect(analyzer.analyze('Sommer2024!').score, lessThanOrEqualTo(2));
  });

  test('long random passwords are very strong', () {
    expect(analyzer.analyze(r'G7f#k9!Qp2@Z8&Lm').score, 4);
    expect(
      analyzer.analyze('Tanne-Komet-Zebra-Lava-Rubin7').score,
      greaterThanOrEqualTo(3),
    );
  });
}
