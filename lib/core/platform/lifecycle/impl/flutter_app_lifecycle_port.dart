import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:visual_time_counter/core/platform/lifecycle/app_lifecycle_port.dart';

/// [AppLifecyclePort] over Flutter's [AppLifecycleListener].
final class FlutterAppLifecyclePort implements AppLifecyclePort {
  /// Starts listening; call [dispose] when no longer needed.
  new() {
    _listener = AppLifecycleListener(onStateChange: _states.add);
  }

  final _states = StreamController<AppLifecycleState>.broadcast();
  late final AppLifecycleListener _listener;

  @override
  Stream<AppLifecycleState> get states => _states.stream;

  /// Stops listening.
  Future<void> dispose() async {
    _listener.dispose();
    await _states.close();
  }
}
