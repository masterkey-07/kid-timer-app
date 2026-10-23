import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:window_manager/window_manager.dart';

/// Full-screen window on Windows, macOS and Linux; `windowManager` must be
/// initialized in bootstrap.
final class WindowManagerFullscreen implements FullscreenPort {
  /// Creates the port.
  const new();

  @override
  bool get isSupported => true;

  @override
  Future<void> enter() => windowManager.setFullScreen(true);

  @override
  Future<void> exit() => windowManager.setFullScreen(false);
}
