import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/app/shortcuts.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<BuildContext> pumpApp(
    WidgetTester tester, {
    AppSettings settings = AppSettings.initial,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(settings: settings),
        child: const KidTimerApp(),
      ),
    );
    await tester.pumpAndSettle();
    return tester.element(find.byKey(const Key('home.screen')));
  }

  testWidgets('follows the system brightness by default', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final context = await pumpApp(tester);

    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('honors a fixed theme preference', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final context = await pumpApp(
      tester,
      settings: AppSettings.initial.copyWith(themeMode: AppThemeMode.light),
    );

    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('uses the high-contrast theme when the system asks', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final context = await pumpApp(tester);

    expect(Theme.of(context).colorScheme.surface, const Color(0xFFFFFFFF));
  });

  for (final (system, expected) in [
    (const Locale('pt', 'PT'), const Locale('pt', 'BR')),
    (const Locale('fr', 'FR'), const Locale('en')),
  ]) {
    testWidgets('system locale $system → $expected', (tester) async {
      tester.platformDispatcher.localesTestValue = [system];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final context = await pumpApp(tester);

      expect(Localizations.localeOf(context), expected);
      expect(AppLocalizations.of(context).appTitle, isNotEmpty);
    });
  }

  test('maps the global keyboard shortcuts (contracts/ui/00 §7)', () {
    expect(
      appShortcuts[const SingleActivator(
        LogicalKeyboardKey.comma,
        control: true,
      )],
      isA<OpenSettingsIntent>(),
    );
    expect(
      appShortcuts[const SingleActivator(LogicalKeyboardKey.comma, meta: true)],
      isA<OpenSettingsIntent>(),
    );
    expect(
      appShortcuts[const CharacterActivator('?')],
      isA<ShowShortcutsIntent>(),
    );
  });

  testWidgets('Ctrl+, reaches an OpenSettingsIntent action', (tester) async {
    var invoked = 0;
    await tester.pumpWidget(
      MaterialApp(
        shortcuts: appShortcuts,
        home: Actions(
          actions: {
            OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
              onInvoke: (_) => invoked++,
            ),
          },
          child: const Focus(autofocus: true, child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(invoked, 1);
  });
}
