import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';

/// Placeholder used outside the Web; never selected there.
final class WebFullscreen implements FullscreenPort {
  /// Creates the port.
  const new();

  @override
  bool get isSupported => false;

  @override
  Future<void> enter() async {}

  @override
  Future<void> exit() async {}
}
