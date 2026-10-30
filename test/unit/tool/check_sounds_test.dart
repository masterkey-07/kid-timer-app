import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/sounds/check_sounds.dart';
import '../../../tool/sounds/wav_audio.dart';

const _sampleRate = 44100;
const _alarmLufs = -20.0;
const _tickLufs = -30.0;

void main() {
  late Directory root;

  void writeManifest(Map<String, String> kindById) =>
      File('${root.path}/assets/sounds/manifest.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'schemaVersion': 1,
            'sounds': [
              for (final MapEntry(:key, :value) in kindById.entries)
                {'id': key, 'file': '$key.wav', 'kind': value},
            ],
          }),
        );

  void writeWav(String id, Uint8List bytes) =>
      File('${root.path}/assets/sounds/$id.wav')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

  /// Checks one sound of [kind] and returns the problems.
  List<String> check(String kind, Uint8List bytes) {
    writeManifest({'sound': kind});
    writeWav('sound', bytes);
    return checkSounds(root);
  }

  setUp(() => root = Directory.systemTemp.createTempSync('check_sounds_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('accepts gentle sounds of every kind', () {
    writeManifest({'bell': 'alarm', 'tock': 'tick', 'hop': 'transition'});
    writeWav('bell', _tone(seconds: 2, lufs: _alarmLufs));
    writeWav('tock', _tone(seconds: 1, lufs: _tickLufs, burst: 0.15));
    writeWav('hop', _tone(seconds: 0.8, lufs: _alarmLufs));

    expect(checkSounds(root), isEmpty);
  });

  test('has no sounds to check without a manifest', () {
    expect(checkSounds(root), ['assets/sounds/manifest.json: not found']);
  });

  test('reports a missing sound file', () {
    writeManifest({'bell': 'alarm'});

    expect(checkSounds(root), [contains('bell.wav: not found')]);
  });

  test('rejects an unknown kind', () {
    final problems = check('whistle', _tone(seconds: 2, lufs: _alarmLufs));

    expect(problems, [contains('unknown kind "whistle"')]);
  });

  group('format', () {
    test('rejects bytes that are not a WAV', () {
      final problems = check('alarm', Uint8List.fromList([1, 2, 3]));

      expect(problems, [contains('not a RIFF/WAVE file')]);
    });

    test('rejects another sample rate', () {
      final bytes = _tone(seconds: 2, lufs: _alarmLufs, sampleRate: 22050);

      expect(check('alarm', bytes), [contains('22050 Hz')]);
    });

    test('rejects stereo', () {
      final bytes = _tone(seconds: 2, lufs: _alarmLufs);
      ByteData.sublistView(bytes).setUint16(22, 2, Endian.little);

      expect(check('alarm', bytes), [contains('2 channels')]);
    });

    test('rejects a file over 500 KB', () {
      final bytes = _tone(seconds: 6, lufs: _alarmLufs);

      expect(check('transition', bytes), contains(contains('KB')));
    });
  });

  group('loudness', () {
    test('rejects an alarm that is too loud', () {
      final problems = check('alarm', _tone(seconds: 2, lufs: -17));

      expect(problems, [contains('LUFS')]);
    });

    test('rejects an alarm that is too quiet', () {
      final problems = check('alarm', _tone(seconds: 2, lufs: -24));

      expect(problems, [contains('LUFS')]);
    });

    test('holds the tick to −30 LUFS', () {
      final problems = check(
        'tick',
        _tone(seconds: 1, lufs: _alarmLufs, burst: 0.15),
      );

      expect(problems, [contains('LUFS')]);
    });

    test('rejects a true peak above −3 dBTP', () {
      final bytes = _tone(seconds: 2, lufs: _alarmLufs, peakBoostDb: 18);

      expect(check('alarm', bytes), contains(contains('dBTP')));
    });
  });

  group('length', () {
    test('rejects an alarm under 1 s', () {
      final problems = check('alarm', _tone(seconds: 0.6, lufs: _alarmLufs));

      expect(problems, [contains('between 1 and 5 s')]);
    });

    test('rejects an alarm over 5 s', () {
      final problems = check('alarm', _tone(seconds: 5.5, lufs: _alarmLufs));

      expect(problems, [contains('between 1 and 5 s')]);
    });

    test('needs the tick to be exactly 1 s so it loops once a second', () {
      final problems = check(
        'tick',
        _tone(seconds: 0.7, lufs: _tickLufs, burst: 0.15),
      );

      expect(problems, [contains('exactly 1 s')]);
    });
  });

  group('softness', () {
    test('rejects a click at the start', () {
      final problems = check(
        'alarm',
        _tone(seconds: 2, lufs: _alarmLufs, attackSeconds: 0),
      );

      expect(problems, contains(contains('attack')));
    });

    test('rejects a click at the end', () {
      final problems = check(
        'alarm',
        _tone(seconds: 2, lufs: _alarmLufs, fadeOutSeconds: 0),
      );

      expect(problems, contains(contains('end')));
    });

    test('rejects piercing content above 12 kHz', () {
      final problems = check(
        'alarm',
        _tone(seconds: 2, lufs: _alarmLufs, frequency: 14000),
      );

      expect(problems, contains(contains('12 kHz')));
    });
  });

  test('prints a summary and fails the run on a problem', () {
    writeManifest({'bell': 'alarm'});
    final out = StringBuffer();

    expect(runCheckSounds(root, out), 1);
    expect(out.toString(), contains('bell.wav'));
  });

  test('prints a summary and passes the run when all is fine', () {
    writeManifest({'bell': 'alarm'});
    writeWav('bell', _tone(seconds: 2, lufs: _alarmLufs));
    final out = StringBuffer();

    expect(runCheckSounds(root, out), 0);
    expect(out.toString(), contains('meet the research R6 targets'));
  });
}

/// A mono sine of [seconds], faded in and out, scaled to [lufs].
///
/// [burst] keeps sound only for that many seconds (a tick); [peakBoostDb]
/// adds a lone spike this many dB above the body to push the peak up
/// without changing the loudness much.
Uint8List _tone({
  required double seconds,
  required double lufs,
  double frequency = 600,
  double attackSeconds = 0.03,
  double fadeOutSeconds = 0.1,
  double? burst,
  double peakBoostDb = 0,
  int sampleRate = _sampleRate,
}) {
  final count = (seconds * sampleRate).round();
  final soundCount = burst == null ? count : (burst * sampleRate).round();
  final samples = Float64List(count);
  for (var i = 0; i < soundCount; i++) {
    final t = i / sampleRate;
    final fadeIn = attackSeconds == 0 ? 1.0 : min(1, t / attackSeconds);
    final fadeOut = fadeOutSeconds == 0
        ? 1.0
        : min(1, (soundCount - 1 - i) / (fadeOutSeconds * sampleRate));
    samples[i] = sin(2 * pi * frequency * t) * fadeIn * fadeOut;
  }

  final gain = pow(
    10,
    (lufs - integratedLoudness(samples, sampleRate: sampleRate)) / 20,
  ).toDouble();
  for (var i = 0; i < count; i++) {
    samples[i] *= gain;
  }
  if (peakBoostDb > 0) {
    final middle = soundCount ~/ 2;
    samples[middle] = pow(
      10,
      (peakDbfs(samples) + peakBoostDb) / 20,
    ).toDouble().clamp(0, 1);
  }
  return encodeWav(samples, sampleRate: sampleRate);
}
