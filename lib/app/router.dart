import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/presentation/battery_help_screen.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/presentation/finished_screen.dart';
import 'package:visual_time_counter/features/timer/presentation/home_screen.dart';
import 'package:visual_time_counter/features/timer/presentation/run_screen.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Route paths (contracts/ui/00 §1); the other routes arrive with their
/// stories.
abstract final class AppRoutes {
  /// Home: set up a timer.
  static const home = '/';

  /// The countdown.
  static const run = '/run';

  /// The final screen.
  static const finished = '/finished';

  /// Help: battery, alarms and screen pinning.
  static const batteryHelp = '/settings/battery';

  /// [batteryHelp] scrolled to [section].
  static String batteryHelpAt(BatteryHelpSection section) =>
      '$batteryHelp#${section.name}';
}

/// The anchors of the battery help page (contracts/ui/06 §6.2).
enum BatteryHelpSection {
  /// Exact alarms and notifications.
  alarms,

  /// Battery optimization per vendor.
  battery,

  /// Screen pinning and Guided Access.
  pinning,

  /// Why Web and Linux need the window open.
  web,
}

/// Whether a preset with the given id exists; bootstrap provides it from
/// the presets box.
final presetExistsProvider = Provider<bool Function(String presetId)>(
  (ref) => throw StateError(
    'presetExistsProvider must be overridden in bootstrap or in tests',
  ),
);

/// The app router.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: initialLocationFor(ref.read(activeSessionProvider)),
    redirect: (context, state) => redirectFor(
      state.uri,
      session: ref.read(activeSessionProvider),
      presetExists: ref.read(presetExistsProvider),
    ),
    onException: (context, state, router) => router.go(AppRoutes.home),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => _DeepLinkNotice(
          notice: state.uri.queryParameters[_noticeParameter],
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.run,
        builder: (context, state) => const RunScreen(),
      ),
      GoRoute(
        path: AppRoutes.finished,
        builder: (context, state) => const FinishedScreen(),
      ),
      GoRoute(
        path: AppRoutes.batteryHelp,
        builder: (context, state) => BatteryHelpScreen(
          section: BatteryHelpSection.values.asNameMap()[state.uri.fragment],
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  _followNotifications(ref, router);
  return router;
});

/// Opens the deep link of a tapped notification, including the one that
/// launched the app (contracts/ui/08 §8.3).
void _followNotifications(Ref ref, GoRouter router) {
  var isDisposed = false;
  final alarms = ref.read(alarmSchedulerProvider);
  final taps = alarms.notificationTaps.listen(router.go);
  ref.onDispose(() {
    isDisposed = true;
    unawaited(taps.cancel());
  });

  unawaited(
    alarms.launchPayload().then((payload) {
      if (payload != null && !isDisposed) router.go(payload);
    }),
  );
}

const _deepLinkScheme = 'vtc';
const _noticeParameter = 'notice';
const _presetNotFoundNotice = 'presetNotFound';
const _startPresetParameter = 'startPreset';

/// Where the app opens for the restored [session] (contracts/ui/00 §1
/// guards).
String initialLocationFor(TimerSession? session) {
  if (_isActive(session)) return AppRoutes.run;
  if (_awaitsAcknowledgement(session)) return AppRoutes.finished;
  return AppRoutes.home;
}

/// The redirect for [uri]: maps `vtc://` deep links and keeps `/run` and
/// `/finished` consistent with [session]. Returns null to stay on [uri].
String? redirectFor(
  Uri uri, {
  required TimerSession? session,
  required bool Function(String presetId) presetExists,
}) {
  if (uri.scheme == _deepLinkScheme) {
    return _deepLinkLocation(uri, session: session, presetExists: presetExists);
  }
  if (uri.path == AppRoutes.run && !_isActive(session)) return AppRoutes.home;
  if (uri.path == AppRoutes.finished && !_awaitsAcknowledgement(session)) {
    return AppRoutes.home;
  }
  return null;
}

/// `vtc://run` opens the countdown (or the final screen once time is up);
/// `vtc://preset/<id>/start` asks home to start the preset (US5) or shows
/// "Preset not found".
String _deepLinkLocation(
  Uri uri, {
  required TimerSession? session,
  required bool Function(String presetId) presetExists,
}) {
  final segments = uri.pathSegments;
  switch (uri.host) {
    case 'run':
      return initialLocationFor(session);
    case 'preset' when segments.length == 2 && segments[1] == 'start':
      final presetId = segments.first;
      return presetExists(presetId)
          ? '${AppRoutes.home}?$_startPresetParameter=$presetId'
          : '${AppRoutes.home}?$_noticeParameter=$_presetNotFoundNotice';
    default:
      return AppRoutes.home;
  }
}

bool _isActive(TimerSession? session) => session?.status.isActive ?? false;

bool _awaitsAcknowledgement(TimerSession? session) =>
    session != null &&
    session.status == SessionStatus.finished &&
    !session.finishedAcknowledged;

/// Shows a snackbar for a deep link that could not be followed.
class _DeepLinkNotice extends StatefulWidget {
  const new({required this.notice, required this.child});

  final String? notice;
  final Widget child;

  @override
  State<_DeepLinkNotice> createState() => _DeepLinkNoticeState();
}

class _DeepLinkNoticeState extends State<_DeepLinkNotice> {
  @override
  void initState() {
    super.initState();
    _scheduleNotice();
  }

  /// Home keeps its state when only the query changes (`/` → `/?notice=…`).
  @override
  void didUpdateWidget(_DeepLinkNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notice != oldWidget.notice) _scheduleNotice();
  }

  void _scheduleNotice() {
    if (widget.notice == _presetNotFoundNotice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNotice());
    }
  }

  void _showNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('deepLink.presetNotFound'),
        content: Text(AppLocalizations.of(context).deepLinkPresetNotFound),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
