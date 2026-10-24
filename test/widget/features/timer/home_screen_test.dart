import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

AppSettings _withDuration(Duration duration) =>
    AppSettings(lastConfig: TimerConfig(duration: TimerDuration(duration)));

const _dial = Key('home.dial');
const _start = Key('home.start');

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> pumpHome(
    WidgetTester tester, {
    Duration duration = const Duration(minutes: 5),
    ScreenClass screen = ScreenClass.compact,
  }) async {
    await tester.pumpKidTimerApp(
      dependencies,
      settings: _withDuration(duration),
      screen: screen,
    );
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

  testWidgets('starts from the last duration used (FR-006)', (tester) async {
    await pumpHome(tester, duration: const Duration(minutes: 7));

    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(tester.textOf('home.digits'), '07:00');
  });

  group('quick buttons (FR-001)', () {
    testWidgets('+1, +5 and −1 adjust the duration', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(const Key('home.plus1')));
      await tester.pump();
      expect(tester.textOf('home.digits'), '06:00');

      await tester.tap(find.byKey(const Key('home.plus5')));
      await tester.pump();
      expect(tester.textOf('home.digits'), '11:00');

      await tester.tap(find.byKey(const Key('home.minus1')));
      await tester.pump();
      expect(tester.textOf('home.digits'), '10:00');
    });

    testWidgets('−1 stops at 10 s and is then disabled', (tester) async {
      await pumpHome(tester, duration: const Duration(seconds: 50));

      await tester.tap(find.byKey(const Key('home.minus1')));
      await tester.pump();

      expect(tester.textOf('home.digits'), '00:10');
      expect(isEnabled(tester, const Key('home.minus1')), false);
      expect(isEnabled(tester, _start), true);
    });

    testWidgets('+1 is disabled at 2 h', (tester) async {
      await pumpHome(tester, duration: const Duration(hours: 2));

      expect(tester.textOf('home.digits'), '2:00:00');
      expect(isEnabled(tester, const Key('home.plus1')), false);
    });

    testWidgets('+5 clamps to 2 h and says so', (tester) async {
      await pumpHome(tester, duration: const Duration(minutes: 118));

      await tester.tap(find.byKey(const Key('home.plus5')));
      await tester.pump();

      expect(tester.textOf('home.digits'), '2:00:00');
      expect(find.byKey(const Key('home.maxReached')), findsOneWidget);
    });
  });

  group('dragging the dial (FR-001)', () {
    Future<void> dragAlongRing(
      WidgetTester tester,
      List<Offset> unitPoints,
    ) async {
      final rect = tester.getRect(find.byKey(_dial));
      final radius = rect.shortestSide / 2;
      Offset at(Offset unit) => rect.center + unit * radius;

      final gesture = await tester.startGesture(at(unitPoints.first));
      for (final point in unitPoints.skip(1)) {
        await gesture.moveTo(at(point));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();
    }

    testWidgets('sets the duration from the edge position', (tester) async {
      await pumpHome(tester);

      // 12 o'clock → 9 o'clock: a quarter of the 60 min scale.
      await dragAlongRing(tester, const [
        Offset(0, -1),
        Offset(-0.38, -0.92),
        Offset(-0.71, -0.71),
        Offset(-0.92, -0.38),
        Offset(-1, 0),
      ]);

      expect(tester.textOf('home.digits'), '15:00');
    });

    testWidgets('ticks the haptics on whole minutes', (tester) async {
      await pumpHome(tester);

      await dragAlongRing(tester, const [Offset(0, -1), Offset(-0.71, -0.71)]);

      expect(dependencies.haptics.calls, contains('selectionTick'));
    });

    testWidgets('touching the middle of the dial does nothing', (tester) async {
      await pumpHome(tester);

      await dragAlongRing(tester, const [Offset.zero, Offset(-0.3, 0)]);

      expect(tester.textOf('home.digits'), '05:00');
    });
  });

  group('keyboard on the dial', () {
    Future<void> focusDial(WidgetTester tester) async {
      final painter = find.descendant(
        of: find.byKey(_dial),
        matching: find.byType(CustomPaint),
      );
      Focus.of(tester.element(painter.first)).requestFocus();
      await tester.pump();
    }

    testWidgets('arrows change one step, PageUp/PageDown five minutes', (
      tester,
    ) async {
      await pumpHome(tester);
      await focusDial(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(tester.textOf('home.digits'), '06:00');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(tester.textOf('home.digits'), '05:00');

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(tester.textOf('home.digits'), '10:00');

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(tester.textOf('home.digits'), '05:00');
    });

    testWidgets('steps are 10 s below 2 min', (tester) async {
      await pumpHome(tester, duration: const Duration(minutes: 1));
      await focusDial(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(tester.textOf('home.digits'), '00:50');
    });
  });

  testWidgets('the dial is an adjustable slider for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expect(
      tester.getSemantics(find.byKey(_dial)),
      matchesSemantics(
        isSlider: true,
        isFocusable: true,
        label: 'Duration',
        value: '5 minutes',
        increasedValue: '6 minutes',
        decreasedValue: '4 minutes',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        hasFocusAction: true,
      ),
    );

    tester.semantics.performAction(
      find.semantics.byLabel('Duration'),
      SemanticsAction.increase,
    );
    await tester.pump();
    expect(tester.textOf('home.digits'), '06:00');
    semantics.dispose();
  });

  group('start', () {
    testWidgets('starts the timer and opens the countdown', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(_start));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
      final saved = dependencies.sessionRepository.load()!;
      expect(saved.status, SessionStatus.running);
      expect(saved.config.duration.value, const Duration(minutes: 5));
    });

    testWidgets('a storage failure keeps home and shows an error', (
      tester,
    ) async {
      await pumpHome(tester);
      await dependencies.breakSessionStorage();

      await tester.tap(find.byKey(_start));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('home.screen')), findsOneWidget);
      expect(find.byKey(const Key('home.startFailed')), findsOneWidget);
      expect(dependencies.alarms.scheduledRequests, isEmpty);
    });

    testWidgets('Space starts the timer', (tester) async {
      await pumpHome(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
    });
  });

  for (final screen in ScreenClass.values) {
    testWidgets('lays out without overflow (${screen.name})', (tester) async {
      await pumpHome(tester, screen: screen);

      expect(find.byKey(_dial), findsOneWidget);
      expect(find.byKey(_start), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('remembers the change as lastConfig', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('home.plus1')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      dependencies.settingsRepository.load().lastConfig.duration.value,
      const Duration(minutes: 6),
    );
  });
}
