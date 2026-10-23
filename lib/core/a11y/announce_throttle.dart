import 'package:clock/clock.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';

/// How often the remaining time may be announced to screen readers
/// (Constitution V: at most once per minute, configurable).
enum AnnounceInterval {
  /// Once per minute (default).
  oneMin(Duration(minutes: 1)),

  /// Once every five minutes.
  fiveMin(Duration(minutes: 5)),

  /// Never.
  off(null);

  new(this.period);

  /// Decodes the persisted name.
  factory fromJson(Object? json) =>
      enumFromJson(values, json, 'a11yAnnounceInterval');

  /// The minimum time between announcements; null when [off].
  final Duration? period;

  /// Encodes as the enum name.
  String toJson() => name;
}

/// Lets at most one announcement through per [AnnounceInterval].
final class AnnounceThrottle {
  /// Creates a throttle for [interval] reading time from [_clock].
  new({required this.interval, required this._clock});

  /// The configured interval.
  final AnnounceInterval interval;

  final Clock _clock;
  DateTime? _lastAnnouncement;

  /// Whether an announcement may happen now; when it may, the attempt is
  /// recorded as the latest announcement.
  bool tryAnnounce() {
    final period = interval.period;
    if (period == null) return false;

    final now = _clock.now();
    final last = _lastAnnouncement;
    if (last != null && now.difference(last) < period) return false;

    _lastAnnouncement = now;
    return true;
  }

  /// Forgets the latest announcement so the next attempt passes.
  void reset() => _lastAnnouncement = null;
}
