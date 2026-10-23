import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';

/// Records whether full screen is on.
class FakeFullscreen implements FullscreenPort {
  new({this.isSupported = true});

  bool isFullscreen = false;

  @override
  final bool isSupported;

  @override
  Future<void> enter() async => isFullscreen = true;

  @override
  Future<void> exit() async => isFullscreen = false;
}
