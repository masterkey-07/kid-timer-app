import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import 'support/one_minute_timer.dart';
import 'support/system_ui.dart';

/// US6 on a real device: with calm mode chosen in the settings and ticking
/// off, a 1 min timer runs with the calm palette and without a tick.
void main() {
  patrolTest('calm mode and ticking off apply to the next timer', ($) async {
    await launchApp($);

    await $(const Key('home.openSettings')).tap();
    await $(const Key('settings.palette')).scrollTo().tap();
    await $(const Key('settings.palette.calm')).tap();
    await $.platform.android.pressBack();
    await $.waitUntilVisible(find.byKey(const Key('home.screen')));

    await setOneMinute($);
    await $(const Key('home.start')).tap(settlePolicy: SettlePolicy.noSettle);
    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));
    await dismissFullScreenHint($);

    final container = ProviderScope.containerOf(
      $.tester.element(find.byKey(const Key('run.screen'))),
    );
    final config = container.read(timerControllerProvider)!.config;
    expect((config.visual as PaletteSource).paletteId, PaletteId.calm);
    expect(config.tickEnabled, isFalse);
  });
}
