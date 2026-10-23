import 'package:flutter/services.dart';
import 'package:visual_time_counter/core/platform/haptics/haptics_port.dart';

/// [HapticsPort] backed by Flutter's [HapticFeedback]; on platforms without
/// a vibrator ([hasVibrator] false) every call is a no-op.
final class FlutterHapticsPort implements HapticsPort {
  /// Creates the port; [hasVibrator] comes from the platform selection.
  const new({required this.hasVibrator});

  static const _pulseGap = Duration(milliseconds: 300);

  @override
  final bool hasVibrator;

  @override
  Future<void> selectionTick() async {
    if (hasVibrator) await HapticFeedback.selectionClick();
  }

  @override
  Future<void> alarmPattern() async {
    if (!hasVibrator) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(_pulseGap);
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> softPulse() async {
    if (hasVibrator) await HapticFeedback.lightImpact();
  }
}
