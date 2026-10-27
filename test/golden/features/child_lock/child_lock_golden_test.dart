import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

final _running = TimerSession(
  id: 'golden-child-lock',
  config: TimerConfig.defaults,
  status: SessionStatus.running,
  startedAt: testNow.subtract(const Duration(minutes: 2)),
  endsAt: testNow.add(const Duration(minutes: 3)),
);

const _themes = {'light': AppThemeMode.light, 'dark': AppThemeMode.dark};

const _hold = Duration(seconds: 3);

/// Lets the countdown screen open; the dial repaints every frame, so the
/// tree never settles.
Future<void> _open(WidgetTester tester) async {
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Holds every scenario's padlock for 3 s, then shows the controls 2 s
/// into their 10 s.
Future<void> _unlock(WidgetTester tester) async {
  await _open(tester);
  final padlocks = find.byKey(const Key('run.lock'));
  final presses = [
    for (final (index, padlock) in padlocks.evaluate().indexed)
      await tester.startGesture(
        tester.getCenter(find.byElementPredicate((e) => e == padlock)),
        pointer: index + 1,
      ),
  ];
  await tester.pump(_hold);
  for (final press in presses) {
    await press.up();
  }
  await tester.pump(const Duration(seconds: 2));
}

Future<void> main() async {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Widget app(AppThemeMode mode) => ProviderScope(
    overrides: dependencies.overrides(
      session: _running,
      settings: AppSettings(themeMode: mode),
    ),
    child: const KidTimerApp(),
  );

  final states = {'locked': _open, 'unlocked': _unlock};

  for (final MapEntry(key: stateName, value: pump) in states.entries) {
    for (final MapEntry(key: themeName, value: mode) in _themes.entries) {
      await goldenTest(
        'child mode $stateName per size class ($themeName)',
        fileName: 'child_lock_${stateName}_$themeName',
        pumpBeforeTest: pump,
        builder: () => GoldenTestGroup(
          columns: ScreenClass.values.length,
          children: [
            for (final screen in ScreenClass.values)
              GoldenTestScenario(
                name: screen.name,
                constraints: BoxConstraints.tight(screen.size),
                child: app(mode),
              ),
          ],
        ),
      );
    }
  }
}
