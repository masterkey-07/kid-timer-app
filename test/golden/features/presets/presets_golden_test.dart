import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const Map<String, AppThemeMode> _themes = {
  'light': AppThemeMode.light,
  'dark': AppThemeMode.dark,
};

const _pageTransition = Duration(seconds: 1);

/// Opens [location] in every scenario's app.
Future<void> Function(WidgetTester) _openAt(String location) => (tester) async {
  await tester.pump(_pageTransition);
  for (final home in find.byKey(const Key('home.screen')).evaluate()) {
    unawaited(GoRouter.of(home).push<void>(location));
  }
  await tester.pump();
  await tester.pump(_pageTransition);
};

Future<void> main() async {
  late TestAppDependencies dependencies;

  setUp(() async {
    dependencies = await TestAppDependencies.create();
    await dependencies.seedPreset(
      'a',
      'Brush teeth',
      const BankImageSource('bank:hygiene/brush_teeth'),
      duration: const Duration(minutes: 2),
    );
    await dependencies.seedPreset(
      'b',
      'Bath',
      VisualSource.defaultSource,
      duration: const Duration(minutes: 10),
    );
    await dependencies.seedPreset(
      'c',
      'Homework',
      const BankImageSource('bank:school/homework'),
      duration: const Duration(minutes: 25),
    );
  });
  tearDown(() => dependencies.dispose());

  Widget app(AppThemeMode mode) => ProviderScope(
    overrides: dependencies.overrides(settings: AppSettings(themeMode: mode)),
    child: const KidTimerApp(),
  );

  final screens = {
    'list': _openAt('/presets'),
    'editor': _openAt('/presets/b/edit'),
  };

  for (final MapEntry(key: screenName, value: open) in screens.entries) {
    for (final MapEntry(key: themeName, value: mode) in _themes.entries) {
      await goldenTest(
        'presets $screenName per size class ($themeName)',
        fileName: 'presets_${screenName}_$themeName',
        pumpBeforeTest: open,
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
