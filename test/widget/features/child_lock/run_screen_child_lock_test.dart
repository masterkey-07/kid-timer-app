import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

/// SC-003: 30 sequences of 20 gestures each (testing-strategy §SC-003).
const _sequenceCount = 30;
const _gesturesPerSequence = 20;
const _seed = 42;

const _hold = Duration(seconds: 3);
const _controlsShown = Duration(seconds: 10);

/// Lets a gesture finish and the padlock glow fade before the next one.
const _settle = Duration(milliseconds: 400);

const _idleOpacity = 0.35;
const _glowOpacity = 0.8;

final _running = TimerSession(
  id: 'run-1',
  config: TimerConfig(duration: TimerDuration(const Duration(minutes: 10))),
  status: SessionStatus.running,
  startedAt: testNow,
  endsAt: testNow.add(const Duration(minutes: 10)),
  scheduledNotificationIds: const [7],
);

/// What the child may do to the locked screen.
enum _GestureKind {
  tap,
  doubleTap,
  shortLongPress,
  drag,
  fling,
  pinch,
  twoFingerTap,
  backButton,
  systemKey,
}

/// Keys a child could press; Esc is only ever pressed briefly.
const List<LogicalKeyboardKey> _childKeys = [
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.keyP,
  LogicalKeyboardKey.tab,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.backspace,
];

final class _Gesture {
  const new(this.kind, this.position, this.other, this.duration, this.key);

  final _GestureKind kind;
  final Offset position;

  /// A drag/fling offset or the second finger's position.
  final Offset other;

  /// How long a long press is held, always under 3 s.
  final Duration duration;
  final LogicalKeyboardKey key;

  @override
  String toString() => '$kind at $position';
}

/// Every sequence, drawn up front from one seeded generator.
final List<List<_Gesture>> _sequences = () {
  final random = Random(_seed);
  final screen = ScreenClass.compact.size;
  Offset anywhere() => Offset(
    random.nextDouble() * (screen.width - 1),
    random.nextDouble() * (screen.height - 1),
  );
  Offset anyOffset() => Offset(
    (random.nextDouble() - 0.5) * screen.width,
    (random.nextDouble() - 0.5) * screen.height,
  );
  return [
    for (var sequence = 0; sequence < _sequenceCount; sequence++)
      [
        for (var gesture = 0; gesture < _gesturesPerSequence; gesture++)
          _Gesture(
            _GestureKind.values[random.nextInt(_GestureKind.values.length)],
            anywhere(),
            anyOffset(),
            Duration(milliseconds: 500 + random.nextInt(2400)),
            _childKeys[random.nextInt(_childKeys.length)],
          ),
      ],
  ];
}();

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Finder byKey(String key) => find.byKey(Key(key));

  Future<void> pumpRun(
    WidgetTester tester, {
    AppSettings settings = AppSettings.initial,
  }) async {
    await dependencies.sessionRepository.save(_running);
    await tester.pumpKidTimerApp(
      dependencies,
      session: _running,
      settings: settings,
    );
    await tester.pump(_settle);
  }

  TimerSession? currentSession(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(byKey('run.screen')))
          .read(timerControllerProvider);

  Future<void> holdPadlock(WidgetTester tester, Duration duration) async {
    final gesture = await tester.startGesture(
      tester.getCenter(byKey('run.lock')),
    );
    await tester.pump(duration);
    await gesture.up();
    await tester.pump();
  }

  double padlockOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(of: byKey('run.lock'), matching: find.byType(Opacity)),
      )
      .opacity;

  Future<void> perform(WidgetTester tester, _Gesture gesture) async {
    switch (gesture.kind) {
      case _GestureKind.tap:
        await tester.tapAt(gesture.position);
      case _GestureKind.doubleTap:
        await tester.tapAt(gesture.position);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(gesture.position);
      case _GestureKind.shortLongPress:
        final press = await tester.startGesture(gesture.position);
        await tester.pump(gesture.duration);
        await press.up();
      case _GestureKind.drag:
        await tester.dragFrom(gesture.position, gesture.other);
      case _GestureKind.fling:
        await tester.flingFrom(gesture.position, gesture.other, 1500);
      case _GestureKind.pinch:
        final first = await tester.startGesture(gesture.position, pointer: 1);
        final second = await tester.startGesture(
          gesture.position + const Offset(60, 60),
          pointer: 2,
        );
        await first.moveBy(gesture.other / 4);
        await second.moveBy(-gesture.other / 4);
        await first.up();
        await second.up();
      case _GestureKind.twoFingerTap:
        final first = await tester.startGesture(gesture.position, pointer: 1);
        final second = await tester.startGesture(
          Offset(gesture.other.dx.abs(), gesture.other.dy.abs()),
          pointer: 2,
        );
        await first.up();
        await second.up();
      case _GestureKind.backButton:
        await tester.binding.handlePopRoute();
      case _GestureKind.systemKey:
        await tester.sendKeyEvent(gesture.key);
    }
    await tester.pump(_settle);
  }

  group('SC-003: 30 seeded sequences of gestures leave the timer alone', () {
    for (final (index, sequence) in _sequences.indexed) {
      testWidgets('sequence ${index + 1}', (tester) async {
        await pumpRun(tester);

        for (final gesture in sequence) {
          await perform(tester, gesture);
          expect(currentSession(tester), _running, reason: 'after $gesture');
          expect(byKey('run.screen'), findsOneWidget, reason: 'after $gesture');
          expect(byKey('confirm.dialog'), findsNothing, reason: '$gesture');
          expect(byKey('run.pauseResume'), findsNothing, reason: '$gesture');
        }
        expect(dependencies.sessionRepository.load(), _running);
      });
    }
  });

  testWidgets('child mode shows only the dial and the padlock (FR-030)', (
    tester,
  ) async {
    await pumpRun(tester);

    expect(byKey('run.dial'), findsOneWidget);
    expect(byKey('run.lock'), findsOneWidget);
    expect(byKey('run.touchShield'), findsOneWidget);
    expect(byKey('run.pauseResume'), findsNothing);
    expect(byKey('run.stop'), findsNothing);
    expect(byKey('run.restart'), findsNothing);
    expect(dependencies.fullscreen.isFullscreen, isTrue);
  });

  testWidgets('the Android back button is consumed in child mode', (
    tester,
  ) async {
    await pumpRun(tester);

    await tester.binding.handlePopRoute();
    await tester.pump(_settle);

    expect(byKey('run.screen'), findsOneWidget);
    expect(byKey('confirm.dialog'), findsNothing);
  });

  testWidgets('a touch makes the padlock glow for 300 ms', (tester) async {
    await pumpRun(tester);
    expect(padlockOpacity(tester), _idleOpacity);

    await tester.tapAt(tester.getCenter(byKey('run.dial')));
    // The glow's clock starts on the next frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(padlockOpacity(tester), _glowOpacity);

    await tester.pump(const Duration(milliseconds: 200));
    expect(padlockOpacity(tester), _idleOpacity);
  });

  testWidgets('with reduce motion the glow steps without easing', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpRun(tester);

    await tester.tapAt(tester.getCenter(byKey('run.dial')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(padlockOpacity(tester), _glowOpacity);

    await tester.pump(const Duration(milliseconds: 330));
    expect(padlockOpacity(tester), _idleOpacity);
  });

  testWidgets('holding the padlock for 3 s shows the controls for 10 s', (
    tester,
  ) async {
    await pumpRun(tester);

    final press = await tester.startGesture(
      tester.getCenter(byKey('run.lock')),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(byKey('run.lockProgress'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await press.up();
    await tester.pump();

    expect(byKey('run.pauseResume'), findsOneWidget);
    expect(byKey('run.relockIn'), findsOneWidget);
    expect(byKey('run.touchShield'), findsNothing);

    await tester.pump(_controlsShown);
    expect(byKey('run.pauseResume'), findsNothing);
    expect(byKey('run.touchShield'), findsOneWidget);
  });

  testWidgets('releasing the padlock early resets the ring', (tester) async {
    await pumpRun(tester);

    await holdPadlock(tester, const Duration(milliseconds: 2900));
    await tester.pump(_hold);

    expect(byKey('run.lockProgress'), findsNothing);
    expect(byKey('run.pauseResume'), findsNothing);
  });

  testWidgets('touching the unlocked screen restarts the 10 s', (tester) async {
    await pumpRun(tester);
    await holdPadlock(tester, _hold);

    await tester.pump(const Duration(seconds: 8));
    await tester.tapAt(tester.getCenter(byKey('run.dial')));
    await tester.pump(const Duration(seconds: 9));
    expect(byKey('run.pauseResume'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(byKey('run.pauseResume'), findsNothing);
  });

  testWidgets('the unlocked controls work', (tester) async {
    await pumpRun(tester);
    await holdPadlock(tester, _hold);

    await tester.tap(byKey('run.pauseResume'));
    await tester.pump(_settle);

    expect(currentSession(tester)!.status, SessionStatus.paused);
  });

  testWidgets('holding Esc for 3 s shows the controls (FR-031)', (
    tester,
  ) async {
    await pumpRun(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump(_hold);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(byKey('run.pauseResume'), findsOneWidget);
  });

  testWidgets('Space does not pause in child mode', (tester) async {
    await pumpRun(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(_settle);

    expect(currentSession(tester), _running);
  });

  testWidgets('with the child lock off the controls are always visible', (
    tester,
  ) async {
    await pumpRun(tester, settings: const AppSettings(childLockEnabled: false));
    await tester.pump(_controlsShown * 2);

    expect(byKey('run.pauseResume'), findsOneWidget);
    expect(byKey('run.lock'), findsNothing);
    expect(byKey('run.touchShield'), findsNothing);
    expect(byKey('run.relockIn'), findsNothing);
    expect(dependencies.fullscreen.isFullscreen, isFalse);
  });

  testWidgets('with reduce motion the ring becomes "1… 2… 3"', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpRun(tester);

    final press = await tester.startGesture(
      tester.getCenter(byKey('run.lock')),
    );
    // The ring's clock starts on the next frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(tester.textOf('run.lockProgress'), '1…');
    await tester.pump(const Duration(seconds: 1));
    expect(tester.textOf('run.lockProgress'), '1… 2…');
    expect(
      find.descendant(
        of: byKey('run.lockProgress'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    await press.up();
    await tester.pump();
  });

  testWidgets('turning on a screen reader mid-countdown keeps the session '
      'and the padlock focusable', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpRun(tester);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump(_settle);

    expect(currentSession(tester), _running);
    expect(
      tester.getSemantics(byKey('run.lock')),
      isSemantics(
        label: 'Hold for 3 seconds to show the controls',
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });
}
