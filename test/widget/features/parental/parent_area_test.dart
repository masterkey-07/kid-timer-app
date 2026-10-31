import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/parental/application/parental_gate_controller.dart';
import 'package:visual_time_counter/features/parental/domain/app_info.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);
const _settleStep = Duration(milliseconds: 500);

/// The parent area behind the parental gate (contracts/ui/07 §7.2).
void main() {
  late TestAppDependencies dependencies;
  late List<String> clipboard;

  setUp(() async {
    dependencies = await TestAppDependencies.create();
    clipboard = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final arguments = call.arguments as Map<Object?, Object?>;
            clipboard.add(arguments['text']! as String);
          }
          return null;
        });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await dependencies.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_settleStep);
    await tester.pump(_pageTransition);
  }

  /// Taps the widget with [key] after scrolling its dialog to it.
  Future<void> tapScrolledTo(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  /// Taps the ⓘ button and answers the gate right.
  Future<void> openParentArea(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ScreenClass screen = ScreenClass.compact,
    double textScale = 1,
  }) async {
    await tester.pumpKidTimerApp(
      dependencies,
      locale: locale,
      screen: screen,
      textScale: textScale,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('home.openAbout')));
    await settle(tester);

    final gate = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('gate.dialog'))),
    ).read(parentalGateControllerProvider).challenge;
    for (final digit in '${gate.answer}'.split('')) {
      await tapScrolledTo(tester, Key('gate.key.$digit'));
    }
    await tapScrolledTo(tester, const Key('gate.ok'));
    await settle(tester);
  }

  Future<void> openFromParentArea(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  testWidgets('the ⓘ button asks the gate before the parent area opens', (
    tester,
  ) async {
    await tester.pumpKidTimerApp(dependencies);
    await settle(tester);

    await tester.tap(find.byKey(const Key('home.openAbout')));
    await settle(tester);

    expect(find.byKey(const Key('gate.dialog')), findsOneWidget);
    expect(find.byKey(const Key('parent.screen')), findsNothing);
  });

  testWidgets('a right answer opens the parent area with version', (
    tester,
  ) async {
    await openParentArea(tester);

    expect(find.byKey(const Key('parent.screen')), findsOneWidget);
    expect(find.textContaining(AppInfo.version), findsOneWidget);
    for (final key in [
      'parent.privacy',
      'parent.licenses',
      'parent.credits',
      'parent.source',
      'parent.report',
      'parent.help',
    ]) {
      expect(
        find.byKey(Key(key), skipOffstage: false),
        findsOneWidget,
        reason: key,
      );
    }
  });

  testWidgets('closing the gate keeps the adult on home', (tester) async {
    await tester.pumpKidTimerApp(dependencies);
    await settle(tester);
    await tester.tap(find.byKey(const Key('home.openAbout')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('gate.close')));
    await settle(tester);

    expect(find.byKey(const Key('home.screen')), findsOneWidget);
    expect(find.byKey(const Key('parent.screen')), findsNothing);
  });

  testWidgets('the privacy policy is a local text in the current language', (
    tester,
  ) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.privacy');

    expect(find.byKey(const Key('privacy.screen')), findsOneWidget);
    expect(
      find.textContaining('does not collect', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('the privacy policy is Portuguese on a pt-BR device', (
    tester,
  ) async {
    await openParentArea(tester, locale: const Locale('pt'));

    await openFromParentArea(tester, 'parent.privacy');

    expect(find.textContaining('não coleta', findRichText: true), findsWidgets);
  });

  testWidgets('the licenses page opens', (tester) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.licenses');

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('the credits list the library authors and licenses', (
    tester,
  ) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.credits');

    expect(find.byKey(const Key('credits.screen')), findsOneWidget);
    expect(find.byKey(const Key('credits.error')), findsNothing);
    expect(find.textContaining('Microsoft Corporation'), findsWidgets);
    expect(find.textContaining('MIT'), findsWidgets);
  });

  testWidgets('the source link asks before opening the browser', (
    tester,
  ) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.source');
    expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
    expect(dependencies.externalLink.opened, isEmpty);

    await tester.tap(find.byKey(const Key('confirm.confirm')));
    await settle(tester);

    expect(dependencies.externalLink.opened, [Uri.parse(AppInfo.sourceUrl)]);
  });

  testWidgets('cancelling the confirmation opens nothing', (tester) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.source');
    await tester.tap(find.byKey(const Key('confirm.cancel')));
    await settle(tester);

    expect(dependencies.externalLink.opened, isEmpty);
  });

  testWidgets('tells the adult when no browser is available', (tester) async {
    dependencies.externalLink.canOpen = false;
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.source');
    await tester.tap(find.byKey(const Key('confirm.confirm')));
    await settle(tester);

    expect(find.byKey(const Key('parent.noBrowser')), findsOneWidget);
  });

  testWidgets('the report copies a diagnostic text without personal data', (
    tester,
  ) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.report');

    expect(clipboard, hasLength(1));
    final report = clipboard.single;
    expect(report, contains(AppInfo.version));
    expect(report, contains('android'));
    expect(report, contains('360x800'));
    expect(report, isNot(contains('@')));
    expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm.confirm')));
    await settle(tester);
    expect(dependencies.externalLink.opened, [Uri.parse(AppInfo.issuesUrl)]);
  });

  testWidgets('the help row opens the battery and alarms help', (tester) async {
    await openParentArea(tester);

    await openFromParentArea(tester, 'parent.help');

    expect(find.byKey(const Key('battery.screen')), findsOneWidget);
  });

  testWidgets('keeps the content at 200% font on a short screen', (
    tester,
  ) async {
    await openParentArea(
      tester,
      screen: ScreenClass.compactLandscape,
      textScale: maxTextScale,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('parent.screen')), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await openParentArea(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
