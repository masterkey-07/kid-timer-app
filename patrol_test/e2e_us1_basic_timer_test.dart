import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/bootstrap.dart';

/// US1 end to end on a real device: drag the dial to 1 min, start, wait
/// for the final screen and tap back home (contracts/ui/01, 02, 03).
void main() {
  /// The alarm may fire up to a few seconds late on a busy emulator.
  const finishedTimeout = Duration(seconds: 75);

  /// 1 min on the default 60 min scale is 1/60 of a turn.
  const oneMinuteTurn = 1 / 60;

  /// The drag passes through these shares of the target to stay on the
  /// ring, the way a finger would.
  const dragSteps = [0.0, 0.5, 1.0];

  patrolTest('set 1 min by dragging, start, final screen, tap back', ($) async {
    final overrides = await bootstrap();
    await $.pumpWidget(
      ProviderScope(overrides: overrides, child: const KidTimerApp()),
    );
    await $.waitUntilVisible(find.byKey(const Key('home.screen')));

    // A clockwise dial opens counter-clockwise from 12 o'clock.
    final dial = $.tester.getRect(find.byKey(const Key('home.dial')));
    final radius = dial.shortestSide / 2;
    Offset onRing(double turn) {
      final angle = -pi / 2 - turn * 2 * pi;
      return dial.center + Offset(cos(angle), sin(angle)) * radius * 0.95;
    }

    final gesture = await $.tester.startGesture(onRing(0));
    for (final step in dragSteps.skip(1)) {
      await gesture.moveTo(onRing(oneMinuteTurn * step));
      await $.pump();
    }
    await gesture.up();
    await $.pump();
    expect($(const Key('home.digits')).$(Text).text, '01:00');

    await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));

    await $.waitUntilVisible(
      find.byKey(const Key('finished.screen')),
      timeout: finishedTimeout,
    );
    // Past the 800 ms guard against accidental touches.
    await $.pump(const Duration(seconds: 1));
    await $(const Key('finished.dismissArea'))
        .tap(settlePolicy: SettlePolicy.noSettle);

    await $.waitUntilVisible(find.byKey(const Key('home.screen')));
  });
}
