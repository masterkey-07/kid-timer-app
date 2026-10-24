import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/one_minute_timer.dart';

/// US2 acceptance 2 on Android: the system kills the app while a timer
/// runs; the alarm still rings and its notification opens /finished.
///
/// A test cannot outlive its own process, so `.github/scripts/android_e2e.sh`
/// runs this file twice: `E2E_PHASE=start` starts the timer and leaves the
/// app, the script kills the process with `am kill` (as low memory would;
/// unlike `force-stop`, it keeps the app's alarms), waits for the end, then
/// `E2E_PHASE=verify` taps the notification.
void main() {
  const phase = String.fromEnvironment('E2E_PHASE');

  /// The script waits this long after the kill before verifying.
  const notificationTimeout = Duration(seconds: 30);

  patrolTest(
    'phase start: run a 1 min timer and leave the app',
    skip: phase != 'start',
    ($) async {
      await launchApp($);
      await setOneMinute($);
      await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);
      if (await $.platform.mobile.isPermissionDialogVisible()) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }
      await $.waitUntilVisible(find.byKey(const Key('run.screen')));

      await $.platform.mobile.pressHome();
    },
  );

  patrolTest(
    'phase verify: the notification of the killed app opens /finished',
    skip: phase != 'verify',
    ($) async {
      await $.platform.mobile.openNotifications();
      await $.platform.mobile.tapOnNotificationBySelector(
        Selector(textContains: "Time's up"),
        timeout: notificationTimeout,
      );

      await launchApp($, screenKey: 'finished.screen');
    },
  );
}
