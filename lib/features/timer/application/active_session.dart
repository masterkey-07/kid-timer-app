import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

/// The session loaded from storage at startup; bootstrap overrides it.
final restoredSessionProvider = Provider<TimerSession?>((ref) => null);

/// The current timer session, if any, owned by the [TimerController].
final activeSessionProvider = Provider<TimerSession?>(
  (ref) => ref.watch(timerControllerProvider),
);
