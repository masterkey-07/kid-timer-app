import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';

import 'fakes/fake_alarm_scheduler.dart';
import 'fakes/fake_audio.dart';
import 'fakes/fake_external_link.dart';
import 'fakes/fake_fullscreen.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_image_picker.dart';
import 'fakes/fake_lifecycle.dart';
import 'fakes/fake_system_settings.dart';
import 'fakes/fake_wakelock.dart';
import 'pump_app.dart';

/// The instant every app-level test starts at.
final testNow = DateTime.utc(2026, 10, 23, 12);

var _boxCount = 0;

/// Fakes for every port, in-memory storage and a controllable clock: what
/// bootstrap provides in the real app.
class TestAppDependencies {
  new _(this._sessionBox, this._settingsBox, Clock? clock) {
    this.clock = clock ?? Clock(() => now);
    alarms = FakeAlarmScheduler(clock: this.clock);
    sessionRepository = SessionRepository(_sessionBox);
    settingsRepository = SettingsRepository(_settingsBox);
  }

  /// Opens empty in-memory boxes. With [clock] (e.g. the real one) [now]
  /// is ignored.
  static Future<TestAppDependencies> create({Clock? clock}) async {
    final id = _boxCount++;
    return TestAppDependencies._(
      await Hive.openBox<Map<dynamic, dynamic>>(
        'test_session_$id',
        bytes: Uint8List(0),
      ),
      await Hive.openBox<Map<dynamic, dynamic>>(
        'test_settings_$id',
        bytes: Uint8List(0),
      ),
      clock,
    );
  }

  final Box<Map<dynamic, dynamic>> _sessionBox;
  final Box<Map<dynamic, dynamic>> _settingsBox;

  /// What the clock reads; tests move it forward.
  DateTime now = testNow;

  late final Clock clock;
  late final FakeAlarmScheduler alarms;
  late final SessionRepository sessionRepository;
  late final SettingsRepository settingsRepository;

  /// The audio fake; a test may swap it before building the overrides.
  FakeAudio audio = FakeAudio();
  final haptics = FakeHaptics();
  final wakeLock = FakeWakeLock();

  /// A real wakelock to use instead of [wakeLock] (integration tests).
  WakeLockPort? wakeLockOverride;
  final fullscreen = FakeFullscreen();
  final lifecycle = FakeLifecycle();
  final systemSettings = FakeSystemSettings();

  /// The platform the app believes it runs on; tests may change it.
  AppPlatform platform = AppPlatform.android;

  /// The overrides for a `ProviderScope` restoring [session] and
  /// [settings].
  List<Override> overrides({
    TimerSession? session,
    AppSettings settings = AppSettings.initial,
    bool Function(String presetId)? presetExists,
  }) => [
    clockProvider.overrideWithValue(clock),
    sessionRepositoryProvider.overrideWithValue(sessionRepository),
    settingsRepositoryProvider.overrideWithValue(settingsRepository),
    restoredSessionProvider.overrideWithValue(session),
    restoredSettingsProvider.overrideWithValue(settings),
    presetExistsProvider.overrideWithValue(presetExists ?? (_) => false),
    ...portOverrides(),
  ];

  /// The fake platform ports alone, for tests that use the real storage
  /// and startup path.
  List<Override> portOverrides() => [
    appPlatformProvider.overrideWithValue(platform),
    alarmSchedulerProvider.overrideWithValue(alarms),
    audioProvider.overrideWithValue(audio),
    hapticsProvider.overrideWithValue(haptics),
    wakeLockProvider.overrideWithValue(wakeLockOverride ?? wakeLock),
    fullscreenProvider.overrideWithValue(fullscreen),
    appLifecycleProvider.overrideWithValue(lifecycle),
    imagePickerProvider.overrideWithValue(FakeImagePicker()),
    systemSettingsProvider.overrideWithValue(systemSettings),
    externalLinkProvider.overrideWithValue(FakeExternalLink()),
  ];

  /// Makes every later session write fail, as a full disk would.
  Future<void> breakSessionStorage() => _sessionBox.close();

  /// Makes every later settings write fail, as a full disk would.
  Future<void> breakSettingsStorage() => _settingsBox.close();

  /// Closes the boxes.
  Future<void> dispose() async {
    await lifecycle.dispose();
    if (_sessionBox.isOpen) await _sessionBox.close();
    if (_settingsBox.isOpen) await _settingsBox.close();
  }
}

extension PumpKidTimerApp on WidgetTester {
  /// Pumps the whole app (router included) over [dependencies], in
  /// [locale] and sized as [screen]. Does not settle: the countdown dial
  /// repaints on every frame.
  Future<void> pumpKidTimerApp(
    TestAppDependencies dependencies, {
    TimerSession? session,
    AppSettings settings = AppSettings.initial,
    ScreenClass screen = ScreenClass.compact,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    view
      ..physicalSize = screen.size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    platformDispatcher
      ..localesTestValue = [locale]
      ..textScaleFactorTestValue = textScale;
    addTearDown(platformDispatcher.clearAllTestValues);

    await pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(session: session, settings: settings),
        child: const KidTimerApp(),
      ),
    );
    await pump();
  }

  /// The text shown by the widget with [key].
  String textOf(String key) => widget<Text>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
  ).data!;
}
