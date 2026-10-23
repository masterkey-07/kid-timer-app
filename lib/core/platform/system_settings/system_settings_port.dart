/// Opens Android system settings screens; returns false elsewhere.
abstract interface class SystemSettingsPort {
  /// Opens the exact alarm setting (Android 12–13).
  Future<bool> openExactAlarmSettings();

  /// Opens the app's notification settings.
  Future<bool> openAppNotificationSettings();

  /// Opens the battery optimization settings.
  Future<bool> openBatteryOptimizationSettings();
}
