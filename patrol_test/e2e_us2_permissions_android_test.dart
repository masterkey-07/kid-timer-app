import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/one_minute_timer.dart';

/// US2 acceptance 6 on Android 13+: refusing notifications explains that
/// the alarm only rings with the app open and offers the settings
/// (contracts/ui/08). `.github/scripts/android_e2e.sh` revokes the
/// permission and its "user fixed" flags first, so the system asks again.
void main() {
  /// Android 13 (API 33) introduced the runtime notification permission.
  const firstApiWithNotificationPermission = 33;

  patrolTest('deny notifications → dialog → "Open settings"', ($) async {
    final apiLevel = await $.platform.mobile.getOsVersion();
    if (apiLevel < firstApiWithNotificationPermission) {
      markTestSkipped('no runtime notification permission before API 33');
      return;
    }

    await launchApp($);
    await setOneMinute($);
    await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);

    expect(await $.platform.mobile.isPermissionDialogVisible(), isTrue);
    await $.platform.mobile.denyPermission();
    await $.waitUntilVisible(
      find.byKey(const Key('notice.notificationsDenied')),
    );

    await $(const Key('notice.notificationsDenied.openSettings'))
        .tap(settlePolicy: SettlePolicy.noSettle);
    // The app notification settings name the app.
    await $.platform.mobile.waitUntilVisible(
      Selector(textContains: 'Kid Timer'),
    );

    await $.platform.mobile.openApp();
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));
  });
}
