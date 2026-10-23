import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';

TimerSession _session(SessionStatus status, {bool acknowledged = false}) =>
    TimerSession(
      id: 's1',
      config: TimerConfig.defaults,
      status: status,
      startedAt: DateTime.utc(2026, 10, 23, 12),
      endsAt:
          status == SessionStatus.running || status == SessionStatus.finished
          ? DateTime.utc(2026, 10, 23, 12, 5)
          : null,
      pausedRemaining: status == SessionStatus.paused
          ? const Duration(minutes: 3)
          : null,
      finishedAcknowledged: acknowledged,
    );

const _knownPreset = 'preset-1';

void main() {
  Future<void> pumpApp(WidgetTester tester, {TimerSession? session}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restoredSessionProvider.overrideWithValue(session),
          presetExistsProvider.overrideWithValue((id) => id == _knownPreset),
        ],
        child: const KidTimerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDeepLink(WidgetTester tester, String link) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': link}),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
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
