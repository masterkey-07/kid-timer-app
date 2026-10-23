import 'dart:typed_data';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/image_picker/image_picker_port.dart';

import '../helpers/fakes/fake_alarm_scheduler.dart';
import '../helpers/fakes/fake_audio.dart';
import '../helpers/fakes/fake_external_link.dart';
import '../helpers/fakes/fake_fullscreen.dart';
import '../helpers/fakes/fake_haptics.dart';
import '../helpers/fakes/fake_image_picker.dart';
import '../helpers/fakes/fake_lifecycle.dart';
import '../helpers/fakes/fake_system_settings.dart';
import '../helpers/fakes/fake_wakelock.dart';
import 'alarm_scheduler_contract.dart';
import 'audio_contract.dart';
import 'wakelock_contract.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);

  runAlarmSchedulerContract('FakeAlarmScheduler', () async {
    final fake = FakeAlarmScheduler(clock: Clock.fixed(now));
    return (
      scheduler: fake,
      now: () => now,
      pending: () async => [
        for (final request in fake.pending.values)
          (id: request.id, title: request.title),
      ],
    );
  });

  runAlarmSchedulerContract('FakeAlarmScheduler (unsupported)', () async {
    final fake = FakeAlarmScheduler(
      clock: Clock.fixed(now),
      capabilities: AlarmCapabilities.unsupported,
    );
    return (
      scheduler: fake,
      now: () => now,
      pending: () async => [
        for (final request in fake.pending.values)
          (id: request.id, title: request.title),
      ],
    );
  }, supportsScheduling: false);

  runWakelockContract('FakeWakeLock', () async => FakeWakeLock());
  runAudioContract('FakeAudio', () async => FakeAudio());

  group('FakeAlarmScheduler controls', () {
    test(
      'records requests and simulates taps and the launch payload',
      () async {
        final fake = FakeAlarmScheduler(clock: Clock.fixed(now))
          ..launchPayloadValue = 'vtc://run';
        final taps = <String>[];
        fake.notificationTaps.listen(taps.add);

        fake.simulateTap('vtc://run');
        await Future<void>.delayed(Duration.zero);

        expect(taps, ['vtc://run']);
        expect(await fake.launchPayload(), 'vtc://run');
      },
    );

    test(
      'permission requests and the exact alarm setting are recorded',
      () async {
        final fake = FakeAlarmScheduler(clock: Clock.fixed(now))
          ..permissionAfterRequest = PermissionState.granted;

        expect(
          await fake.requestNotificationPermission(),
          PermissionState.granted,
        );
        expect(await fake.openExactAlarmSettings(), isTrue);
        expect(fake.calls, [
          'requestNotificationPermission',
          'openExactAlarmSettings',
        ]);
      },
    );

    test('denied notifications make schedule fail', () async {
      final fake = FakeAlarmScheduler(
        clock: Clock.fixed(now),
        capabilities: const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.denied,
          exactAlarm: PermissionState.granted,
        ),
      );

      final result = await fake.schedule(
        AlarmRequest(
          id: 1,
          groupKey: 'g',
          fireAtUtc: now.add(const Duration(minutes: 1)),
          kind: AlarmKind.end,
          title: 't',
          body: 'b',
          sound: SoundId.chimeSoft,
          payload: 'vtc://run',
        ),
      );

      expect(result, const Failed(ScheduleFailure.permissionDenied));
    });

    test('inexact scheduling reports Scheduled(isExact: false)', () async {
      final fake = FakeAlarmScheduler(
        clock: Clock.fixed(now),
        capabilities: const AlarmCapabilities(
          scheduling: SchedulingSupport.inexactOnly,
          notifications: PermissionState.granted,
          exactAlarm: PermissionState.denied,
        ),
      );

      final result = await fake.schedule(
        AlarmRequest(
          id: 1,
          groupKey: 'g',
          fireAtUtc: now.add(const Duration(minutes: 1)),
          kind: AlarmKind.end,
          title: 't',
          body: 'b',
          sound: SoundId.chimeSoft,
          payload: 'vtc://run',
        ),
      );

      expect(result, const Scheduled(isExact: false));
    });
  });

  test('FakeAudio records calls in order', () async {
    final audio = FakeAudio()..systemVolumeValue = 0;

    await audio.startTicking(volume: 0.3);
    await audio.playAlarm(SoundId.chimeSoft, volume: 0.7, repeat: 3);
    await audio.stopAll();

    expect(audio.calls, [
      'startTicking(0.3)',
      'playAlarm(chime_soft, 0.7, 3)',
      'stopAll',
    ]);
    expect(audio.isTicking, isFalse);
    expect(await audio.systemVolume(), 0);
  });

  test('FakeFullscreen tracks the state', () async {
    final fullscreen = FakeFullscreen();

    await fullscreen.enter();
    expect(fullscreen.isFullscreen, isTrue);
    await fullscreen.exit();
    expect(fullscreen.isFullscreen, isFalse);
    expect(fullscreen.isSupported, isTrue);
  });

  test('FakeHaptics records calls and reports the vibrator', () async {
    final haptics = FakeHaptics(hasVibrator: false);

    await haptics.selectionTick();
    await haptics.alarmPattern();
    await haptics.softPulse();

    expect(haptics.hasVibrator, isFalse);
    expect(haptics.calls, ['selectionTick', 'alarmPattern', 'softPulse']);
  });

  test('FakeImagePicker returns the queued result once', () async {
    final picked = PickedImage(
      bytes: Uint8List.fromList([1, 2]),
      name: 'a.jpg',
    );
    final picker = FakeImagePicker()..nextResult = picked;

    expect(await picker.pickImage(), picked);
    expect(await picker.pickImage(), isNull);
    expect(picker.pickCount, 2);
  });

  test('FakeSystemSettings records which screen was opened', () async {
    final settings = FakeSystemSettings(result: false);

    expect(await settings.openExactAlarmSettings(), isFalse);
    await settings.openAppNotificationSettings();
    await settings.openBatteryOptimizationSettings();

    expect(settings.opened, [
      'exactAlarm',
      'notifications',
      'batteryOptimization',
    ]);
  });

  test('FakeExternalLink records opened links', () async {
    final links = FakeExternalLink();
    final uri = Uri.parse('https://github.com/masterkey-07/kid-timer-app');

    expect(await links.open(uri), isTrue);
    expect(links.opened, [uri]);
  });

  test('FakeLifecycle emits simulated states', () async {
    final lifecycle = FakeLifecycle();
    final states = <AppLifecycleState>[];
    lifecycle.states.listen(states.add);

    lifecycle.emit(AppLifecycleState.paused);
    lifecycle.emit(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(states, [AppLifecycleState.paused, AppLifecycleState.resumed]);
    await lifecycle.dispose();
  });
}
