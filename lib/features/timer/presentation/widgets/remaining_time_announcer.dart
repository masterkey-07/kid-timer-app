import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Tells screen readers how much time is left, at most once per the
/// configured interval (FR-060; contracts/ui/02). Draws nothing.
class RemainingTimeAnnouncer extends ConsumerStatefulWidget {
  /// Creates the announcer.
  const new({super.key});

  @override
  ConsumerState<RemainingTimeAnnouncer> createState() =>
      _RemainingTimeAnnouncerState();
}

class _RemainingTimeAnnouncerState
    extends ConsumerState<RemainingTimeAnnouncer> {
  /// How often the throttle is asked; it decides what is let through.
  static const _checkEvery = Duration(seconds: 1);

  Timer? _ticker;
  late AnnounceThrottle _throttle = _throttleFor(
    ref.read(appSettingsProvider).a11yAnnounceInterval,
  );

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_checkEvery, (_) => _announceIfDue());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      appSettingsProvider.select((settings) => settings.a11yAnnounceInterval),
      (_, interval) => _throttle = _throttleFor(interval),
    );
    return const SizedBox.shrink();
  }

  AnnounceThrottle _throttleFor(AnnounceInterval interval) =>
      AnnounceThrottle(interval: interval, clock: ref.read(clockProvider));

  void _announceIfDue() {
    final session = ref.read(timerControllerProvider);
    if (session == null || session.status != SessionStatus.running) return;
    if (!_throttle.tryAnnounce()) return;

    final remaining = session.remaining(ref.read(clockProvider).now());
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        spokenDuration(AppLocalizations.of(context), remaining),
        Directionality.of(context),
      ),
    );
  }
}
