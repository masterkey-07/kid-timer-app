// Checks every sound in `assets/sounds/manifest.json` against the gentleness
// and format targets of research R6 (Constitution II, FR-052), so a harsh or
// malformed sound cannot reach the app.
//
// Usage: dart run tool/sounds/check_sounds.dart [root]
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'wav_audio.dart';

const _exitPassed = 0;
const _exitProblems = 1;

const _assetsDir = 'assets/sounds';
const _manifestFile = '$_assetsDir/manifest.json';

const int _requiredSampleRate = 44100;
const int _maxFileBytes = 500 * 1024;

const _loudnessToleranceLu = 1.0;
const _maxTruePeakDbfs = -3.0;

/// No piercing content: nothing above this frequency louder than
/// [_maxHighBandDbfs].
const _highBandHz = 12000.0;
const _maxHighBandDbfs = -40.0;

/// A sound must fade in over at least this long, so its first
/// [_attackWindow] stays below [_attackPeakRatio] of the sound's peak.
const _attackWindow = Duration(milliseconds: 20);
const _attackPeakRatio = 0.8;

/// The first and last [_edgeWindow] must be nearly silent: no click.
const _edgeWindow = Duration(milliseconds: 1);
const _maxEdgeAmplitude = 0.02;

/// What each manifest `kind` has to meet.
const _rules = <String, _Rule>{
  'alarm': _Rule(
    lufs: -20,
    minDuration: Duration(seconds: 1),
    maxDuration: Duration(seconds: 5),
    lengthText: 'between 1 and 5 s',
  ),
  'transition': _Rule(
    lufs: -20,
    minDuration: Duration(milliseconds: 300),
    maxDuration: Duration(seconds: 3),
    lengthText: 'between 0.3 and 3 s',
  ),
  // The app loops the tick file, so one play must last one second.
  'tick': _Rule(
    lufs: -30,
    minDuration: Duration(milliseconds: 995),
    maxDuration: Duration(milliseconds: 1005),
    lengthText: 'exactly 1 s',
  ),
};

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  exitCode = runCheckSounds(root, stdout);
}

/// Checks the sounds under [root], reports to [out] and returns the exit
/// code.
int runCheckSounds(Directory root, StringSink out) {
  final problems = checkSounds(root);
  if (problems.isEmpty) {
    out.writeln('Sounds meet the research R6 targets.');
    return _exitPassed;
  }
  out.writeln('Sounds need attention (research R6):');
  for (final problem in problems) {
    out.writeln('  - $problem');
  }
  return _exitProblems;
}

/// Checks every manifest sound under [root]; returns one message per
/// problem, none when all pass.
List<String> checkSounds(Directory root) {
  final manifest = File('${root.path}/$_manifestFile');
  if (!manifest.existsSync()) return ['$_manifestFile: not found'];

  final sounds = (jsonDecode(manifest.readAsStringSync()) as Map)['sounds'];
  return [
    for (final sound in (sounds as List).cast<Map<String, dynamic>>())
      ..._checkSound(root, sound['id'] as String, sound['kind'] as String),
  ];
}

List<String> _checkSound(Directory root, String id, String kind) {
  final path = '$_assetsDir/$id.wav';
  final rule = _rules[kind];
  if (rule == null) return ['$path: unknown kind "$kind"'];

  final file = File('${root.path}/$path');
  if (!file.existsSync()) return ['$path: not found'];

  final bytes = file.readAsBytesSync();
  final Audio audio;
  try {
    audio = decodeWav(bytes);
  } on WavFormatException catch (error) {
    return ['$path: $error'];
  }

  final formatProblems = _formatProblems(bytes, audio);
  if (formatProblems.isNotEmpty) {
    return [for (final problem in formatProblems) '$path: $problem'];
  }
  return [
    for (final problem in _contentProblems(audio, rule)) '$path: $problem',
  ];
}

List<String> _formatProblems(Uint8List bytes, Audio audio) => [
  if (audio.sampleRate != _requiredSampleRate)
    'sample rate is ${audio.sampleRate} Hz, expected $_requiredSampleRate Hz',
  if (audio.channels != 1) 'has ${audio.channels} channels, expected mono',
  if (bytes.length > _maxFileBytes)
    'is ${bytes.length ~/ 1024} KB, over ${_maxFileBytes ~/ 1024} KB',
];

List<String> _contentProblems(Audio audio, _Rule rule) {
  final samples = audio.samples;
  final duration = Duration(
    microseconds:
        samples.length * Duration.microsecondsPerSecond ~/ audio.sampleRate,
  );
  final loudness = integratedLoudness(samples, sampleRate: audio.sampleRate);
  final truePeak = peakDbfs(samples);
  final highBand = highestLevelAboveDbfs(
    samples,
    sampleRate: audio.sampleRate,
    fromHz: _highBandHz,
  );

  final loudnessText = loudness.toStringAsFixed(1);
  final peakText = truePeak.toStringAsFixed(1);
  final highBandText = highBand.toStringAsFixed(1);

  return [
    if (duration < rule.minDuration || duration > rule.maxDuration)
      'lasts ${_seconds(duration)} s, expected ${rule.lengthText}',
    if ((loudness - rule.lufs).abs() > _loudnessToleranceLu)
      'is $loudnessText LUFS, expected ${rule.lufs} ± $_loudnessToleranceLu',
    if (truePeak > _maxTruePeakDbfs)
      'peaks at $peakText dBTP, over $_maxTruePeakDbfs',
    if (highBand > _maxHighBandDbfs)
      'is piercing: $highBandText dBFS above 12 kHz, over $_maxHighBandDbfs',
    if (!_fadesIn(samples, audio.sampleRate))
      'attack is too sharp: no fade-in of 20 ms or more',
    if (!_endsQuietly(samples, audio.sampleRate))
      'ends abruptly, with a click at the end',
  ];
}

bool _fadesIn(Float64List samples, int sampleRate) {
  final overallPeak = _peakOf(samples, 0, samples.length);
  final window = _sampleCount(_attackWindow, sampleRate);
  final edge = _sampleCount(_edgeWindow, sampleRate);
  return _peakOf(samples, 0, edge) <= _maxEdgeAmplitude &&
      _peakOf(samples, 0, window) <= overallPeak * _attackPeakRatio;
}

bool _endsQuietly(Float64List samples, int sampleRate) {
  final edge = _sampleCount(_edgeWindow, sampleRate);
  return _peakOf(samples, samples.length - edge, samples.length) <=
      _maxEdgeAmplitude;
}

double _peakOf(Float64List samples, int start, int end) {
  var peak = 0.0;
  for (var i = max(0, start); i < min(end, samples.length); i++) {
    peak = max(peak, samples[i].abs());
  }
  return peak;
}

int _sampleCount(Duration duration, int sampleRate) =>
    duration.inMicroseconds * sampleRate ~/ Duration.microsecondsPerSecond;

String _seconds(Duration duration) =>
    (duration.inMilliseconds / Duration.millisecondsPerSecond).toStringAsFixed(
      2,
    );

class _Rule {
  const new({
    required this.lufs,
    required this.minDuration,
    required this.maxDuration,
    required this.lengthText,
  });

  final double lufs;
  final Duration minDuration;
  final Duration maxDuration;
  final String lengthText;
}
