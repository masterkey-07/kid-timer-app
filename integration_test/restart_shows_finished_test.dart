import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/persistence/boxes.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';
import 'package:visual_time_counter/startup_state.dart';

import '../test/helpers/test_app.dart';

/// An app killed while a timer ran and reopened after its end shows the
/// final screen until tapped (FR-005, contracts/ui/03), using the real
/// storage and startup path.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory storage;
  late TestAppDependencies fakes;

  setUp(() async {
    storage = Directory.systemTemp.createTempSync('restart_finished_');
    Hive.init(storage.path);
    fakes = await TestAppDependencies.create();
  });

  tearDown(() async {
    await fakes.dispose();
    await Hive.close();
    storage.deleteSync(recursive: true);
  });

  /// Saves a session that ended a minute ago, then "kills" the app.
  Future<void> runTimerAndKillApp() async {
    final now = clock.now().toUtc();
    final boxes = await openPersistence(clock: const Clock());
    await SessionRepository(boxes.session).save(
      TimerSession(
        id: 'killed-run',
        config: TimerConfig.defaults,
        status: SessionStatus.running,
        startedAt: now.subtract(const Duration(minutes: 6)),
        endsAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    await Hive.close();
  }

  /// Boots like main(): open storage, load and reconcile, then run the app.
  Future<void> relaunch(WidgetTester tester) async {
    final boxes = await openPersistence(clock: const Clock());
    final startup = await loadStartupState(boxes: boxes, clock: const Clock());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...fakes.portOverrides(), ...startup.overrides],
        child: const KidTimerApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
  }

  TimerSession? storedSession() =>
      SessionRepository(Hive.box<Map<dynamic, dynamic>>(BoxNames.session))
          .load();

  testWidgets('an expired, unacknowledged session reopens /finished', (
    tester,
  ) async {
    await runTimerAndKillApp();

    await relaunch(tester);

    expect(find.byKey(const Key('finished.screen')), findsOneWidget);
    expect(storedSession()!.status, SessionStatus.finished);
  });

  testWidgets('it keeps reopening /finished until tapped, then home', (
    tester,
  ) async {
    await runTimerAndKillApp();
    await relaunch(tester);
    await tester.pumpWidget(const SizedBox());
    await Hive.close();

    await relaunch(tester);
    expect(find.byKey(const Key('finished.screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('finished.dismissArea')));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(storedSession(), isNull);
  });
}
