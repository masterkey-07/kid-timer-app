import 'package:visual_time_counter/core/domain/sound_id.dart';

/// Plays the app's sounds while it is in the foreground; one channel each
/// for alarm, preview and ticking.
abstract interface class AudioPort {
  /// Loads [sounds] ahead of time.
  Future<void> preload(Iterable<SoundId> sounds);

  /// Plays the end alarm [repeat] times at [volume] (0.0–1.0).
  Future<void> playAlarm(
    SoundId sound, {
    required double volume,
    int repeat = 1,
  });

  /// Plays a short preview at [volume] (sound picker).
  Future<void> playPreview(SoundId sound, {required double volume});

  /// Starts the once-per-second tick at [volume].
  Future<void> startTicking({required double volume});

  /// Stops the tick.
  Future<void> stopTicking();

  /// Stops every channel.
  Future<void> stopAll();

  /// The system media volume (0.0–1.0), or null where unavailable.
  Future<double?> systemVolume();
}
