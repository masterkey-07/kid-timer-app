import 'package:visual_time_counter/core/platform/haptics/haptics_port.dart';

/// Records every haptic call.
class FakeHaptics implements HapticsPort {
  new({this.hasVibrator = true});

  final List<String> calls = [];

  @override
  final bool hasVibrator;

  @override
  Future<void> selectionTick() async => calls.add('selectionTick');

  @override
  Future<void> alarmPattern() async => calls.add('alarmPattern');

  @override
  Future<void> softPulse() async => calls.add('softPulse');
}
