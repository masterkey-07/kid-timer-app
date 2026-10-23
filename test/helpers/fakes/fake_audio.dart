import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';

/// Records every audio call as a readable string.
class FakeAudio implements AudioPort {
  final List<String> calls = [];
  bool isTicking = false;

  /// What [systemVolume] returns.
  double? systemVolumeValue = 1;

  @override
  Future<void> preload(Iterable<SoundId> sounds) async =>
      calls.add('preload(${sounds.map((sound) => sound.value).join(', ')})');

  @override
  Future<void> playAlarm(
    SoundId sound, {
    required double volume,
    int repeat = 1,
  }) async => calls.add('playAlarm(${sound.value}, $volume, $repeat)');

  @override
  Future<void> playPreview(SoundId sound, {required double volume}) async =>
      calls.add('playPreview(${sound.value}, $volume)');

  @override
  Future<void> startTicking({required double volume}) async {
    isTicking = true;
    calls.add('startTicking($volume)');
  }

  @override
  Future<void> stopTicking() async {
    isTicking = false;
    calls.add('stopTicking');
  }

  @override
  Future<void> stopAll() async {
    isTicking = false;
    calls.add('stopAll');
  }

  @override
  Future<double?> systemVolume() async => systemVolumeValue;
}
