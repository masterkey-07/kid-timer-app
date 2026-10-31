import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/parental/domain/diagnostic_report.dart';

void main() {
  const report = DiagnosticReport(
    version: '1.0.0',
    build: '1',
    platform: AppPlatform.android,
    screenSize: Size(360, 800),
    languageCode: 'pt',
    notifications: PermissionState.denied,
    exactAlarm: PermissionState.granted,
  );

  test('lists version, platform, screen size and permission states', () {
    final text = report.toText();

    expect(text, contains('Kid Timer 1.0.0 (1)'));
    expect(text, contains('Platform: android'));
    expect(text, contains('Screen: 360x800'));
    expect(text, contains('Language: pt'));
    expect(text, contains('Notifications: denied'));
    expect(text, contains('Exact alarms: granted'));
  });

  test('rounds fractional screen sizes', () {
    final text = const DiagnosticReport(
      version: '1.0.0',
      build: '1',
      platform: AppPlatform.web,
      screenSize: Size(411.4, 914.6),
      languageCode: 'en',
      notifications: PermissionState.notApplicable,
      exactAlarm: PermissionState.notApplicable,
    ).toText();

    expect(text, contains('Screen: 411x915'));
  });
}
