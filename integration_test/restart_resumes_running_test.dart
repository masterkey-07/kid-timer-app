import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';
import 'package:visual_time_counter/startup_state.dart';

import '../test/helpers/test_app.dart';

/// An app killed while a timer ran and reopened before its end continues
/// the countdown from the real remaining time (US2 acceptance 3), using
/// the real storage and startup path.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory storage;
  late TestAppDependencies fakes;

  setUp(() async {
    storage = Directory.systemTemp.createTempSync('restart_running_');
    Hive.init(storage.path);
    fakes = await TestAppDependencies.create(clock: const Clock());
  });

  tearDown(() async {
    await fakes.dispose();
    await Hive.close();
    storage.deleteSync(recursive: true);
  });

  testWidgets('a session still running reopens /run with the real time', (
    tester,
  ) async {
    // Started 2 minutes ago for 5 minutes, then the app was killed.
    final now = clock.now().toUtc();
    final boxes = await openPersistence(clock: const Clock());
    await SessionRepository(boxes.session).save(
      TimerSession(
        id: 'killed-while-running',
        config: TimerConfig.defaults,
        status: SessionStatus.running,
        startedAt: now.subtract(const Duration(minutes: 2)),
        endsAt: now.add(const Duration(minutes: 3)),
      ),
    );
    await Hive.close();

    final reopened = await openPersistence(clock: const Clock());
    final startup = await loadStartupState(
      boxes: reopened,
      clock: const Clock(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...fakes.portOverrides(), ...startup.overrides],
        child: const KidTimerApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    expect(startup.session!.status, SessionStatus.running);
    expect(tester.textOf('run.digits'), anyOf('03:00', '02:59', '02:58'));
  });
}
