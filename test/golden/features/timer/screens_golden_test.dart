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
  id: 'golden-run',
  config: TimerConfig.defaults,
  status: SessionStatus.running,
  startedAt: testNow.subtract(const Duration(minutes: 2)),
  endsAt: testNow.add(const Duration(minutes: 3)),
);

final _finished = TimerSession(
  id: 'golden-done',
  config: TimerConfig.defaults,
  status: SessionStatus.finished,
  startedAt: testNow.subtract(const Duration(minutes: 5)),
  endsAt: testNow,
);

/// The screens, by the session that opens them.
final Map<String, TimerSession?> _screens = {
  'home': null,
  'run': _running,
  'finished': _finished,
};

/// Light, dark and high-contrast light (testing-strategy §2 rule 7).
const Map<String, ({AppThemeMode mode, bool highContrast})> _themes = {
  'light': (mode: AppThemeMode.light, highContrast: false),
  'dark': (mode: AppThemeMode.dark, highContrast: false),
  'high_contrast_light': (mode: AppThemeMode.light, highContrast: true),
};

Future<void> main() async {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Widget app({
    required TimerSession? session,
    required AppThemeMode mode,
    required bool highContrast,
  }) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(highContrast: highContrast),
      child: ProviderScope(
        overrides: dependencies.overrides(
          session: session,
          settings: AppSettings(
            themeMode: mode,
            childLockEnabled: false,
            onboarding: const OnboardingFlags(dialHintDismissed: true),
          ),
        ),
        child: const KidTimerApp(),
      ),
    ),
  );

  for (final MapEntry(key: screenName, value: session) in _screens.entries) {
    for (final MapEntry(key: themeName, value: theme) in _themes.entries) {
      await goldenTest(
        '$screenName screen per size class ($themeName)',
        fileName: '${screenName}_screen_$themeName',
        // Past the final screen's celebration and hint; the countdown dial
        // repaints every frame, so the tree never settles.
        pumpBeforeTest: pumpNTimes(3, const Duration(milliseconds: 1500)),
        builder: () => GoldenTestGroup(
          columns: ScreenClass.values.length,
          children: [
            for (final screen in ScreenClass.values)
              GoldenTestScenario(
                name: screen.name,
                constraints: BoxConstraints.tight(screen.size),
                child: app(
                  session: session,
                  mode: theme.mode,
                  highContrast: theme.highContrast,
                ),
              ),
          ],
        ),
      );
    }
  }
}
