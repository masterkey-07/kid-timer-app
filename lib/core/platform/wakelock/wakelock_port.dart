/// Keeps the screen on during a countdown (FR-014).
abstract interface class WakeLockPort {
  /// Keeps the screen on.
  Future<void> enable();

  /// Lets the screen turn off again.
  Future<void> disable();

  /// Whether the screen is being kept on.
  Future<bool> get isEnabled;
}
