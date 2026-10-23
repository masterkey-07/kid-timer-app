import 'package:visual_time_counter/core/platform/system_settings/system_settings_port.dart';

/// Records which settings screen was opened.
class FakeSystemSettings implements SystemSettingsPort {
  new({this.result = true});

  /// What every open method returns.
  final bool result;
  final List<String> opened = [];

  @override
  Future<bool> openExactAlarmSettings() => _open('exactAlarm');

  @override
  Future<bool> openAppNotificationSettings() => _open('notifications');

  @override
  Future<bool> openBatteryOptimizationSettings() =>
      _open('batteryOptimization');

  Future<bool> _open(String screen) async {
    opened.add(screen);
    return result;
  }
}
