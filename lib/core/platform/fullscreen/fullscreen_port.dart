/// Full-screen / immersive mode for the countdown.
abstract interface class FullscreenPort {
  /// Enters full screen; on the Web it must be called from a user gesture.
  Future<void> enter();

  /// Leaves full screen.
  Future<void> exit();

  /// Whether the platform supports full screen.
  bool get isSupported;
}
