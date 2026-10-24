import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/dial_image.dart';
import 'support/one_minute_timer.dart';

/// US3 acceptance 2 on a real device: a photo chosen in the system picker,
/// with no permission dialog (FR-021), framed and shown on the dial.
/// `.github/scripts/android_e2e.sh` first pushes the GPS fixture to the
/// gallery as `e2e_photo.jpg` (the simulator's sample photos serve on iOS).
void main() {
  patrolTest('own photo: system picker, frame, on the dial', ($) async {
    await launchApp($);

    await $(const Key('home.imageChip')).tap();
    await $.waitUntilVisible(find.byKey(const Key('images.screen')));
    await $(const Key('images.fromDevice'))
        .tap(settlePolicy: SettlePolicy.noSettle);

    // The system photo picker needs no permission, unlike the gallery.
    expect(await $.platform.mobile.isPermissionDialogVisible(), isFalse);
    await $.platform.mobile.tap(
      Selector(contentDescriptionContains: 'Photo', instance: 0),
    );

    await $.waitUntilVisible(find.byKey(const Key('frame.screen')));
    await $(const Key('frame.name')).enterText('E2E photo');
    await $(const Key('frame.save')).tap(settlePolicy: SettlePolicy.noSettle);

    await $.waitUntilVisible(find.byKey(const Key('home.screen')));
    await waitUntilDialShowsImage($, 'home.dial');
  });
}
