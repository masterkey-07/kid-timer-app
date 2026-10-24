import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/core/platform/wakelock/impl/wakelock_plus_port.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../test/helpers/test_app.dart';

/// The real wakelock keeps the screen on during the countdown and lets it
/// go when the timer stops (FR-014). Android and Linux; on Linux it needs a
/// desktop session with a screensaver inhibitor on D-Bus.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestAppDependencies dependencies;
  const wakeLock = WakelockPlusPort();

  setUp(
    () async => dependencies = await TestAppDependencies.create()
      ..wakeLockOverride = wakeLock,
  );
  tearDown(() async {
    await wakeLock.disable();
    await dependencies.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the countdown holds the wakelock until it stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(
          settings: const AppSettings(childLockEnabled: false),
        ),
        child: const KidTimerApp(),
      ),
    );
    await settle(tester);
    expect(await wakeLock.isEnabled, isFalse);

    await tester.tap(find.byKey(const Key('home.start')));
    await settle(tester);
    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    expect(await wakeLock.isEnabled, isTrue);

    await tester.tap(find.byKey(const Key('run.stop')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('confirm.confirm')));
    await settle(tester);
    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(await wakeLock.isEnabled, isFalse);
  });
}
