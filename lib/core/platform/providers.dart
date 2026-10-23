import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';
import 'package:visual_time_counter/core/platform/external_link/external_link_port.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:visual_time_counter/core/platform/haptics/haptics_port.dart';
import 'package:visual_time_counter/core/platform/image_picker/image_picker_port.dart';
import 'package:visual_time_counter/core/platform/lifecycle/app_lifecycle_port.dart';
import 'package:visual_time_counter/core/platform/system_settings/system_settings_port.dart';
import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';

/// The platforms the app runs on.
enum AppPlatform {
  /// Android.
  android,

  /// iOS and iPadOS.
  ios,

  /// macOS.
  macos,

  /// Windows.
  windows,

  /// Linux (also used for Fuchsia).
  linux,

  /// Any browser.
  web;

  /// The platform for [isWeb] and [target].
  static AppPlatform resolve({
    required bool isWeb,
    required TargetPlatform target,
  }) {
    if (isWeb) return web;
    return switch (target) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => macos,
      TargetPlatform.windows => windows,
      TargetPlatform.linux || TargetPlatform.fuchsia => linux,
    };
  }
}

/// Which alarm implementation a platform uses.
enum AlarmChoice {
  /// `flutter_local_notifications` with OS scheduling.
  localNotifications,

  /// No OS scheduling; rings only with the app open.
  foregroundOnly,
}

/// Which full-screen implementation a platform uses.
enum FullscreenChoice {
  /// `SystemChrome` immersive mode (Android, iOS).
  systemChrome,

  /// `window_manager` (desktop).
  windowManager,

  /// The browser Fullscreen API.
  web,
}

/// The implementation choices for one platform (contracts/platform-ports.md
/// support matrix).
@immutable
final class PortChoice {
  /// Creates the choices.
  const new({
    required this.alarm,
    required this.fullscreen,
    required this.hasVibrator,
    required this.hasSystemSettings,
  });

  /// The alarm implementation.
  final AlarmChoice alarm;

  /// The full-screen implementation.
  final FullscreenChoice fullscreen;

  /// Whether haptics are available.
  final bool hasVibrator;

  /// Whether the Android settings channel exists.
  final bool hasSystemSettings;

  @override
  bool operator ==(Object other) =>
      other is PortChoice &&
      other.alarm == alarm &&
      other.fullscreen == fullscreen &&
      other.hasVibrator == hasVibrator &&
      other.hasSystemSettings == hasSystemSettings;

  @override
  int get hashCode =>
      Object.hash(alarm, fullscreen, hasVibrator, hasSystemSettings);

  @override
  String toString() =>
      'PortChoice($alarm, $fullscreen, vibrator: $hasVibrator, '
      'systemSettings: $hasSystemSettings)';
}

/// The implementations [platform] uses.
///
/// Windows stays foreground-only until spike T042 confirms reliable OS
/// scheduling (research R4): an unverified alarm could fail silently,
/// which Constitution III forbids.
PortChoice choosePorts(AppPlatform platform) => switch (platform) {
  AppPlatform.android => const PortChoice(
    alarm: AlarmChoice.localNotifications,
    fullscreen: FullscreenChoice.systemChrome,
    hasVibrator: true,
    hasSystemSettings: true,
  ),
  AppPlatform.ios => const PortChoice(
    alarm: AlarmChoice.localNotifications,
    fullscreen: FullscreenChoice.systemChrome,
    hasVibrator: true,
    hasSystemSettings: false,
  ),
  AppPlatform.macos => const PortChoice(
    alarm: AlarmChoice.localNotifications,
    fullscreen: FullscreenChoice.windowManager,
    hasVibrator: false,
    hasSystemSettings: false,
  ),
  AppPlatform.windows || AppPlatform.linux => const PortChoice(
    alarm: AlarmChoice.foregroundOnly,
    fullscreen: FullscreenChoice.windowManager,
    hasVibrator: false,
    hasSystemSettings: false,
  ),
  AppPlatform.web => const PortChoice(
    alarm: AlarmChoice.foregroundOnly,
    fullscreen: FullscreenChoice.web,
    hasVibrator: false,
    hasSystemSettings: false,
  ),
};

/// The platform the app is running on.
final appPlatformProvider = Provider<AppPlatform>(
  (ref) => AppPlatform.resolve(isWeb: kIsWeb, target: defaultTargetPlatform),
);

/// Schedules the end-of-timer alarm with the OS.
final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => _notOverridden('AlarmScheduler'),
);

/// Keeps the screen on.
final wakeLockProvider = Provider<WakeLockPort>(
  (ref) => _notOverridden('WakeLockPort'),
);

/// Full-screen mode.
final fullscreenProvider = Provider<FullscreenPort>(
  (ref) => _notOverridden('FullscreenPort'),
);

/// Foreground sounds.
final audioProvider = Provider<AudioPort>((ref) => _notOverridden('AudioPort'));

/// Vibration.
final hapticsProvider = Provider<HapticsPort>(
  (ref) => _notOverridden('HapticsPort'),
);

/// The system image picker.
final imagePickerProvider = Provider<ImagePickerPort>(
  (ref) => _notOverridden('ImagePickerPort'),
);

/// Android system settings screens.
final systemSettingsProvider = Provider<SystemSettingsPort>(
  (ref) => _notOverridden('SystemSettingsPort'),
);

/// Links outside the app.
final externalLinkProvider = Provider<ExternalLinkPort>(
  (ref) => _notOverridden('ExternalLinkPort'),
);

/// App lifecycle changes.
final appLifecycleProvider = Provider<AppLifecyclePort>(
  (ref) => _notOverridden('AppLifecyclePort'),
);

/// Ports are provided by bootstrap (real implementations) or by tests
/// (fakes); reading one that was not provided is a programming error.
Never _notOverridden(String port) => throw StateError(
  '$port must be overridden in bootstrap or in the test ProviderScope',
);
