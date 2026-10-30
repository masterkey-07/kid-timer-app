// Generates the app's own sounds (`assets/sounds/*.wav`) and their
// `manifest.json`: soft bell-like notes synthesized from a few low partials,
// so every file is the project's own work (CC0-1.0) and meets the research R6
// gentleness targets by construction (no content above 12 kHz, 30 ms attack,
// faded ends). `check_sounds.dart` verifies the result.
//
// Usage: dart run tool/sounds/generate_sounds.dart [root]
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'wav_audio.dart';

const _sampleRate = 44100;
const _attack = Duration(milliseconds: 30);
const _tickAttack = Duration(milliseconds: 40);
const _tailFade = Duration(milliseconds: 200);
const _assetsDir = 'assets/sounds';

/// Integrated loudness targets (research R6).
const _alarmLufs = -20.0;
const _tickLufs = -30.0;

/// True-peak ceiling (research R6: ≤ −3 dBTP), with 1 dB of margin.
const _peakCeilingDbfs = -4.0;

/// A note: when it starts, its fundamental and how fast it decays.
typedef _Note = ({Duration start, double frequency, double decayPerSecond});

/// Partials as (ratio to the fundamental, relative amplitude); with the
/// fundamentals below 1.2 kHz the highest partial stays under 5 kHz.
typedef _Partials = List<(double, double)>;

const _Partials _bellPartials = [(1, 1), (2, 0.35), (3.01, 0.12)];
const _Partials _woodPartials = [(1, 1), (3.9, 0.2)];
const _Partials _purePartials = [(1, 1), (2, 0.1)];

const double _c4 = 261.63;
const double _e4 = 329.63;
const double _g4 = 392;
const double _c5 = 523.25;
const double _d5 = 587.33;
const double _e5 = 659.25;
const double _fSharp5 = 739.99;
const double _g5 = 783.99;
const double _a5 = 880;
const double _b5 = 987.77;
const double _c6 = 1046.50;

class _Sound {
  const new({
    required this.id,
    required this.kind,
    required this.namePt,
    required this.nameEn,
    required this.length,
    required this.notes,
    this.partials = _bellPartials,
    this.attack = _attack,
  });

  final String id;
  final String kind;
  final String namePt;
  final String nameEn;
  final Duration length;
  final List<_Note> notes;
  final _Partials partials;
  final Duration attack;

  double get targetLufs => kind == 'tick' ? _tickLufs : _alarmLufs;
}

_Note _note(int startMs, double frequency, double decayPerSecond) => (
  start: Duration(milliseconds: startMs),
  frequency: frequency,
  decayPerSecond: decayPerSecond,
);

final List<_Sound> _sounds = [
  _Sound(
    id: 'chime_soft',
    kind: 'alarm',
    namePt: 'Sino suave',
    nameEn: 'Soft chime',
    length: const Duration(milliseconds: 2600),
    notes: [_note(0, _g5, 2.2), _note(450, _e5, 1.8)],
  ),
  _Sound(
    id: 'bell_gentle',
    kind: 'alarm',
    namePt: 'Sininho',
    nameEn: 'Little bell',
    length: const Duration(milliseconds: 3000),
    notes: [_note(0, _c5, 1.6)],
  ),
  _Sound(
    id: 'ding_dong',
    kind: 'alarm',
    namePt: 'Dim-dom',
    nameEn: 'Ding dong',
    length: const Duration(milliseconds: 3000),
    notes: [_note(0, _e5, 1.5), _note(700, _c5, 1.5)],
  ),
  _Sound(
    id: 'marimba',
    kind: 'alarm',
    namePt: 'Marimba',
    nameEn: 'Marimba',
    length: const Duration(milliseconds: 2200),
    partials: _woodPartials,
    notes: [_note(0, _c5, 5), _note(250, _e5, 5), _note(500, _g5, 4)],
  ),
  _Sound(
    id: 'harp',
    kind: 'alarm',
    namePt: 'Harpa',
    nameEn: 'Harp',
    length: const Duration(milliseconds: 3200),
    partials: _purePartials,
    notes: [
      _note(0, _c5, 2.6),
      _note(300, _e5, 2.6),
      _note(600, _g5, 2.6),
      _note(900, _c6, 2.4),
    ],
  ),
  _Sound(
    id: 'music_box',
    kind: 'alarm',
    namePt: 'Caixinha de música',
    nameEn: 'Music box',
    length: const Duration(milliseconds: 3400),
    notes: [
      _note(0, _g5, 3),
      _note(350, _e5, 3),
      _note(700, _c5, 3),
      _note(1050, _g5, 2.4),
    ],
  ),
  _Sound(
    id: 'xylophone',
    kind: 'alarm',
    namePt: 'Xilofone',
    nameEn: 'Xylophone',
    length: const Duration(milliseconds: 2000),
    partials: _woodPartials,
    notes: [_note(0, _d5, 5), _note(300, _a5, 4.5)],
  ),
  _Sound(
    id: 'water_drop',
    kind: 'alarm',
    namePt: 'Gota d’água',
    nameEn: 'Water drop',
    length: const Duration(milliseconds: 2400),
    partials: _purePartials,
    notes: [_note(0, _b5, 4), _note(500, _fSharp5, 3.5)],
  ),
  _Sound(
    id: 'lullaby',
    kind: 'alarm',
    namePt: 'Cantiga de ninar',
    nameEn: 'Lullaby',
    length: const Duration(milliseconds: 4200),
    partials: _purePartials,
    notes: [_note(0, _e4, 1.2), _note(900, _g4, 1.2), _note(1800, _c4 * 2, 1)],
  ),
  _Sound(
    id: 'tick_soft',
    kind: 'tick',
    namePt: 'Tique suave',
    nameEn: 'Soft tick',
    // Looped by the app: one play lasts exactly one second.
    length: const Duration(seconds: 1),
    partials: _woodPartials,
    attack: _tickAttack,
    notes: [_note(0, _c5, 14)],
  ),
  _Sound(
    id: 'transition_soft',
    kind: 'transition',
    namePt: 'Transição suave',
    nameEn: 'Soft transition',
    length: const Duration(milliseconds: 900),
    partials: _purePartials,
    notes: [_note(0, _c5, 4), _note(200, _g5, 4)],
  ),
];

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  final folder = Directory('${root.path}/$_assetsDir')
    ..createSync(recursive: true);

  for (final sound in _sounds) {
    final samples = _normalized(_synthesize(sound), sound.targetLufs);
    File('${folder.path}/${sound.id}.wav')
        .writeAsBytesSync(encodeWav(samples, sampleRate: _sampleRate));
    final loudness = integratedLoudness(samples, sampleRate: _sampleRate);
    stdout.writeln(
      '${sound.id}: ${sound.length.inMilliseconds} ms, '
      '${loudness.toStringAsFixed(1)} LUFS, '
      'peak ${peakDbfs(samples).toStringAsFixed(1)} dBFS',
    );
  }
  File('${folder.path}/manifest.json').writeAsStringSync(_manifest());
}

String _manifest() {
  final json = {
    'schemaVersion': 1,
    'sounds': [
      for (final sound in _sounds)
        {
          'id': sound.id,
          'file': '${sound.id}.wav',
          'kind': sound.kind,
          'names': {'pt': sound.namePt, 'en': sound.nameEn},
        },
    ],
  };
  return '${const JsonEncoder.withIndent('  ').convert(json)}\n';
}

Float64List _synthesize(_Sound sound) {
  final count = _sampleCount(sound.length);
  final samples = Float64List(count);
  for (final note in sound.notes) {
    final first = _sampleCount(note.start);
    for (var i = first; i < count; i++) {
      final t = (i - first) / _sampleRate;
      final envelope =
          _attackGain(t, sound.attack) * exp(-note.decayPerSecond * t);
      for (final (ratio, amplitude) in sound.partials) {
        samples[i] +=
            envelope * amplitude * sin(2 * pi * note.frequency * ratio * t);
      }
    }
  }

  final fadeSamples = _sampleCount(_tailFade);
  for (var i = 0; i < fadeSamples; i++) {
    samples[count - 1 - i] *= i / fadeSamples;
  }
  return samples;
}

double _attackGain(double seconds, Duration attack) {
  final attackSeconds = attack.inMicroseconds / Duration.microsecondsPerSecond;
  return seconds >= attackSeconds ? 1 : seconds / attackSeconds;
}

/// Scales to [targetLufs], then lowers further if the peak would pass the
/// ceiling.
Float64List _normalized(Float64List samples, double targetLufs) {
  final measured = integratedLoudness(samples, sampleRate: _sampleRate);
  final loudnessGain = pow(10, (targetLufs - measured) / 20).toDouble();
  final peakGain =
      pow(10, _peakCeilingDbfs / 20).toDouble() /
      pow(10, peakDbfs(samples) / 20).toDouble();
  final gain = min(loudnessGain, peakGain);
  return Float64List.fromList([for (final s in samples) s * gain]);
}

int _sampleCount(Duration duration) =>
    duration.inMicroseconds * _sampleRate ~/ Duration.microsecondsPerSecond;
