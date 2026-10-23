import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';

/// The AudioPort contract, shared by the fake and the real implementation:
/// every method completes without throwing.
void runAudioContract(
  String description,
  Future<AudioPort> Function() createPort,
) {
  group('$description AudioPort contract', () {
    late AudioPort port;

    setUp(() async => port = await createPort());
    tearDown(() => port.stopAll());

    test('preloads sounds, including an empty set', () async {
      await port.preload([SoundId.chimeSoft]);
      await port.preload(const []);
    });

    test('plays the alarm, repeated, and a preview', () async {
      await port.playAlarm(SoundId.chimeSoft, volume: 0.7, repeat: 3);
      await port.playPreview(SoundId.chimeSoft, volume: 0.5);
    });

    test('playing no sound is a no-op', () async {
      await port.playAlarm(SoundId.none, volume: 0.7);
    });

    test('ticking starts and stops idempotently', () async {
      await port.startTicking(volume: 0.3);
      await port.startTicking(volume: 0.3);
      await port.stopTicking();
      await port.stopTicking();
    });

    test('stopAll is safe when nothing plays', () async {
      await port.stopAll();
    });

    test('system volume is null or within 0.0–1.0', () async {
      final volume = await port.systemVolume();

      if (volume != null) expect(volume, inInclusiveRange(0, 1));
    });
  });
}
