import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';

/// Records whether the screen is kept on.
class FakeWakeLock implements WakeLockPort {
  bool enabled = false;

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;

  @override
  Future<bool> get isEnabled async => enabled;
}
