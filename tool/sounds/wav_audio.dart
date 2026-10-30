// Reading, writing and measuring 16-bit PCM WAV audio, shared by the sound
// generator and `check_sounds.dart` so both agree on what "−20 LUFS" means.
import 'dart:math';
import 'dart:typed_data';

const _canonicalHeaderBytes = 44;
const _bitsPerSample = 16;
const int _bytesPerSample = _bitsPerSample ~/ 8;
const _maxSampleValue = 32767;
const _pcmFormat = 1;

/// Decoded audio, with samples in −1.0…1.0.
typedef Audio = ({int sampleRate, int channels, Float64List samples});

/// Thrown when bytes are not a WAV file this tool understands.
class WavFormatException implements Exception {
  /// Creates the exception with [message].
  const new(this.message);

  /// What is wrong with the file.
  final String message;

  @override
  String toString() => message;
}

/// Decodes a PCM 16-bit WAV; multi-channel samples stay interleaved.
///
/// Throws a [WavFormatException] for anything else.
Audio decodeWav(Uint8List bytes) {
  if (bytes.length < _canonicalHeaderBytes || _tag(bytes, 0) != 'RIFF') {
    throw const WavFormatException('not a RIFF/WAVE file');
  }
  if (_tag(bytes, 8) != 'WAVE') {
    throw const WavFormatException('not a RIFF/WAVE file');
  }
  final data = ByteData.sublistView(bytes);

  int? channels;
  int? sampleRate;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = _tag(bytes, offset);
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      final format = data.getUint16(body, Endian.little);
      final bits = data.getUint16(body + 14, Endian.little);
      if (format != _pcmFormat || bits != _bitsPerSample) {
        throw const WavFormatException('not PCM 16-bit');
      }
      channels = data.getUint16(body + 2, Endian.little);
      sampleRate = data.getUint32(body + 4, Endian.little);
    } else if (id == 'data') {
      if (channels == null || sampleRate == null) {
        throw const WavFormatException('data chunk before fmt chunk');
      }
      final available = min(size, bytes.length - body);
      final count = available ~/ _bytesPerSample;
      return (
        sampleRate: sampleRate,
        channels: channels,
        samples: Float64List.fromList([
          for (var i = 0; i < count; i++)
            data.getInt16(body + i * _bytesPerSample, Endian.little) /
                _maxSampleValue,
        ]),
      );
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  throw const WavFormatException('no data chunk');
}

/// A canonical 44-byte-header PCM WAV, 16-bit mono.
Uint8List encodeWav(Float64List samples, {required int sampleRate}) {
  final dataBytes = samples.length * _bytesPerSample;
  final data = ByteData(_canonicalHeaderBytes + dataBytes);

  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, _canonicalHeaderBytes - 8 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little) // fmt chunk size
    ..setUint16(20, _pcmFormat, Endian.little)
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * _bytesPerSample, Endian.little)
    ..setUint16(32, _bytesPerSample, Endian.little)
    ..setUint16(34, _bitsPerSample, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, dataBytes, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i] * _maxSampleValue).round().clamp(
      -_maxSampleValue,
      _maxSampleValue,
    );
    data.setInt16(
      _canonicalHeaderBytes + i * _bytesPerSample,
      value,
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

/// Integrated loudness in LUFS per ITU-R BS.1770-4: K-weighting, 400 ms
/// blocks with 75% overlap, absolute (−70 LUFS) and relative (−10 LU) gates.
/// Audio shorter than one block counts as a single block; silence is
/// negative infinity.
double integratedLoudness(Float64List samples, {required int sampleRate}) {
  final weighted = _kWeighted(samples, sampleRate);
  final block = min(sampleRate * 4 ~/ 10, weighted.length);
  final hop = max(1, block ~/ 4);
  final blockPowers = <double>[
    for (var start = 0; start + block <= weighted.length; start += hop)
      _meanSquare(weighted, start, block),
  ];

  final aboveAbsolute = blockPowers
      .where((power) => _loudness(power) > _absoluteGate)
      .toList();
  if (aboveAbsolute.isEmpty) return double.negativeInfinity;

  final relativeGate = _loudness(_average(aboveAbsolute)) - _relativeGateLu;
  final gated = aboveAbsolute
      .where((power) => _loudness(power) > relativeGate)
      .toList();
  return _loudness(_average(gated));
}

/// The sample peak in dBFS (an approximation of the true peak that is
/// within a fraction of a dB for the band-limited sounds this app ships).
double peakDbfs(Float64List samples) =>
    amplitudeToDbfs(samples.fold<double>(0, (peak, s) => max(peak, s.abs())));

/// The loudest content at or above [fromHz], in dBFS (a full-scale sine is
/// 0 dBFS), from Hann-windowed FFT frames.
double highestLevelAboveDbfs(
  Float64List samples, {
  required int sampleRate,
  required double fromHz,
}) {
  const frameSize = 4096;
  final window = [
    for (var i = 0; i < frameSize; i++)
      0.5 - 0.5 * cos(2 * pi * i / (frameSize - 1)),
  ];
  final windowSum = window.reduce((a, b) => a + b);
  final firstBin = (fromHz * frameSize / sampleRate).ceil();

  var loudest = 0.0;
  for (var start = 0; start < samples.length; start += frameSize ~/ 2) {
    final real = Float64List(frameSize);
    final imaginary = Float64List(frameSize);
    for (var i = 0; i < frameSize && start + i < samples.length; i++) {
      real[i] = samples[start + i] * window[i];
    }
    _fft(real, imaginary);
    for (var bin = firstBin; bin < frameSize ~/ 2; bin++) {
      final magnitude = sqrt(
        real[bin] * real[bin] + imaginary[bin] * imaginary[bin],
      );
      loudest = max(loudest, 2 * magnitude / windowSum);
    }
  }
  return amplitudeToDbfs(loudest);
}

/// 20·log10 of [amplitude]; negative infinity for silence.
double amplitudeToDbfs(double amplitude) =>
    amplitude <= 0 ? double.negativeInfinity : 20 * log(amplitude) / ln10;

const _absoluteGate = -70.0;
const _relativeGateLu = 10.0;

double _loudness(double meanSquare) => -0.691 + 10 * log(meanSquare) / ln10;

double _meanSquare(Float64List samples, int start, int length) {
  var sum = 0.0;
  for (var i = start; i < start + length; i++) {
    sum += samples[i] * samples[i];
  }
  return sum / length;
}

double _average(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

String _tag(Uint8List bytes, int offset) =>
    String.fromCharCodes(bytes.sublist(offset, offset + 4));

/// K-weighting: a high shelf (head acoustics) then a 38 Hz high-pass, with
/// the BS.1770 filter parameters re-derived for [sampleRate].
Float64List _kWeighted(Float64List samples, int sampleRate) {
  final shelf = _highShelf(sampleRate);
  final highPass = _highPass(sampleRate);
  return highPass.apply(shelf.apply(samples));
}

_Biquad _highShelf(int sampleRate) {
  const frequency = 1681.974450955533;
  const gainDb = 3.999843853973347;
  const q = 0.7071752369554196;
  final k = tan(pi * frequency / sampleRate);
  final vh = pow(10, gainDb / 20).toDouble();
  final vb = pow(vh, 0.4996667741545416).toDouble();
  final a0 = 1 + k / q + k * k;
  return _Biquad(
    b0: (vh + vb * k / q + k * k) / a0,
    b1: 2 * (k * k - vh) / a0,
    b2: (vh - vb * k / q + k * k) / a0,
    a1: 2 * (k * k - 1) / a0,
    a2: (1 - k / q + k * k) / a0,
  );
}

_Biquad _highPass(int sampleRate) {
  const frequency = 38.13547087602444;
  const q = 0.5003270373238773;
  final k = tan(pi * frequency / sampleRate);
  final a0 = 1 + k / q + k * k;
  return _Biquad(
    b0: 1,
    b1: -2,
    b2: 1,
    a1: 2 * (k * k - 1) / a0,
    a2: (1 - k / q + k * k) / a0,
  );
}

class _Biquad {
  const new({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  /// Filters [input] in direct form I.
  Float64List apply(Float64List input) {
    final output = Float64List(input.length);
    var x1 = 0.0;
    var x2 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < input.length; i++) {
      final x0 = input[i];
      final y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      output[i] = y0;
      x2 = x1;
      x1 = x0;
      y2 = y1;
      y1 = y0;
    }
    return output;
  }
}

/// In-place radix-2 FFT; the length must be a power of two.
void _fft(Float64List real, Float64List imaginary) {
  final n = real.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final swappedReal = real[i];
      real[i] = real[j];
      real[j] = swappedReal;
      final swappedImaginary = imaginary[i];
      imaginary[i] = imaginary[j];
      imaginary[j] = swappedImaginary;
    }
  }
  for (var length = 2; length <= n; length <<= 1) {
    final angle = -2 * pi / length;
    final stepReal = cos(angle);
    final stepImaginary = sin(angle);
    for (var start = 0; start < n; start += length) {
      var twiddleReal = 1.0;
      var twiddleImaginary = 0.0;
      for (var k = 0; k < length ~/ 2; k++) {
        final even = start + k;
        final odd = even + length ~/ 2;
        final oddReal =
            real[odd] * twiddleReal - imaginary[odd] * twiddleImaginary;
        final oddImaginary =
            real[odd] * twiddleImaginary + imaginary[odd] * twiddleReal;
        real[odd] = real[even] - oddReal;
        imaginary[odd] = imaginary[even] - oddImaginary;
        real[even] += oddReal;
        imaginary[even] += oddImaginary;
        final nextReal =
            twiddleReal * stepReal - twiddleImaginary * stepImaginary;
        twiddleImaginary =
            twiddleReal * stepImaginary + twiddleImaginary * stepReal;
        twiddleReal = nextReal;
      }
    }
  }
}
