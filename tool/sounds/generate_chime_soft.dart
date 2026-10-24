// Generates assets/sounds/chime_soft.wav, the default alarm: two soft bell
// notes synthesized from a few low partials, so the file is the project's
// own work (CC0-1.0) and meets the research R6 gentleness targets by
// construction (no content above 12 kHz, 30 ms attack, faded ends).
//
// Usage: dart run tool/sounds/generate_chime_soft.dart [output path]
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 44100;
const _bitsPerSample = 16;
const _length = Duration(milliseconds: 2600);
const _attack = Duration(milliseconds: 30);
const _tailFade = Duration(milliseconds: 200);

/// Integrated loudness target (research R6: −20 LUFS ± 1).
const _targetLufs = -20.0;

/// True-peak ceiling (research R6: ≤ −3 dBTP), with 1 dB of margin.
const _peakCeilingDbfs = -4.0;

/// A bell note: when it starts, its fundamental and how fast it decays.
typedef _Note = ({Duration start, double frequency, double decayPerSecond});

const List<_Note> _notes = [
  (start: Duration.zero, frequency: 783.99, decayPerSecond: 2.2), // G5
  (start: Duration(milliseconds: 450), frequency: 659.25, decayPerSecond: 1.8),
];

/// Bell-like partials (ratio to the fundamental, relative amplitude); the
/// highest stays under 3 kHz.
const List<(double, double)> _partials = [(1, 1), (2, 0.35), (3.01, 0.12)];

void main(List<String> args) {
  final output = File(args.isEmpty ? 'assets/sounds/chime_soft.wav' : args[0]);
  final samples = _normalized(_synthesize());
  output
    ..createSync(recursive: true)
    ..writeAsBytesSync(_wav(samples));
  stdout.writeln(
    'Wrote ${output.path}: ${_length.inMilliseconds} ms, '
    'loudness ≈ ${_lufs(samples).toStringAsFixed(1)} LUFS, '
    'peak ${_dbfs(_peak(samples)).toStringAsFixed(1)} dBFS',
  );
}

Float64List _synthesize() {
  final count = _sampleCount(_length);
  final samples = Float64List(count);
  for (final note in _notes) {
    final first = _sampleCount(note.start);
    for (var i = first; i < count; i++) {
      final t = (i - first) / _sampleRate;
      final envelope = _attackGain(t) * exp(-note.decayPerSecond * t);
      for (final (ratio, amplitude) in _partials) {
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

double _attackGain(double seconds) {
  final attackSeconds = _attack.inMicroseconds / Duration.microsecondsPerSecond;
  return seconds >= attackSeconds ? 1 : seconds / attackSeconds;
}

/// Scales to the loudness target, then lowers further if the peak would
/// pass the ceiling.
Float64List _normalized(Float64List samples) {
  final loudnessGain = pow(10, (_targetLufs - _lufs(samples)) / 20).toDouble();
  final peakGain = pow(10, _peakCeilingDbfs / 20).toDouble() / _peak(samples);
  final gain = min(loudnessGain, peakGain);
  return Float64List.fromList([for (final s in samples) s * gain]);
}

/// Integrated loudness per ITU-R BS.1770 gating (400 ms blocks, 75%
/// overlap, absolute −70 and relative −10 LU gates). The partials sit
/// between 650 Hz and 2.4 kHz, where K-weighting is within ~1 dB of flat,
/// so it is omitted.
double _lufs(Float64List samples) {
  final block = _sampleCount(const Duration(milliseconds: 400));
  final hop = block ~/ 4;
  final blockPowers = <double>[
    for (var start = 0; start + block <= samples.length; start += hop)
      _meanSquare(samples, start, block),
  ];
  double loudness(double power) => -0.691 + 10 * log(power) / ln10;

  final aboveAbsolute = blockPowers.where((p) => loudness(p) > -70).toList();
  final relativeGate = loudness(_average(aboveAbsolute)) - 10;
  final gated = aboveAbsolute.where((p) => loudness(p) > relativeGate);
  return loudness(_average(gated.toList()));
}

double _meanSquare(Float64List samples, int start, int length) {
  var sum = 0.0;
  for (var i = start; i < start + length; i++) {
    sum += samples[i] * samples[i];
  }
  return sum / length;
}

double _average(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _peak(Float64List samples) =>
    samples.fold(0, (peak, s) => max(peak, s.abs()));

double _dbfs(double amplitude) => 20 * log(amplitude) / ln10;

int _sampleCount(Duration duration) =>
    duration.inMicroseconds * _sampleRate ~/ Duration.microsecondsPerSecond;

/// A canonical 44-byte-header PCM WAV, 16-bit mono.
Uint8List _wav(Float64List samples) {
  const headerBytes = 44;
  const bytesPerSample = _bitsPerSample ~/ 8;
  const maxSampleValue = 32767;
  final dataBytes = samples.length * bytesPerSample;
  final data = ByteData(headerBytes + dataBytes);

  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, headerBytes - 8 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little) // fmt chunk size
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, _sampleRate, Endian.little)
    ..setUint32(28, _sampleRate * bytesPerSample, Endian.little)
    ..setUint16(32, bytesPerSample, Endian.little)
    ..setUint16(34, _bitsPerSample, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, dataBytes, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i] * maxSampleValue).round().clamp(
      -maxSampleValue,
      maxSampleValue,
    );
    data.setInt16(headerBytes + i * bytesPerSample, value, Endian.little);
  }
  return data.buffer.asUint8List();
}
