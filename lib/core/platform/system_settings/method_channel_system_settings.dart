import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:visual_time_counter/core/platform/system_settings/system_settings_port.dart';

/// [SystemSettingsPort] over the app's own `vtc/system_settings` channel
/// (research R15); returns false without calling it outside Android.
final class MethodChannelSystemSettings implements SystemSettingsPort {
  /// Creates the port; [isAndroid] comes from the platform selection.
  const new({required this.isAndroid});

  static const _channel = MethodChannel('vtc/system_settings');

  /// Whether the channel exists on this platform.
  final bool isAndroid;

  @override
  Future<bool> openExactAlarmSettings() => _open('openExactAlarm');

  @override
  Future<bool> openAppNotificationSettings() => _open('openNotifications');

  @override
  Future<bool> openBatteryOptimizationSettings() =>
      _open('openBatteryOptimization');

  Future<bool> _open(String method) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException catch (error) {
      debugPrint('System settings "$method" failed: $error');
      return false;
    }
  }
}
