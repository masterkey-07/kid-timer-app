import 'package:audioplayers/audioplayers.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';

/// [AudioPort] backed by `audioplayers`, with one player per channel
/// (alarm, preview, ticking). Sounds are `assets/sounds/<id>.wav`.
final class AudioplayersAudioPort implements AudioPort {
  /// Creates the port with its three players.
  new()
    : _alarm = AudioPlayer(),
      _preview = AudioPlayer(),
      _tick = AudioPlayer();

  /// A one-second tick, looped while ticking is on.
  static const _tickSound = SoundId('tick');

  final AudioPlayer _alarm;
  final AudioPlayer _preview;
  final AudioPlayer _tick;

  /// Bumped by [stopAll] so an in-progress repeat loop stops.
  int _alarmGeneration = 0;

  @override
  Future<void> preload(Iterable<SoundId> sounds) async {
    final audible = sounds.where((sound) => sound.isAudible).map(_assetPath);
    await AudioCache.instance.loadAll(audible.toList());
  }

  @override
  Future<void> playAlarm(
    SoundId sound, {
    required double volume,
    int repeat = 1,
  }) async {
    if (!sound.isAudible) return;
    final generation = ++_alarmGeneration;
    for (var play = 0; play < repeat; play++) {
      if (generation != _alarmGeneration) return;
      final completed = _alarm.onPlayerComplete.first;
      await _alarm.play(AssetSource(_assetPath(sound)), volume: volume);
      await completed;
    }
  }

  @override
  Future<void> playPreview(SoundId sound, {required double volume}) async {
    if (!sound.isAudible) return;
    await _preview.stop();
    await _preview.play(AssetSource(_assetPath(sound)), volume: volume);
  }

  @override
  Future<void> startTicking({required double volume}) async {
    await _tick.setReleaseMode(ReleaseMode.loop);
    await _tick.play(AssetSource(_assetPath(_tickSound)), volume: volume);
  }

  @override
  Future<void> stopTicking() => _tick.stop();

  @override
  Future<void> stopAll() async {
    _alarmGeneration++;
    await Future.wait([_alarm.stop(), _preview.stop(), _tick.stop()]);
  }

  /// No approved package exposes the system media volume; null means
  /// "unavailable" in the port contract.
  @override
  Future<double?> systemVolume() async => null;

  static String _assetPath(SoundId sound) => 'sounds/${sound.value}.wav';
}
