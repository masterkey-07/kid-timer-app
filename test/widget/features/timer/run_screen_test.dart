import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/test_app.dart';

const _controlsAlwaysVisible = AppSettings(childLockEnabled: false);

TimerSession _running({bool showDigits = true}) => TimerSession(
  id: 'run-1',
  config: TimerConfig(
    duration: TimerDuration(const Duration(minutes: 10)),
    showDigits: showDigits,
  ),
  status: SessionStatus.running,
  startedAt: testNow,
  endsAt: testNow.add(const Duration(minutes: 10)),
  scheduledNotificationIds: const [7],
);

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> pumpRun(WidgetTester tester, {TimerSession? session}) async {
    final running = session ?? _running();
    await dependencies.sessionRepository.save(running);
    await tester.pumpKidTimerApp(
      dependencies,
      session: running,
      settings: _controlsAlwaysVisible,
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapAndSettleDialog(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  SessionStatus? savedStatus() => dependencies.sessionRepository.load()?.status;

  testWidgets('shows the dial and the remaining time', (tester) async {
    dependencies.now = testNow.add(const Duration(minutes: 5, seconds: 48));
    await pumpRun(tester);

    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    expect(find.byKey(const Key('run.dial')), findsOneWidget);
    expect(tester.textOf('run.digits'), '04:12');
  });

  testWidgets('hides the digits when showDigits is off (FR-004)', (
    tester,
  ) async {
    await pumpRun(tester, session: _running(showDigits: false));

    expect(find.byKey(const Key('run.dial')), findsOneWidget);
    expect(find.byKey(const Key('run.digits')), findsNothing);
  });

  testWidgets('the dial repaints inside its own RepaintBoundary', (
    tester,
  ) async {
    await pumpRun(tester);

    final painter = find.descendant(
      of: find.byKey(const Key('run.dial')),
      matching: find.byType(CustomPaint),
    );
    expect(
      find.ancestor(of: painter.first, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('run.dial')),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });

  testWidgets('the digits follow the clock', (tester) async {
    await pumpRun(tester);

    dependencies.now = testNow.add(const Duration(minutes: 1, seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.textOf('run.digits'), '08:59');
  });

  group('pause and resume (FR-003)', () {
    testWidgets('pause freezes the time and resume continues', (tester) async {
      await pumpRun(tester);
      dependencies.now = testNow.add(const Duration(minutes: 2));

      await tapAndSettleDialog(tester, 'run.pauseResume');

      expect(savedStatus(), SessionStatus.paused);
      dependencies.now = testNow.add(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.textOf('run.digits'), '08:00');

      await tapAndSettleDialog(tester, 'run.pauseResume');

      expect(savedStatus(), SessionStatus.running);
      expect(tester.textOf('run.digits'), '08:00');
    });
  });

  group('restart', () {
    testWidgets('restarts right away with at least half left', (tester) async {
      await pumpRun(tester);
      dependencies.now = testNow.add(const Duration(minutes: 4));

      await tapAndSettleDialog(tester, 'run.restart');

      expect(find.byKey(const Key('confirm.dialog')), findsNothing);
      expect(
        dependencies.sessionRepository.load()!.endsAt,
        testNow.add(const Duration(minutes: 14)),
      );
    });

    testWidgets('asks first with less than half left', (tester) async {
      await pumpRun(tester);
      dependencies.now = testNow.add(const Duration(minutes: 6));

      await tapAndSettleDialog(tester, 'run.restart');
      expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
      await tapAndSettleDialog(tester, 'confirm.confirm');

      expect(
        dependencies.sessionRepository.load()!.endsAt,
        testNow.add(const Duration(minutes: 16)),
      );
    });

    testWidgets('declining keeps the timer as it was', (tester) async {
      await pumpRun(tester);
      dependencies.now = testNow.add(const Duration(minutes: 6));

      await tapAndSettleDialog(tester, 'run.restart');
      await tapAndSettleDialog(tester, 'confirm.cancel');

      expect(
        dependencies.sessionRepository.load()!.endsAt,
        testNow.add(const Duration(minutes: 10)),
      );
    });
  });

  group('stop', () {
    testWidgets('asks for confirmation, then goes home', (tester) async {
      await pumpRun(tester);

      await tapAndSettleDialog(tester, 'run.stop');
      expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
      await tapAndSettleDialog(tester, 'confirm.confirm');

      expect(find.byKey(const Key('home.screen')), findsOneWidget);
      expect(dependencies.sessionRepository.load(), isNull);
      // On Android the alarm was already cancelled in front (single ring);
      // stopping cancels it too and never schedules it again.
      expect(dependencies.alarms.cancelledIds.last, 7);
      expect(dependencies.alarms.scheduledRequests, isEmpty);
    });

    testWidgets('declining keeps counting', (tester) async {
      await pumpRun(tester);

      await tapAndSettleDialog(tester, 'run.stop');
      await tapAndSettleDialog(tester, 'confirm.cancel');

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
      expect(savedStatus(), SessionStatus.running);
    });
  });

  testWidgets('time up with the app open opens the final screen', (
    tester,
  ) async {
    await pumpRun(tester);

    dependencies.now = testNow.add(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 10));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('finished.screen')), findsOneWidget);
    expect(
      dependencies.audio.calls.where((call) => call.startsWith('playAlarm')),
      hasLength(1),
    );
  });
}
