import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import 'support/one_minute_timer.dart';

/// US4 on a real device: in child mode 30 taps and the Android back button
/// change nothing; holding the padlock for 3 s shows the controls (SC-003).
void main() {
  const tapCount = 30;
  const seed = 42;
  const hold = Duration(seconds: 3);
  const betweenTaps = Duration(milliseconds: 150);

  patrolTest('child mode ignores taps and back; the padlock unlocks it', (
    $,
  ) async {
    await launchApp($);
    await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);
    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));

    final container = ProviderScope.containerOf(
      $.tester.element(find.byKey(const Key('run.screen'))),
    );
    final session = container.read(timerControllerProvider);

    // Anywhere but the padlock, whose short taps are covered by the widget
    // tests.
    final random = Random(seed);
    final screen = $.tester.getRect(find.byKey(const Key('run.screen')));
    final padlock = $.tester.getRect(find.byKey(const Key('run.lock')));
    for (var tap = 0; tap < tapCount; tap++) {
      final position = Offset(
        screen.left + random.nextDouble() * screen.width,
        screen.top + random.nextDouble() * screen.height,
      );
      if (padlock.inflate(8).contains(position)) continue;
      await $.tester.tapAt(position);
      await $.pump(betweenTaps);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await $.platform.android.pressBack();
      await $.pump(const Duration(seconds: 1));
    }

    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    expect(find.byKey(const Key('confirm.dialog')), findsNothing);
    expect(container.read(timerControllerProvider), session);

    final press = await $.tester.startGesture(padlock.center);
    await $.pump(hold);
    await press.up();
    await $.pump();
    await $.waitUntilVisible(find.byKey(const Key('run.pauseResume')));
  });
}
