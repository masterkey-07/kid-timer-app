import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// [WakeLockPort] backed by `wakelock_plus` (all platforms).
final class WakelockPlusPort implements WakeLockPort {
  /// Creates the port.
  const new();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();

  @override
  Future<bool> get isEnabled => WakelockPlus.enabled;
}
