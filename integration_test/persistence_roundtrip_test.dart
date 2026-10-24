import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';

/// The session and the settings survive closing and reopening the real
/// storage of each platform: files on Android and Linux, IndexedDB on the
/// Web (FR-013).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const clock = Clock();
  const storageFolder = 'persistence_roundtrip_test';

  setUp(() => Hive.initFlutter(storageFolder));

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  /// Closes everything, as killing the app would, and opens it again.
  Future<PersistenceBoxes> reopen() async {
    await Hive.close();
    await Hive.initFlutter(storageFolder);
    return await openPersistence(clock: clock);
  }

  testWidgets('a running session comes back exactly as saved', (_) async {
    final now = clock.now().toUtc();
    final session = TimerSession(
      id: 'roundtrip',
      config: TimerConfig(
        duration: TimerDuration(const Duration(minutes: 12)),
        tickEnabled: true,
        showDigits: false,
      ),
      status: SessionStatus.running,
      startedAt: now,
      endsAt: now.add(const Duration(minutes: 12)),
      scheduledNotificationIds: const [42],
    );
    final boxes = await openPersistence(clock: clock);
    await SessionRepository(boxes.session).save(session);

    final reopened = await reopen();

    expect(SessionRepository(reopened.session).load(), session);
  });

  testWidgets('settings and onboarding flags come back as saved', (_) async {
    const settings = AppSettings(
      childLockEnabled: false,
      onboarding: OnboardingFlags(
        webKeepOpenSeen: true,
        exactAlarmExplained: true,
        iosSilentWarned: true,
      ),
    );
    final boxes = await openPersistence(clock: clock);
    await SettingsRepository(boxes.settings).save(settings);

    final reopened = await reopen();

    expect(SettingsRepository(reopened.settings).load(), settings);
  });

  testWidgets('a cleared session stays cleared', (_) async {
    final now = clock.now().toUtc();
    final boxes = await openPersistence(clock: clock);
    final repository = SessionRepository(boxes.session);
    await repository.save(
      TimerSession(
        id: 'cleared',
        config: TimerConfig.defaults,
        status: SessionStatus.running,
        startedAt: now,
        endsAt: now.add(const Duration(minutes: 5)),
      ),
    );
    await repository.clear();

    final reopened = await reopen();

    expect(SessionRepository(reopened.session).load(), isNull);
  });
}
