import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/settings/presentation/child_mode_section.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/test_app.dart';

/// The "Child mode" section of the settings (contracts/ui/06 §6.1, FR-032,
/// FR-033).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Finder byKey(String key) => find.byKey(Key(key));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpSection(
    WidgetTester tester, {
    AppSettings settings = AppSettings.initial,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              Scaffold(body: ListView(children: const [ChildModeSection()])),
        ),
        GoRoute(
          path: AppRoutes.batteryHelp,
          builder: (context, state) => Scaffold(
            key: const Key('battery.screen'),
            body: Text(state.uri.fragment, key: const Key('test.anchor')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(settings: settings),
        child: MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  bool isChildLockEnabled(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(byKey('settings.childLock')))
          .read(appSettingsProvider)
          .childLockEnabled;

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(byKey('settings.childLock')).value;

  testWidgets('shows the child lock on by default', (tester) async {
    await pumpSection(tester);

    expect(switchValue(tester), isTrue);
  });

  testWidgets('turning the lock off asks first; cancel keeps it on', (
    tester,
  ) async {
    await pumpSection(tester);

    await tester.tap(byKey('settings.childLock'));
    await settle(tester);
    expect(byKey('confirm.dialog'), findsOneWidget);

    await tester.tap(byKey('confirm.cancel'));
    await settle(tester);
    expect(isChildLockEnabled(tester), isTrue);
    expect(switchValue(tester), isTrue);
  });

  testWidgets('confirming turns the lock off and saves it', (tester) async {
    await pumpSection(tester);

    await tester.tap(byKey('settings.childLock'));
    await settle(tester);
    await tester.tap(byKey('confirm.confirm'));
    await settle(tester);

    expect(isChildLockEnabled(tester), isFalse);
    expect(switchValue(tester), isFalse);
    expect(dependencies.settingsRepository.load().childLockEnabled, isFalse);
  });

  testWidgets('turning the lock on needs no confirmation', (tester) async {
    await pumpSection(
      tester,
      settings: const AppSettings(childLockEnabled: false),
    );

    await tester.tap(byKey('settings.childLock'));
    await settle(tester);

    expect(byKey('confirm.dialog'), findsNothing);
    expect(isChildLockEnabled(tester), isTrue);
  });

  testWidgets('links to the screen pinning help (FR-033)', (tester) async {
    await pumpSection(tester);

    await tester.tap(byKey('settings.childLockPinning'));
    await settle(tester);

    expect(byKey('battery.screen'), findsOneWidget);
    expect(tester.textOf('test.anchor'), 'pinning');
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await pumpSection(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
