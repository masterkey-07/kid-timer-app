import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/persistence/boxes.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';
import 'package:visual_time_counter/startup_state.dart';

import '../helpers/hive_test_utils.dart';

void main() {
  useTemporaryHive();

  final now = DateTime.utc(2026, 10, 23, 12, 10);
  final clock = Clock.fixed(now);

  TimerSession running({required DateTime endsAt}) => TimerSession(
    id: 's1',
    config: TimerConfig.defaults,
    status: SessionStatus.running,
    startedAt: endsAt.subtract(const Duration(minutes: 5)),
    endsAt: endsAt,
  );

  Future<PersistenceBoxes> open() => openPersistence(clock: clock);

  test(
    'removes own image bytes and metadata left without each other',
    () async {
      final boxes = await open();
      await boxes.userImages.put('bytes-only', Uint8List.fromList([1, 2]));
      await boxes.userImagesMeta.put('meta-only', {'schemaVersion': 1});

      final state = await loadStartupState(boxes: boxes, clock: clock);

      expect(boxes.userImages.isEmpty, isTrue);
      expect(boxes.userImagesMeta.isEmpty, isTrue);
      final container = ProviderContainer(overrides: state.overrides);
      addTearDown(container.dispose);
      expect(
        container.read(userImageStorageProvider).meta,
        boxes.userImagesMeta,
      );
    },
  );

  test('first launch: no session, initial settings, no issues', () async {
    final state = await loadStartupState(boxes: await open(), clock: clock);

    expect(state.session, isNull);
    expect(state.settings, AppSettings.initial);
    expect(state.issues, isEmpty);
  });

  test('restores a running session before its end', () async {
    final boxes = await open();
    final session = running(endsAt: now.add(const Duration(minutes: 2)));
    await SessionRepository(boxes.session).save(session);

    final state = await loadStartupState(boxes: boxes, clock: clock);

    expect(state.session, session);
  });

  test('finishes and persists a session whose end has passed', () async {
    final boxes = await open();
    await SessionRepository(boxes.session)
        .save(running(endsAt: now.subtract(const Duration(hours: 3))));

    final state = await loadStartupState(boxes: boxes, clock: clock);

    expect(state.session!.status, SessionStatus.finished);
    expect(state.session!.finishedAcknowledged, isFalse);
    expect(
      SessionRepository(boxes.session).load()!.status,
      SessionStatus.finished,
    );
  });

  test('restores the saved settings', () async {
    final boxes = await open();
    final settings = AppSettings.initial.copyWith(childLockEnabled: false);
    await SettingsRepository(boxes.settings).save(settings);

    final state = await loadStartupState(boxes: boxes, clock: clock);

    expect(state.settings, settings);
  });

  test('an unreadable session is cleared and reported', () async {
    final boxes = await open();
    await boxes.session.put('timer', {'schemaVersion': 1, 'status': 'running'});

    final state = await loadStartupState(boxes: boxes, clock: clock);

    expect(state.session, isNull);
    expect(state.issues, contains(StartupIssue.sessionUnreadable));
    expect(boxes.session.get('timer'), isNull);
  });

  test(
    'unreadable settings fall back to the defaults and are reported',
    () async {
      final boxes = await open();
      await boxes.settings.put('app', {'schemaVersion': 1});

      final state = await loadStartupState(boxes: boxes, clock: clock);

      expect(state.settings, AppSettings.initial);
      expect(state.issues, contains(StartupIssue.settingsUnreadable));
    },
  );

  test('a migration failure is reported', () async {
    final presets = await Hive.openBox<Map<dynamic, dynamic>>(BoxNames.presets);
    await presets.put('p', {'schemaVersion': 99});
    await presets.close();

    final state = await loadStartupState(boxes: await open(), clock: clock);

    expect(state.issues, contains(StartupIssue.migrationFailed));
  });

  test('provides overrides for the restored state and repositories', () async {
    final boxes = await open();
    await boxes.presets.put('p1', {'schemaVersion': 1});
    final session = running(endsAt: now.add(const Duration(minutes: 1)));
    await SessionRepository(boxes.session).save(session);
    final state = await loadStartupState(boxes: boxes, clock: clock);

    final container = ProviderContainer(overrides: state.overrides);
    addTearDown(container.dispose);

    expect(container.read(restoredSessionProvider), session);
    expect(container.read(restoredSettingsProvider), AppSettings.initial);
    expect(container.read(sessionRepositoryProvider).load(), session);
    expect(
      container.read(settingsRepositoryProvider).load(),
      AppSettings.initial,
    );
    expect(container.read(presetExistsProvider)('p1'), isTrue);
    expect(container.read(presetExistsProvider)('p2'), isFalse);
    expect(container.read(startupIssuesProvider), isEmpty);
    expect(container.read(clockProvider).now(), now);
  });
}
