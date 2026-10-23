/// Vibration feedback; a no-op on platforms without a vibrator.
abstract interface class HapticsPort {
  /// Whether the device can vibrate.
  bool get hasVibrator;

  /// A light tick while adjusting the dial.
  Future<void> selectionTick();

  /// Two pulses at the end of the timer.
  Future<void> alarmPattern();

  /// A soft pulse for warnings (v1.x).
  Future<void> softPulse();
}
