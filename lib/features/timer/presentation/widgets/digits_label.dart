import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/duration_format.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

/// [duration] as `mm:ss` or `h:mm:ss` in the display style with tabular
/// figures (FR-004).
///
/// Screen readers skip it when [excludeSemantics] is set, because the dial
/// already announces the time.
class DigitsLabel extends StatelessWidget {
  /// Creates the label.
  const new({required this.duration, this.excludeSemantics = false, super.key});

  /// The time to show.
  final Duration duration;

  /// Whether screen readers skip the label.
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      excluding: excludeSemantics,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          formatRemaining(duration),
          style: theme.textTheme.displayLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A [DigitsLabel] showing [session]'s remaining time, rebuilt only when the
/// shown second changes.
class CountdownDigits extends ConsumerStatefulWidget {
  /// Creates the digits for [session].
  const new({required this.session, super.key});

  /// The session counting down.
  final TimerSession session;

  @override
  ConsumerState<CountdownDigits> createState() => _CountdownDigitsState();
}

class _CountdownDigitsState extends ConsumerState<CountdownDigits>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _tick());
  late String _shown = formatRemaining(_remaining);

  Duration get _remaining =>
      widget.session.remaining(ref.read(clockProvider).now());

  bool get _isRunning => widget.session.status == SessionStatus.running;

  @override
  void initState() {
    super.initState();
    if (_isRunning) _ticker.start();
  }

  @override
  void didUpdateWidget(CountdownDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    _shown = formatRemaining(_remaining);
    if (_isRunning && !_ticker.isActive) _ticker.start();
    if (!_isRunning && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick() {
    final next = formatRemaining(_remaining);
    if (next != _shown) setState(() => _shown = next);
  }

  @override
  Widget build(BuildContext context) =>
      DigitsLabel(duration: _remaining, excludeSemantics: true);
}
