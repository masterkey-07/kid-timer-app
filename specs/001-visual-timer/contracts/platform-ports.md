# Contract — Platform ports

Interfaces in `lib/core/platform/`. Each port has: a real implementation per platform
(`*_io.dart`, `*_web.dart` or one class per OS), a fake implementation in
`test/helpers/fakes/` and a shared contract test (`test/contract/<port>_contract.dart`) run
against the fake (unit) and against the real implementation (integration).

All asynchronous methods return a `Future` and never throw for an expected platform condition:
they return a typed result.

## AlarmScheduler

```dart
abstract interface class AlarmScheduler {
  /// What the current platform can do right now (queries permissions).
  Future<AlarmCapabilities> capabilities();

  /// Requests notification permission (no-op where not applicable).
  Future<PermissionState> requestNotificationPermission();

  /// Opens the exact alarm setting (Android 12–13) or returns false.
  Future<bool> openExactAlarmSettings();

  /// Schedules the end alarm. Idempotent per [request.id].
  Future<ScheduleResult> schedule(AlarmRequest request);

  /// Cancels a scheduled alarm (ignores unknown ids).
  Future<void> cancel(int id);

  /// Cancels every alarm in a group (e.g., a routine).
  Future<void> cancelGroup(String groupKey);

  /// Stream of notification taps (payload = deep link).
  Stream<String> get notificationTaps;

  /// Payload of the notification that opened the app, if any.
  Future<String?> launchPayload();
}

final class AlarmCapabilities {
  final SchedulingSupport scheduling;   // native | inexactOnly | unsupported
  final PermissionState notifications;  // granted | denied | notDetermined | notApplicable
  final PermissionState exactAlarm;     // granted | denied | notApplicable
  final bool bypassesSilentMode;        // true only with AlarmKit (iOS 26+)
}

final class AlarmRequest {
  final int id;                 // stable, derived from sessionId (+ step index)
  final String groupKey;        // sessionId or routineRunId
  final DateTime fireAtUtc;
  final AlarmKind kind;         // end | warning | stepEnd
  final String title;           // already localized
  final String body;            // already localized
  final SoundId sound;
  final String payload;         // deep link, e.g. "vtc://run"
}

sealed class ScheduleResult { /* Scheduled(exact|inexact) | NotSupported | Failed(reason) */ }
```

| Implementation                     | Platforms                      | Notes                                                                        |
| ---------------------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `LocalNotificationsAlarmScheduler` | Android, iOS, macOS, Windows\* | `flutter_local_notifications` + `timezone`; \*Windows depending on the spike |
| `AlarmKitScheduler` (v1.x)         | iOS 26+                        | decorator: tries AlarmKit, falls back to the previous one                    |
| `ForegroundOnlyAlarmScheduler`     | Web, Linux                     | `scheduling = unsupported`; schedules nothing                                |
| `FakeAlarmScheduler`               | tests                          | records requests; can simulate taps and permissions                          |

**Contract rules** (tested): `schedule` with the same id replaces; `cancel` of an unknown id does
not fail; `fireAtUtc` in the past → `ScheduleResult.Failed(pastTime)`; never more than 60
pending per `groupKey`.

## WakeLockPort

```dart
abstract interface class WakeLockPort {
  Future<void> enable();
  Future<void> disable();
  Future<bool> get isEnabled;
}
```

Implementation: `wakelock_plus`. The fake records state.

## FullscreenPort

```dart
abstract interface class FullscreenPort {
  Future<void> enter();
  Future<void> exit();
  bool get isSupported;
}
```

Implementations: `SystemChromeFullscreen` (Android/iOS, immersive), `WindowManagerFullscreen`
(desktop), `WebFullscreen` (Fullscreen API; requires a user gesture, so it is called on the Start
tap).

## AudioPort

```dart
abstract interface class AudioPort {
  Future<void> preload(Iterable<SoundId> sounds);
  Future<void> playAlarm(SoundId sound, {required double volume, int repeat = 1});
  Future<void> playPreview(SoundId sound, {required double volume});
  Future<void> startTicking({required double volume});
  Future<void> stopTicking();
  Future<void> stopAll();
  Future<double?> systemVolume(); // null when unavailable
}
```

Implementation: `audioplayers` (one player per channel: alarm, preview, ticking).

## HapticsPort

```dart
abstract interface class HapticsPort {
  bool get hasVibrator;
  Future<void> selectionTick();     // dial adjustment
  Future<void> alarmPattern();      // 2 pulses at the end
  Future<void> softPulse();         // v1.x warning
}
```

Implementation: `HapticFeedback` + vibration via `SystemSound`/the notification plugin;
desktop/Web: no-op with `hasVibrator = false`.

## ImagePickerPort

```dart
abstract interface class ImagePickerPort {
  /// Opens the system picker. Returns null if cancelled.
  Future<PickedImage?> pickImage();
}
final class PickedImage { final Uint8List bytes; final String? mimeType; final String? name; }
```

Implementation: `image_picker` (mobile/Web) delegating to `file_selector` (desktop). Never
requests broad storage permission (verified in the manifest and in E2E).

## ImageProcessor (pure Dart, not a platform port)

```dart
abstract interface class ImageProcessor {
  /// Decodes, applies framing, crops, resizes and re-encodes without metadata.
  Future<ProcessedImage> process(Uint8List input, FrameSpec frame);
}
final class FrameSpec { final double centerX, centerY; final double zoom; } // normalized 0..1
final class ProcessedImage { final Uint8List jpegBytes; final int width, height; }
// Errors: UnsupportedImageFormat, CorruptImage, ImageTooLarge (> 100 MP)
```

## SystemSettingsPort (Android)

```dart
abstract interface class SystemSettingsPort {
  Future<bool> openExactAlarmSettings();
  Future<bool> openAppNotificationSettings();
  Future<bool> openBatteryOptimizationSettings();
}
```

`MethodChannel('vtc/system_settings')` with methods `openExactAlarm`, `openNotifications`,
`openBatteryOptimization` → `Boolean`. Other platforms: `false`.

## ExternalLinkPort

```dart
abstract interface class ExternalLinkPort {
  Future<bool> open(Uri uri); // only called after the parental gate + confirmation
}
```

## HomeWidgetPort (v1.x)

```dart
abstract interface class HomeWidgetPort {
  Future<void> publish(HomeWidgetPayload payload);
  Stream<Uri> get launches; // deep links coming from the widget
}
```

## AppLifecyclePort

A wrapper around `AppLifecycleListener` for tests (`Stream<AppLifecycleState>`).

## Injection

All ports are Riverpod providers in `lib/core/platform/providers.dart`, overridden in `main_*`
per platform (selection by `defaultTargetPlatform`/`kIsWeb`) and in tests through
`ProviderContainer(overrides: [...])`.
