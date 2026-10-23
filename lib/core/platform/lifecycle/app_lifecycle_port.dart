import 'dart:ui';

/// App lifecycle changes (resumed, inactive, hidden, paused, detached).
abstract interface class AppLifecyclePort {
  /// Emits every lifecycle change.
  Stream<AppLifecycleState> get states;
}
