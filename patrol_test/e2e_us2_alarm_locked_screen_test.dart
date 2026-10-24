import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/one_minute_timer.dart';

/// US2 acceptance 1 on a real device: a 1 min timer rings through the OS
/// alarm with the app in the background (Android, iOS).
///
/// Patrol cannot lock the screen from inside the app, so the app goes to
/// the background with Home; the OS alarm path is the same. Lateness is
/// measured by polling the notification shade, which overstates it by up
/// to one poll.
void main() {
  /// The notification must show within this long of starting.
  const notificationTimeout = Duration(seconds: 65);

  /// The most the OS alarm may be late (plan: ≤ 5 s in the background).
  const maxLateness = Duration(seconds: 5);

  const pollEvery = Duration(milliseconds: 500);

  patrolTest('the alarm notification arrives with the app in the background', (
    $,
  ) async {
    await launchApp($);
    await setOneMinute($);
    await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);
    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));
    final endsAt = runningEndsAt($);

    await $.platform.mobile.pressHome();
    final seenAt = await _waitForTimeUpNotification(
      $,
      deadline: clock.now().add(notificationTimeout),
      pollEvery: pollEvery,
    );

    expect(seenAt, isNotNull, reason: 'no notification within 65 s');
    expect(
      seenAt!.difference(endsAt),
      lessThanOrEqualTo(maxLateness + pollEvery),
    );

    await $.platform.mobile.tapOnNotificationBySelector(
      Selector(textContains: "Time's up"),
    );
    await $.waitUntilVisible(find.byKey(const Key('finished.screen')));
  });
}

/// Polls the shade until the end notification shows; returns when it was
/// first seen, or null at [deadline]. Leaves the shade open when found.
Future<DateTime?> _waitForTimeUpNotification(
  PatrolIntegrationTester $, {
  required DateTime deadline,
  required Duration pollEvery,
}) async {
  await $.platform.mobile.openNotifications();
  while (clock.now().isBefore(deadline)) {
    final notifications = await $.platform.mobile.getNotifications();
    if (notifications.any((shown) => shown.title.contains("Time's up"))) {
      return clock.now().toUtc();
    }
    await Future<void>.delayed(pollEvery);
  }
  return null;
}
