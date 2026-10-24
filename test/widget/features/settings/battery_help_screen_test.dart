import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const _sections = ['alarms', 'battery', 'pinning', 'web'];

const _pageTransition = Duration(seconds: 1);

const _androidButtons = {
  'battery.openExactAlarm': 'exactAlarm',
  'battery.openNotifications': 'notifications',
  'battery.openBatteryOptimization': 'batteryOptimization',
};

/// Help: battery, alarms and screen pinning (contracts/ui/06 §6.2).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> openHelp(
    WidgetTester tester, {
    String location = '/settings/battery',
    AppPlatform platform = AppPlatform.android,
    ScreenClass screen = ScreenClass.compact,
    double textScale = 1,
  }) async {
    dependencies.platform = platform;
    await tester.pumpKidTimerApp(
      dependencies,
      screen: screen,
      textScale: textScale,
    );
    await settle(tester);
    unawaited(
      GoRouter.of(tester.element(find.byKey(const Key('home.screen'))))
          .push<void>(location),
    );
    await settle(tester);
    // Android's page transition fades in for longer than settle() waits.
    await tester.pump(_pageTransition);
  }

  /// Whether the widget with [key] is at least partly on screen.
  bool isOnScreen(WidgetTester tester, String key) {
    final screen = Offset.zero & tester.view.physicalSize;
    return screen.overlaps(tester.getRect(find.byKey(Key(key))));
  }

  testWidgets('shows the four sections', (tester) async {
    await openHelp(tester);

    expect(find.byKey(const Key('battery.screen')), findsOneWidget);
    for (final section in _sections) {
      expect(
        find.byKey(Key('battery.section.$section'), skipOffstage: false),
        findsOneWidget,
        reason: section,
      );
    }
  });

  testWidgets('Android buttons open the matching system settings', (
    tester,
  ) async {
    await openHelp(tester);

    for (final MapEntry(key: button, value: screen)
        in _androidButtons.entries) {
      await tester.scrollUntilVisible(find.byKey(Key(button)), 100);
      await tester.tap(find.byKey(Key(button)));
      await settle(tester);
      expect(dependencies.systemSettings.opened.last, screen, reason: button);
    }
  });

  for (final platform in [AppPlatform.ios, AppPlatform.web]) {
    testWidgets('${platform.name} hides the Android buttons', (tester) async {
      await openHelp(tester, platform: platform);

      for (final button in _androidButtons.keys) {
        expect(
          find.byKey(Key(button), skipOffstage: false),
          findsNothing,
          reason: button,
        );
      }
    });
  }

  testWidgets('an anchor scrolls to its section', (tester) async {
    await openHelp(tester, location: '/settings/battery#web');

    expect(isOnScreen(tester, 'battery.section.web'), isTrue);
    expect(isOnScreen(tester, 'battery.section.alarms'), isFalse);
  });

  testWidgets('"Learn more" on the banner opens the section it explains', (
    tester,
  ) async {
    dependencies
      ..platform = AppPlatform.web
      ..alarms.capabilitiesValue = AlarmCapabilities.unsupported;
    await tester.pumpKidTimerApp(dependencies);
    await settle(tester);

    await tester.tap(find.byKey(const Key('notice.banner.learnMore')));
    await settle(tester);
    await tester.pump(_pageTransition);

    expect(find.byKey(const Key('battery.screen')), findsOneWidget);
    expect(isOnScreen(tester, 'battery.section.web'), isTrue);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await openHelp(tester);

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('keeps a readable column on wide screens', (tester) async {
    await openHelp(tester, screen: ScreenClass.expanded);

    expect(
      tester.getSize(find.byKey(const Key('battery.content'))).width,
      lessThanOrEqualTo(720),
    );
  });

  testWidgets('200% font scale does not overflow', (tester) async {
    await openHelp(tester, textScale: maxTextScale);

    expect(tester.takeException(), isNull);
  });
}
