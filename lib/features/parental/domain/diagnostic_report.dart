import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';

/// The text an adult pastes into a problem report: technical facts only,
/// nothing about the person or their timers (contracts/ui/07 §7.2).
@immutable
final class DiagnosticReport {
  /// Creates a report.
  const new({
    required this.version,
    required this.build,
    required this.platform,
    required this.screenSize,
    required this.languageCode,
    required this.notifications,
    required this.exactAlarm,
  });

  /// The app version.
  final String version;

  /// The app build number.
  final String build;

  /// The platform the app runs on.
  final AppPlatform platform;

  /// The window size in logical pixels.
  final Size screenSize;

  /// The language the app is shown in.
  final String languageCode;

  /// The notification permission.
  final PermissionState notifications;

  /// The exact alarm permission.
  final PermissionState exactAlarm;

  /// The report as plain text, one fact per line.
  String toText() {
    final width = screenSize.width.round();
    final height = screenSize.height.round();
    return [
      'Kid Timer $version ($build)',
      'Platform: ${platform.name}',
      'Screen: ${width}x$height',
      'Language: $languageCode',
      'Notifications: ${notifications.name}',
      'Exact alarms: ${exactAlarm.name}',
    ].join('\n');
  }
}
