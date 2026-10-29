import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);

/// Presets on the home screen (contracts/ui/01: `home.presetStrip`,
/// `home.savePreset`, `home.openPresets`; FR-041, SC-006).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_pageTransition);
  }

  Future<void> pumpHome(WidgetTester tester, {TimerConfig? lastConfig}) async {
    await tester.pumpKidTimerApp(
      dependencies,
      settings: AppSettings(lastConfig: lastConfig ?? TimerConfig.defaults),
    );
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  Future<void> seedBath() => dependencies.seedPreset(
    'bath',
    'Bath',
    const BankImageSource('bank:hygiene/bath'),
    duration: const Duration(minutes: 10),
  );

  testWidgets('without presets there is no strip', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('home.presetStrip')), findsNothing);
    expect(find.byKey(const Key('home.openPresets')), findsOneWidget);
  });

  testWidgets('the strip shows up to 8 presets', (tester) async {
    for (var i = 0; i < 10; i++) {
      await dependencies.seedPreset('p$i', 'P$i', VisualSource.defaultSource);
    }
    await pumpHome(tester);

    expect(find.byKey(const Key('home.presetStrip')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('home.preset.p7')),
      100,
      scrollable: find.descendant(
        of: find.byKey(const Key('home.presetStrip')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('home.preset.p8')), findsNothing);
    expect(find.byKey(const Key('home.preset.p9')), findsNothing);
  });

  testWidgets('tapping a preset loads its configuration (first tap)', (
    tester,
  ) async {
    await seedBath();
    await pumpHome(tester);

    await tapKey(tester, 'home.preset.bath');

    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(tester.textOf('home.digits'), '10:00');
    expect(dependencies.sessionRepository.load(), isNull);

    await tapKey(tester, 'home.start');
    expect(find.byKey(const Key('run.screen')), findsOneWidget);
  });

  testWidgets('▶ on a preset starts it from home in one tap (SC-006)', (
    tester,
  ) async {
    await seedBath();
    await pumpHome(tester);

    await tapKey(tester, 'home.presetStart.bath');

    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    final session = dependencies.sessionRepository.load()!;
    expect(session.origin, const PresetOrigin('bath'));
    expect(session.config.duration.value, const Duration(minutes: 10));
  });

  testWidgets('Save as preset opens the editor with the current setup', (
    tester,
  ) async {
    final config = TimerConfig(
      duration: TimerDuration(const Duration(minutes: 3)),
    );
    await pumpHome(tester, lastConfig: config);
    await tapKey(tester, 'home.plus1');

    await tapKey(tester, 'home.savePreset');
    expect(find.byKey(const Key('presetEditor.screen')), findsOneWidget);
    expect(tester.textOf('presetEditor.digits'), '04:00');

    await tester.enterText(find.byKey(const Key('presetEditor.name')), 'Snack');
    await tapKey(tester, 'presetEditor.save');

    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(find.byKey(const Key('home.preset.preset-0')), findsOneWidget);
  });

  testWidgets('Presets opens the list', (tester) async {
    await pumpHome(tester);

    await tapKey(tester, 'home.openPresets');

    expect(find.byKey(const Key('presets.screen')), findsOneWidget);
  });

  testWidgets('presets edited in the list show on home when back', (
    tester,
  ) async {
    await seedBath();
    await pumpHome(tester);
    await tapKey(tester, 'home.openPresets');

    await tapKey(tester, 'presets.menu.bath');
    await tapKey(tester, 'presets.delete.bath');
    await tapKey(tester, 'confirm.confirm');
    await tester.pageBack();
    await settle(tester);

    expect(find.byKey(const Key('home.preset.bath')), findsNothing);
  });

  testWidgets('a preset deep link starts the preset', (tester) async {
    await seedBath();
    await pumpHome(tester);

    GoRouter.of(tester.element(find.byKey(const Key('home.screen'))))
        .go('/?startPreset=bath');
    await settle(tester);
    await settle(tester);

    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    expect(
      dependencies.sessionRepository.load()!.origin,
      const PresetOrigin('bath'),
    );
  });

  testWidgets('the expanded layout keeps the presets', (tester) async {
    await seedBath();
    await tester.pumpKidTimerApp(dependencies, screen: ScreenClass.expanded);
    await settle(tester);

    expect(find.byKey(const Key('home.preset.bath')), findsOneWidget);
    expect(find.byKey(const Key('home.savePreset')), findsOneWidget);
  });
}
