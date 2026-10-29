import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/features/generator/application/generator_controller.dart';
import 'package:g04passwort/models/generator_options.dart';

void main() {
  test('generator controller regenerates and keeps history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = container.read(generatorControllerProvider).password;
    container.read(generatorControllerProvider.notifier).regenerate();
    final state = container.read(generatorControllerProvider);
    expect(state.password, isNot(first));
    expect(state.history.first, first);
  });

  test('never disables all character classes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(generatorControllerProvider.notifier).update(
          (o) => o.copyWith(uppercase: false, lowercase: false, digits: false, symbols: false),
        );
    final o = container.read(generatorControllerProvider).options;
    expect(o.lowercase, isTrue);
    expect(o.mode, GeneratorMode.password);
  });
}
