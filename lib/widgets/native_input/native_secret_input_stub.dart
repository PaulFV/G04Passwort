import 'package:flutter/widgets.dart';

import 'native_secret_input.dart';

/// Not used outside the web – the app falls back to a normal text field.
Widget buildNativeSecretInput(NativeSecretInput config) =>
    const SizedBox.shrink();
