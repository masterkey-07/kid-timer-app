import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/bootstrap.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

/// The default timer is 5 min; four "−1 min" taps leave 1 min.
const _minusTapsToOneMinute = 4;

/// Boots the real app like `main()` and waits for [screenKey].
Future<void> launchApp(
  PatrolIntegrationTester $, {
  String screenKey = 'home.screen',
}) async {
  final overrides = await bootstrap();
  await $.pumpWidget(
    ProviderScope(overrides: overrides, child: const KidTimerApp()),
  );
  await $.waitUntilVisible(find.byKey(Key(screenKey)));
}

/// Sets 1 min on home with the quick buttons.
Future<void> setOneMinute(PatrolIntegrationTester $) async {
  for (var tap = 0; tap < _minusTapsToOneMinute; tap++) {
    await $(const Key('home.minus1')).tap();
  }
  expect($(const Key('home.digits')).$(Text).text, '01:00');
}

/// When the running timer ends, read from the app's own session.
DateTime runningEndsAt(PatrolIntegrationTester $) {
  final container = ProviderScope.containerOf(
    $.tester.element(find.byKey(const Key('run.screen'))),
  );
  return container.read(timerControllerProvider)!.endsAt!;
}
