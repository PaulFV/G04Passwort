import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../models/generator_options.dart';
import '../../../models/password_strength.dart';

/// Strength of an arbitrary password (used by forms and the generator).
final passwordStrengthProvider = Provider.family<PasswordStrength, String>(
  (ref, password) => ref.watch(passwordAnalyzerProvider).analyze(password),
);

@immutable
class GeneratorState {
  const GeneratorState({required this.options, required this.password, required this.history});

  final GeneratorOptions options;
  final String password;

  /// Recently generated passwords of this session (not persisted).
  final List<String> history;

  GeneratorState copyWith({GeneratorOptions? options, String? password, List<String>? history}) =>
      GeneratorState(
        options: options ?? this.options,
        password: password ?? this.password,
        history: history ?? this.history,
      );
}

/// State of the password generator screen.
class GeneratorController extends Notifier<GeneratorState> {
  @override
  GeneratorState build() {
    const options = GeneratorOptions();
    return GeneratorState(
      options: options,
      password: ref.read(passwordGeneratorProvider).generate(options),
      history: const [],
    );
  }

  void regenerate() {
    final next = ref.read(passwordGeneratorProvider).generate(state.options);
    state = state.copyWith(
      password: next,
      history: [state.password, ...state.history].take(10).toList(),
    );
  }

  void update(GeneratorOptions Function(GeneratorOptions o) change) {
    var options = change(state.options);
    // Never allow all character classes to be disabled.
    if (options.mode == GeneratorMode.password &&
        !options.uppercase &&
        !options.lowercase &&
        !options.digits &&
        !options.symbols) {
      options = options.copyWith(lowercase: true);
    }
    state = state.copyWith(
      options: options,
      password: ref.read(passwordGeneratorProvider).generate(options),
    );
  }
}

final generatorControllerProvider =
    NotifierProvider<GeneratorController, GeneratorState>(GeneratorController.new);
