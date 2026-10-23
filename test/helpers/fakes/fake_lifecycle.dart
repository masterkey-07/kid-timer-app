import 'dart:async';
import 'dart:ui';

import 'package:visual_time_counter/core/platform/lifecycle/app_lifecycle_port.dart';

/// Emits lifecycle states on demand.
class FakeLifecycle implements AppLifecyclePort {
  final _states = StreamController<AppLifecycleState>.broadcast();

  void emit(AppLifecycleState state) => _states.add(state);

  Future<void> dispose() => _states.close();

  @override
  Stream<AppLifecycleState> get states => _states.stream;
}
