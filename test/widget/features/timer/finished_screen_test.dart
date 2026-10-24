import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

import '../../../helpers/test_app.dart';

final _finished = TimerSession(
  id: 'done-1',
  config: TimerConfig.defaults,
  status: SessionStatus.finished,
  startedAt: testNow.subtract(const Duration(minutes: 5)),
  endsAt: testNow,
  scheduledNotificationIds: const [42],
);

const _dismissArea = Key('finished.dismissArea');

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> pumpFinished(WidgetTester tester) async {
    await dependencies.sessionRepository.save(_finished);
    await tester.pumpKidTimerApp(dependencies, session: _finished);
  }

  /// Waits out the 800 ms guard against accidental touches.
  Future<void> pastTheGuard(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  Future<void> expectBackHome(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(dependencies.sessionRepository.load(), isNull);
  }

  testWidgets('shows the celebration', (tester) async {
    await pumpFinished(tester);

    expect(find.byKey(const Key('finished.screen')), findsOneWidget);
    expect(find.byKey(const Key('finished.title')), findsOneWidget);
    expect(find.byKey(const Key('finished.image')), findsOneWidget);
  });

  testWidgets('a tap after the guard acknowledges and goes home (FR-005)', (
    tester,
  ) async {
    await pumpFinished(tester);
    await pastTheGuard(tester);

    await tester.tap(find.byKey(_dismissArea));

    await expectBackHome(tester);
  });

  testWidgets('ignores taps during the first 800 ms', (tester) async {
    await pumpFinished(tester);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(_dismissArea));
    await tester.pump();

    expect(find.byKey(const Key('finished.screen')), findsOneWidget);
    expect(
      dependencies.sessionRepository.load()!.status,
      SessionStatus.finished,
    );
  });

  for (final key in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.escape,
  ]) {
    testWidgets('${key.keyLabel} acts as the tap', (tester) async {
      await pumpFinished(tester);
      await pastTheGuard(tester);

      await tester.sendKeyEvent(key);

      await expectBackHome(tester);
    });
  }

  testWidgets('stays until tapped, even after 10 minutes', (tester) async {
    await pumpFinished(tester);

    await tester.pump(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 1));

    expect(find.byKey(const Key('finished.screen')), findsOneWidget);
  });

  testWidgets('announces "Time\'s up" to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpFinished(tester);
    await tester.pump();

    final announcements = tester.takeAnnouncements();
    expect(announcements.map((a) => a.message), contains("Time's up!"));
    expect(
      announcements.firstWhere((a) => a.message == "Time's up!").assertiveness,
      Assertiveness.assertive,
    );
    semantics.dispose();
  });

  testWidgets('repeats the sound every 30 s, up to 3 times in all', (
    tester,
  ) async {
    await pumpFinished(tester);
    int alarms() => dependencies.audio.calls
        .where((call) => call.startsWith('playAlarm'))
        .length;

    await tester.pump(const Duration(seconds: 30));
    expect(alarms(), 1);
    await tester.pump(const Duration(seconds: 30));
    expect(alarms(), 2);
    await tester.pump(const Duration(minutes: 5));
    expect(alarms(), 2);
  });

  testWidgets('keeps the screen on for 10 minutes', (tester) async {
    await pumpFinished(tester);
    expect(dependencies.wakeLock.enabled, true);

    await tester.pump(const Duration(minutes: 10));

    expect(dependencies.wakeLock.enabled, false);
  });

  testWidgets('removes the timer notification from the tray', (tester) async {
    await pumpFinished(tester);

    expect(dependencies.alarms.cancelledIds, [42]);
  });
}
