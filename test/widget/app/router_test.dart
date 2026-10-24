import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

import '../../helpers/test_app.dart';

TimerSession _session(SessionStatus status, {bool acknowledged = false}) =>
    TimerSession(
      id: 's1',
      config: TimerConfig.defaults,
      status: status,
      startedAt: testNow,
      endsAt:
          status == SessionStatus.running || status == SessionStatus.finished
          ? testNow.add(const Duration(minutes: 5))
          : null,
      pausedRemaining: status == SessionStatus.paused
          ? const Duration(minutes: 3)
          : null,
      finishedAcknowledged: acknowledged,
    );

const _knownPreset = 'preset-1';

void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  /// The countdown dial repaints every frame, so pumpAndSettle never ends.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpApp(WidgetTester tester, {TimerSession? session}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(
          session: session,
          presetExists: (id) => id == _knownPreset,
        ),
        child: const KidTimerApp(),
      ),
    );
    await settle(tester);
  }

  Future<void> openDeepLink(WidgetTester tester, String link) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': link}),
      ),
      (_) {},
    );
    await settle(tester);
  }

  group('guards on opening the app', () {
    testWidgets('no session opens home', (tester) async {
      await pumpApp(tester);

      expect(find.byKey(const Key('home.screen')), findsOneWidget);
    });

    testWidgets('a running session opens /run', (tester) async {
      await pumpApp(tester, session: _session(SessionStatus.running));

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
    });

    testWidgets('a paused session opens /run', (tester) async {
      await pumpApp(tester, session: _session(SessionStatus.paused));

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
    });

    testWidgets('an unacknowledged finished session opens /finished', (
      tester,
    ) async {
      await pumpApp(tester, session: _session(SessionStatus.finished));

      expect(find.byKey(const Key('finished.screen')), findsOneWidget);
    });

    testWidgets('an acknowledged finished session opens home', (tester) async {
      await pumpApp(
        tester,
        session: _session(SessionStatus.finished, acknowledged: true),
      );

      expect(find.byKey(const Key('home.screen')), findsOneWidget);
    });
  });

  group('deep links', () {
    testWidgets('vtc://run opens the active countdown', (tester) async {
      await pumpApp(tester, session: _session(SessionStatus.running));
      await openDeepLink(tester, 'vtc://run');

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
    });

    testWidgets('vtc://run without a session opens home', (tester) async {
      await pumpApp(tester);
      await openDeepLink(tester, 'vtc://run');

      expect(find.byKey(const Key('home.screen')), findsOneWidget);
    });

    testWidgets('an unknown preset opens home with a snackbar', (tester) async {
      await pumpApp(tester);
      await openDeepLink(tester, 'vtc://preset/missing/start');

      expect(find.byKey(const Key('home.screen')), findsOneWidget);
      expect(find.byKey(const Key('deepLink.presetNotFound')), findsOneWidget);
    });
  });

  group('notifications', () {
    testWidgets('a notification tap follows its deep link', (tester) async {
      await pumpApp(tester, session: _session(SessionStatus.running));
      // Leave the countdown for home, where a tap must bring it back.
      await openDeepLink(tester, 'vtc://preset/missing/start');
      expect(find.byKey(const Key('home.screen')), findsOneWidget);

      dependencies.alarms.simulateTap('vtc://run');
      await settle(tester);

      expect(find.byKey(const Key('run.screen')), findsOneWidget);
    });

    testWidgets('the notification that launched the app is followed', (
      tester,
    ) async {
      dependencies.alarms.launchPayloadValue = 'vtc://preset/missing/start';

      await pumpApp(tester);

      expect(find.byKey(const Key('deepLink.presetNotFound')), findsOneWidget);
    });
  });

  group('redirectFor', () {
    bool presetExists(String id) => id == _knownPreset;

    test('keeps ordinary navigation', () {
      expect(
        redirectFor(Uri.parse('/'), session: null, presetExists: presetExists),
        isNull,
      );
    });

    test('/run without an active session goes home', () {
      expect(
        redirectFor(
          Uri.parse('/run'),
          session: _session(SessionStatus.finished),
          presetExists: presetExists,
        ),
        AppRoutes.home,
      );
    });

    test('/finished needs an unacknowledged finished session', () {
      expect(
        redirectFor(
          Uri.parse('/finished'),
          session: _session(SessionStatus.running),
          presetExists: presetExists,
        ),
        AppRoutes.home,
      );
      expect(
        redirectFor(
          Uri.parse('/finished'),
          session: _session(SessionStatus.finished),
          presetExists: presetExists,
        ),
        isNull,
      );
    });

    test('vtc://run on a finished session opens /finished', () {
      expect(
        redirectFor(
          Uri.parse('vtc://run'),
          session: _session(SessionStatus.finished),
          presetExists: presetExists,
        ),
        AppRoutes.finished,
      );
    });

    test('a known preset asks home to start it', () {
      expect(
        redirectFor(
          Uri.parse('vtc://preset/$_knownPreset/start'),
          session: null,
          presetExists: presetExists,
        ),
        '/?startPreset=$_knownPreset',
      );
    });

    test('an unknown preset goes home with a notice', () {
      expect(
        redirectFor(
          Uri.parse('vtc://preset/nope/start'),
          session: null,
          presetExists: presetExists,
        ),
        '/?notice=presetNotFound',
      );
    });

    test('malformed vtc links go home', () {
      for (final link in [
        'vtc://preset',
        'vtc://preset/x/stop',
        'vtc://other',
      ]) {
        expect(
          redirectFor(
            Uri.parse(link),
            session: null,
            presetExists: presetExists,
          ),
          AppRoutes.home,
          reason: link,
        );
      }
    });
  });

  testWidgets('an unknown route falls back to home', (tester) async {
    await pumpApp(tester);
    await openDeepLink(tester, '/does-not-exist');

    expect(find.byKey(const Key('home.screen')), findsOneWidget);
  });
}
