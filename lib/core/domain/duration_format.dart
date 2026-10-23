/// Formats a remaining time as `mm:ss`, or `h:mm:ss` from one hour on
/// (FR-004).
///
/// Partial seconds round up, so `00:00` only shows when time is up.
String formatRemaining(Duration remaining) {
  if (remaining <= Duration.zero) return '00:00';

  final totalSeconds =
      (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  final hours = totalSeconds ~/ Duration.secondsPerHour;
  final minutes =
      (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final seconds = totalSeconds % Duration.secondsPerMinute;

  final mmss = '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  return hours > 0 ? '$hours:$mmss' : mmss;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
