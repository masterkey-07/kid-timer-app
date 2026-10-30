import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';

/// Records every audio call as a readable string.
class FakeAudio implements AudioPort {
  final List<String> calls = [];
  bool isTicking = false;

  /// The sound being previewed; a new preview replaces it, as in the port.
  SoundId? previewing;

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
  Future<void> playPreview(SoundId sound, {required double volume}) async {
    previewing = sound;
    calls.add('playPreview(${sound.value}, $volume)');
  }

  @override
  Future<void> stopPreview() async {
    previewing = null;
    calls.add('stopPreview');
  }

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
    previewing = null;
    calls.add('stopAll');
  }

  @override
  Future<double?> systemVolume() async => systemVolumeValue;
}
