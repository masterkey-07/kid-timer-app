import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// [duration] as screen readers say it, e.g. "4 minutes and 12 seconds";
/// partial seconds round up, like the digits.
String spokenDuration(AppLocalizations l10n, Duration duration) {
  final totalSeconds =
      (duration.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  final hours = totalSeconds ~/ Duration.secondsPerHour;
  final minutes =
      (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final seconds = totalSeconds % Duration.secondsPerMinute;

  final parts = [
    if (hours > 0) l10n.durationHours(hours),
    if (minutes > 0) l10n.durationMinutes(minutes),
    if (seconds > 0 || totalSeconds == 0) l10n.durationSeconds(seconds),
  ];
  if (parts.length == 1) return parts.single;
  return l10n.durationJoin(parts.take(parts.length - 1).join(', '), parts.last);
}
