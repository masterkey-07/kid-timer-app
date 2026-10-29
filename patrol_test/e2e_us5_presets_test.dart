import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import 'support/one_minute_timer.dart';
import 'support/system_ui.dart';

/// US5 on a real device: a preset saved from home survives a restart and
/// starts from home in at most two taps (SC-006).
void main() {
  const presetName = 'Brush teeth E2E';

  ProviderContainer containerOf(PatrolIntegrationTester $, String key) =>
      ProviderScope.containerOf($.tester.element(find.byKey(Key(key))));

  patrolTest('save a preset, restart, start it from home', ($) async {
    await launchApp($);
    await setOneMinute($);
    await $(const Key('home.savePreset')).scrollTo().tap();
    await $(const Key('presetEditor.name')).enterText(presetName);
    await $(const Key('presetEditor.save')).tap();
    await $.waitUntilVisible(find.byKey(const Key('home.screen')));

    // Restart: drop every open box and boot again from storage.
    await Hive.close();
    await launchApp($);

    final preset = containerOf(
      $,
      'home.screen',
    ).read(presetsProvider).singleWhere((preset) => preset.name == presetName);
    // The first-use examples come first, so the new preset sits at the end
    // of the horizontal strip. Scrolling is not a tap: one tap from home
    // starts it (the limit is two).
    await $(const Key('home.presetStrip')).scrollTo();
    await $(Key('home.presetStart.${preset.id}'))
        .scrollTo(
          view: find.descendant(
            of: find.byKey(const Key('home.presetStrip')),
            matching: find.byType(Scrollable),
          ),
          scrollDirection: AxisDirection.right,
        )
        .tap(settlePolicy: SettlePolicy.noSettle);
    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
    await $.waitUntilVisible(find.byKey(const Key('run.screen')));
    await dismissFullScreenHint($);

    final session = containerOf($, 'run.screen').read(timerControllerProvider)!;
    expect(session.origin, PresetOrigin(preset.id));
    expect(session.config.duration.value, const Duration(minutes: 1));
  });
}
