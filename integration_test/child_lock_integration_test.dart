import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:visual_time_counter/core/platform/fullscreen/impl/system_chrome_fullscreen.dart';
import 'package:visual_time_counter/core/platform/fullscreen/impl/window_manager_fullscreen.dart';
import 'package:visual_time_counter/core/platform/lifecycle/impl/flutter_app_lifecycle_port.dart';
import 'package:window_manager/window_manager.dart';

import '../test/helpers/test_app.dart';

/// Child mode with the real full screen and lifecycle ports (FR-030,
/// FR-031). Android and Linux; on Linux the window really goes full screen
/// and holding Esc for 3 s unlocks, on Android the padlock does.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const hold = Duration(seconds: 3);
  final isDesktop = defaultTargetPlatform == TargetPlatform.linux;

  late TestAppDependencies dependencies;
  late FlutterAppLifecyclePort lifecycle;

  setUpAll(() async {
    if (isDesktop) await windowManager.ensureInitialized();
  });

  setUp(() async {
    lifecycle = FlutterAppLifecyclePort();
    final FullscreenPort fullscreen = isDesktop
        ? const WindowManagerFullscreen()
        : const SystemChromeFullscreen();
    dependencies = await TestAppDependencies.create()
      ..fullscreenOverride = fullscreen
      ..lifecycleOverride = lifecycle;
  });
  tearDown(() async {
    await dependencies.fullscreenOverride!.exit();
    await lifecycle.dispose();
    await dependencies.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> expectFullScreen({required bool isOn}) async {
    if (isDesktop) expect(await windowManager.isFullScreen(), isOn);
  }

  Future<void> unlock(WidgetTester tester) async {
    if (isDesktop) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump(hold);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    } else {
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('run.lock'))),
      );
      await tester.pump(hold);
      await press.up();
    }
    await tester.pump();
  }

  testWidgets('the countdown runs full screen and unlocks after a 3 s hold', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(),
        child: const KidTimerApp(),
      ),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('home.start')));
    await settle(tester);
    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    expect(find.byKey(const Key('run.pauseResume')), findsNothing);
    await expectFullScreen(isOn: true);

    await unlock(tester);
    expect(find.byKey(const Key('run.pauseResume')), findsOneWidget);

    await tester.tap(find.byKey(const Key('run.stop')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('confirm.confirm')));
    await settle(tester);
    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    await expectFullScreen(isOn: false);
  });
}
