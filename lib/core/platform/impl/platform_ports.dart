import 'package:clock/clock.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/alarm/foreground_only_alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/alarm/impl/local_notifications_alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/audio/impl/audioplayers_audio_port.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:visual_time_counter/core/platform/fullscreen/impl/system_chrome_fullscreen.dart';
import 'package:visual_time_counter/core/platform/fullscreen/impl/web_fullscreen.dart';
import 'package:visual_time_counter/core/platform/fullscreen/impl/window_manager_fullscreen.dart';
import 'package:visual_time_counter/core/platform/haptics/impl/flutter_haptics_port.dart';
import 'package:visual_time_counter/core/platform/lifecycle/impl/flutter_app_lifecycle_port.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/platform/system_settings/method_channel_system_settings.dart';
import 'package:visual_time_counter/core/platform/wakelock/impl/wakelock_plus_port.dart';

/// Creates the real port implementations for [platform] and returns the
/// provider overrides for the app's `ProviderScope`.
///
/// The image picker and external link ports are added by the stories that
/// use them (US3, US7).
Future<List<Override>> createPlatformPortOverrides(
  AppPlatform platform, {
  required Clock clock,
}) async {
  final choice = choosePorts(platform);
  return [
    appPlatformProvider.overrideWithValue(platform),
    alarmSchedulerProvider.overrideWithValue(
      await _createAlarmScheduler(choice.alarm, clock: clock),
    ),
    wakeLockProvider.overrideWithValue(const WakelockPlusPort()),
    fullscreenProvider.overrideWithValue(_createFullscreen(choice.fullscreen)),
    audioProvider.overrideWithValue(AudioplayersAudioPort()),
    hapticsProvider.overrideWithValue(
      FlutterHapticsPort(hasVibrator: choice.hasVibrator),
    ),
    systemSettingsProvider.overrideWithValue(
      MethodChannelSystemSettings(isAndroid: choice.hasSystemSettings),
    ),
    appLifecycleProvider.overrideWithValue(FlutterAppLifecyclePort()),
  ];
}

Future<AlarmScheduler> _createAlarmScheduler(
  AlarmChoice choice, {
  required Clock clock,
}) async {
  switch (choice) {
    case AlarmChoice.foregroundOnly:
      return const ForegroundOnlyAlarmScheduler();
    case AlarmChoice.localNotifications:
      final scheduler = LocalNotificationsAlarmScheduler(clock: clock);
      await scheduler.initialize();
      return scheduler;
  }
}

FullscreenPort _createFullscreen(FullscreenChoice choice) => switch (choice) {
  FullscreenChoice.systemChrome => const SystemChromeFullscreen(),
  FullscreenChoice.windowManager => const WindowManagerFullscreen(),
  FullscreenChoice.web => const WebFullscreen(),
};
