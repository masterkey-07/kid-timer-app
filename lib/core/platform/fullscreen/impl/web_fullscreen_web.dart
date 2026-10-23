import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:web/web.dart' as web;

/// The browser Fullscreen API; [enter] must run inside a user gesture (the
/// Start tap), otherwise the browser refuses it.
final class WebFullscreen implements FullscreenPort {
  /// Creates the port.
  const new();

  @override
  bool get isSupported => web.document.fullscreenEnabled;

  @override
  Future<void> enter() async {
    if (web.document.fullscreenElement != null) return;
    try {
      await web.document.documentElement?.requestFullscreen().toDart;
    } on Object catch (error) {
      // Refused without a user gesture or by the browser settings; the
      // countdown works the same without full screen.
      debugPrint('Fullscreen refused: $error');
    }
  }

  @override
  Future<void> exit() async {
    if (web.document.fullscreenElement == null) return;
    await web.document.exitFullscreen().toDart;
  }
}
