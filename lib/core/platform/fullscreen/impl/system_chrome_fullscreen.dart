import 'package:flutter/services.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';

/// Immersive mode on Android; on iOS it only hides the status bar.
final class SystemChromeFullscreen implements FullscreenPort {
  /// Creates the port.
  const new();

  @override
  bool get isSupported => true;

  @override
  Future<void> enter() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  @override
  Future<void> exit() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
