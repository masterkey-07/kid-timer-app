import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

import 'support/dial_image.dart';
import 'support/one_minute_timer.dart';

/// US3 acceptance 1 on a real device: a library image fills the dial on
/// home and keeps filling the remaining sector while it counts down
/// (contracts/ui/04 §4.1, FR-025).
void main() {
  patrolTest('library image on the dial, then counting down', ($) async {
    await launchApp($);

    await $(const Key('home.imageChip')).tap();
    await $.waitUntilVisible(find.byKey(const Key('images.screen')));
    await $(const Key('images.tab.hygiene')).tap();
    await $(const Key('images.item.bank:hygiene/brush_teeth')).tap();

    await $.waitUntilVisible(find.byKey(const Key('home.screen')));
    await waitUntilDialShowsImage($, 'home.dial');

    await setOneMinute($);
    await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);
    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));
    await waitUntilDialShowsImage($, 'run.dial');
  });
}
