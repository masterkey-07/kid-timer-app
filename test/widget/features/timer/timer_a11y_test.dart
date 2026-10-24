import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

final _running = TimerSession(
  id: 'a11y-run',
  config: TimerConfig.defaults,
  status: SessionStatus.running,
  startedAt: testNow,
  endsAt: testNow.add(const Duration(minutes: 5)),
);

final _paused = TimerSession(
  id: 'a11y-paused',
  config: TimerConfig.defaults,
  status: SessionStatus.paused,
  startedAt: testNow,
  pausedRemaining: const Duration(minutes: 3),
);

final _finished = TimerSession(
  id: 'a11y-done',
  config: TimerConfig.defaults,
  status: SessionStatus.finished,
  startedAt: testNow.subtract(const Duration(minutes: 5)),
  endsAt: testNow,
);

const _controlsAlwaysVisible = AppSettings(childLockEnabled: false);

/// The screens under test, by the session that opens them.
final Map<String, TimerSession?> _screens = {
  'home': null,
  'run': _running,
  'run (paused)': _paused,
  'finished': _finished,
};

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> pumpScreen(
    WidgetTester tester,
    TimerSession? session, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    ScreenClass screen = ScreenClass.compact,
  }) async {
    if (session != null) await dependencies.sessionRepository.save(session);
    await tester.pumpKidTimerApp(
      dependencies,
      session: session,
      settings: _controlsAlwaysVisible,
      locale: locale,
      textScale: textScale,
      screen: screen,
    );
    // Past the final screen's celebration and hint.
    await tester.pump(const Duration(seconds: 3));
  }

  for (final MapEntry(key: name, value: session) in _screens.entries) {
    for (final locale in const [Locale('pt'), Locale('en')]) {
      testWidgets('$name meets the guidelines ($locale)', (tester) async {
        await pumpScreen(tester, session, locale: locale);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('$name fits at 200% font ($locale)', (tester) async {
        await pumpScreen(
          tester,
          session,
          locale: locale,
          textScale: maxTextScale,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$name fits at 200% font in a short landscape window', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        session,
        textScale: maxTextScale,
        screen: ScreenClass.compactLandscape,
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the countdown dial tells screen readers the time left', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    dependencies.now = testNow.add(const Duration(seconds: 48));
    await pumpScreen(tester, _running);

    expect(
      tester.getSemantics(find.byKey(const Key('run.dial'))),
      matchesSemantics(
        label: 'Time remaining',
        value: '4 minutes and 12 seconds',
      ),
    );
    semantics.dispose();
  });

  testWidgets('the countdown digits are hidden from screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, _running);

    expect(
      find.descendant(
        of: find.byKey(const Key('run.digits')),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the final screen is one button that goes back', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, _finished);

    expect(find.semantics.byLabel("Time's up. Tap to go back"), findsOne);
    semantics.dispose();
  });
}
