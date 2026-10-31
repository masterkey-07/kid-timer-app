import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/child_lock/presentation/hold_to_unlock.dart';
import 'package:visual_time_counter/features/parental/application/parental_gate_controller.dart';
import 'package:visual_time_counter/features/parental/presentation/parental_gate.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../helpers/a11y_expectations.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_app.dart';

/// The shortest cycle of a repeating animation (contracts/ui/00 §4, flash
/// safety: at most 3 luminance changes per second).
const _minimumAnimationCycle = Duration(milliseconds: 400);

const _settleStep = Duration(milliseconds: 500);
const _pageTransition = Duration(seconds: 1);

/// Enough for the longest list (the image library has 40 tiles).
const _maxTabPresses = 200;
const _announcementType = 'announce';

final _running = TimerSession(
  id: 'sweep-run',
  config: TimerConfig.defaults,
  status: SessionStatus.running,
  startedAt: testNow,
  endsAt: testNow.add(const Duration(minutes: 30)),
);

final _paused = TimerSession(
  id: 'sweep-paused',
  config: TimerConfig.defaults,
  status: SessionStatus.paused,
  startedAt: testNow,
  pausedRemaining: const Duration(minutes: 3),
);

final _finished = TimerSession(
  id: 'sweep-done',
  config: TimerConfig.defaults,
  status: SessionStatus.finished,
  startedAt: testNow.subtract(const Duration(minutes: 5)),
  endsAt: testNow,
);

/// A v1.0 screen and how to reach it.
class _Screen {
  const new({this.session, this.route, this.needsParentUnlock = false});

  /// The session that opens the screen on startup.
  final TimerSession? session;

  /// The route pushed over home; null stays on the startup screen.
  final String? route;

  /// Whether the parental gate must have been answered.
  final bool needsParentUnlock;
}

final Map<String, _Screen> _screens = {
  'home': const _Screen(),
  'run': _Screen(session: _running),
  'run (paused)': _Screen(session: _paused),
  'finished': _Screen(session: _finished),
  'images': const _Screen(route: AppRoutes.images),
  'my images': const _Screen(route: AppRoutes.imagesMine),
  'presets': const _Screen(route: AppRoutes.presets),
  'new preset': const _Screen(route: AppRoutes.presetsNew),
  'settings': const _Screen(route: AppRoutes.settings),
  'battery help': const _Screen(route: AppRoutes.batteryHelp),
  'parent area': const _Screen(
    route: AppRoutes.parent,
    needsParentUnlock: true,
  ),
  'privacy': const _Screen(
    route: AppRoutes.parentPrivacy,
    needsParentUnlock: true,
  ),
  'credits': const _Screen(
    route: AppRoutes.parentCredits,
    needsParentUnlock: true,
  ),
};

const List<Locale> _locales = [Locale('pt'), Locale('en')];

const Map<String, AppThemeMode> _themes = {
  'light': AppThemeMode.light,
  'dark': AppThemeMode.dark,
};

/// Every v1.0 screen against the accessibility rules of Constitution V
/// (testing-strategy §2 rule 6).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> openScreen(
    WidgetTester tester,
    _Screen screen, {
    Locale locale = const Locale('en'),
    AppThemeMode theme = AppThemeMode.light,
    double textScale = 1,
    ScreenClass size = ScreenClass.compact,
  }) async {
    final session = screen.session;
    if (session != null) await dependencies.sessionRepository.save(session);
    await tester.pumpKidTimerApp(
      dependencies,
      session: session,
      settings: AppSettings(childLockEnabled: false, themeMode: theme),
      locale: locale,
      textScale: textScale,
      screen: size,
    );
    await tester.pump(const Duration(seconds: 3));

    if (screen.needsParentUnlock) _unlockParentArea(tester);
    final route = screen.route;
    if (route == null) return;
    final home = tester.element(find.byKey(const Key('home.screen')));
    final extra = route == AppRoutes.presetsNew ? TimerConfig.defaults : null;
    unawaited(GoRouter.of(home).push<void>(route, extra: extra));
    await tester.pump();
    await tester.pump(_settleStep);
    await tester.pump(_pageTransition);
  }

  for (final MapEntry(key: name, value: screen) in _screens.entries) {
    group(name, () {
      for (final locale in _locales) {
        for (final MapEntry(key: themeName, value: theme) in _themes.entries) {
          testWidgets('meets the guidelines ($locale, $themeName)', (
            tester,
          ) async {
            await openScreen(tester, screen, locale: locale, theme: theme);

            await expectMeetsA11yGuidelines(tester);
          });
        }

        testWidgets('fits at 200% font ($locale)', (tester) async {
          await openScreen(
            tester,
            screen,
            locale: locale,
            textScale: maxTextScale,
          );

          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('fits a compact landscape window at 200% font', (
        tester,
      ) async {
        await openScreen(
          tester,
          screen,
          textScale: maxTextScale,
          size: ScreenClass.compactLandscape,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('every tappable control can take keyboard focus', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await openScreen(tester, screen);

        final unreachable = _tappableButNotFocusable(tester);

        expect(unreachable, isEmpty, reason: unreachable.join('\n'));
        semantics.dispose();
      });

      testWidgets('Tab visits every focusable control and goes around', (
        tester,
      ) async {
        await openScreen(tester, screen);

        // The first Tab lands in the screen on top; its scope holds the
        // controls to reach (routes underneath are out of reach).
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final first = FocusManager.instance.primaryFocus;
        final visited = <FocusNode>{?first};
        var wentAround = false;
        for (var press = 0; press < _maxTabPresses && !wentAround; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final focus = FocusManager.instance.primaryFocus;
          wentAround = focus == first;
          if (focus != null) visited.add(focus);
        }
        expect(wentAround, isTrue, reason: 'Tab never came back to the start');
        final focusable = _focusableNodesAround(first);

        // A lazy grid recycles tiles while Tab scrolls; only live ones count.
        final missed = focusable.where(
          (node) => node.context != null && !visited.contains(node),
        );
        expect(
          missed,
          isEmpty,
          reason: [
            for (final node in missed)
              '${node.rect} ${_describe(node.context!)}',
          ].join('\n'),
        );
      });
    });
  }

  group('dial announcements', () {
    late List<String> announcements;

    setUp(() {
      announcements = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            if (message is Map && message['type'] == _announcementType) {
              final data = message['data'] as Map<Object?, Object?>;
              announcements.add(data['message']! as String);
            }
            return null;
          });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(
            SystemChannels.accessibility,
            null,
          );
    });

    Future<void> runFor(WidgetTester tester, Duration length) async {
      const step = Duration(seconds: 1);
      for (var elapsed = Duration.zero; elapsed < length; elapsed += step) {
        dependencies.now = dependencies.now.add(step);
        await tester.pump(step);
      }
    }

    Future<void> startRunning(
      WidgetTester tester,
      AnnounceInterval interval,
    ) async {
      await dependencies.sessionRepository.save(_running);
      await tester.pumpKidTimerApp(
        dependencies,
        session: _running,
        settings: AppSettings(
          childLockEnabled: false,
          a11yAnnounceInterval: interval,
        ),
      );
      await tester.pump();
    }

    testWidgets('say the time left at most once per minute by default', (
      tester,
    ) async {
      await startRunning(tester, AnnounceInterval.oneMin);

      await runFor(tester, const Duration(minutes: 3));

      expect(announcements.length, inInclusiveRange(3, 4));
      expect(announcements.first, contains('minutes'));
    });

    testWidgets('wait five minutes when configured', (tester) async {
      await startRunning(tester, AnnounceInterval.fiveMin);

      await runFor(tester, const Duration(minutes: 4));

      expect(announcements.length, lessThanOrEqualTo(1));
    });

    testWidgets('stay silent when turned off', (tester) async {
      await startRunning(tester, AnnounceInterval.off);

      await runFor(tester, const Duration(minutes: 3));

      expect(announcements, isEmpty);
    });
  });

  group('reduce motion', () {
    testWidgets('the final screen stops animating', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await openScreen(tester, _Screen(session: _finished));

      await tester.pump(const Duration(seconds: 3));

      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('high contrast', () {
    for (final brightness in Brightness.values) {
      test('the empty dial sector is opaque ($brightness)', () {
        final color = DialPalettes.empty(brightness, highContrast: true);

        expect(color.a, 1);
      });
    }

    testWidgets('the countdown still fits', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await openScreen(tester, _Screen(session: _running));

      expect(tester.takeException(), isNull);
    });
  });

  group('flash safety', () {
    test('the padlock glow cycle lasts at least 400 ms', () {
      expect(
        HoldToUnlock.glowDuration,
        greaterThanOrEqualTo(_minimumAnimationCycle),
      );
    });
  });

  group('dialogs', () {
    Future<FocusNode> openDialogOver(
      WidgetTester tester,
      Future<void> Function(BuildContext context) open,
    ) async {
      final openerFocus = FocusNode(debugLabel: 'opener');
      addTearDown(openerFocus.dispose);
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            key: const Key('opener'),
            focusNode: openerFocus,
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      );
      openerFocus.requestFocus();
      await tester.pump();
      await tester.tap(find.byKey(const Key('opener')));
      await tester.pumpAndSettle();
      return openerFocus;
    }

    /// Whether focus is on the dialog's route scope or inside it.
    bool isFocusInside(WidgetTester tester, Key dialogKey) {
      final scope = FocusScope.of(tester.element(find.byKey(dialogKey)));
      final focus = FocusManager.instance.primaryFocus;
      return focus != null &&
          (focus == scope || focus.ancestors.contains(scope));
    }

    final dialogs =
        <
          String,
          ({Key key, Future<void> Function(BuildContext) open, Key close})
        >{
          'confirmation': (
            key: const Key('confirm.dialog'),
            open: (context) => showConfirmDialog(
              context,
              title: 'Title',
              message: 'Message',
              confirmLabel: 'Go',
            ),
            close: const Key('confirm.cancel'),
          ),
          'parental gate': (
            key: const Key('gate.dialog'),
            open: showParentalGate,
            close: const Key('gate.close'),
          ),
        };

    for (final MapEntry(key: name, value: dialog) in dialogs.entries) {
      testWidgets('the $name moves focus in and traps it', (tester) async {
        await openDialogOver(tester, dialog.open);
        expect(isFocusInside(tester, dialog.key), isTrue, reason: 'on open');

        for (var press = 0; press < 20; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            isFocusInside(tester, dialog.key),
            isTrue,
            reason: 'Tab $press',
          );
        }
      });

      testWidgets('the $name gives focus back to its opener', (tester) async {
        final openerFocus = await openDialogOver(tester, dialog.open);

        await tester.tap(find.byKey(dialog.close));
        await tester.pumpAndSettle();

        expect(openerFocus.hasFocus, isTrue);
      });
    }
  });
}

/// Answers the gate so the parent routes are open.
void _unlockParentArea(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const Key('home.screen'))),
  );
  final gate = container.read(parentalGateControllerProvider.notifier);
  for (final digit
      in '${container.read(parentalGateControllerProvider).challenge.answer}'
          .split('')) {
    gate.enterDigit(int.parse(digit));
  }
  gate.submit();
}

/// The focus nodes Tab can reach from [current]: the controls of its scope.
List<FocusNode> _focusableNodesAround(FocusNode? current) {
  final scope = current?.enclosingScope;
  if (scope == null) return [];
  return scope.traversalDescendants
      .where(
        (node) =>
            node is! FocusScopeNode &&
            node.canRequestFocus &&
            !node.skipTraversal,
      )
      .toList();
}

/// Labels of the semantics nodes that react to a tap but cannot take focus,
/// so a keyboard user could not use them.
List<String> _tappableButNotFocusable(WidgetTester tester) {
  final unreachable = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final isTappable = data.hasAction(SemanticsAction.tap);
    final isFocusable = data.flagsCollection.isFocused != Tristate.none;
    final isHidden = node.isInvisible || data.flagsCollection.isHidden;
    if (isTappable && !isFocusable && !isHidden) {
      unreachable.add('"${data.label}" ${data.rect}');
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    RendererBinding
        .instance
        .renderViews
        .first
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return unreachable;
}

/// The texts under [context], to name a focus node in a failure message.
String _describe(BuildContext context) {
  final texts = <String>[];
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && widget.data != null) texts.add(widget.data!);
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return texts.toString();
}
