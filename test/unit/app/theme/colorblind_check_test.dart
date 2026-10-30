import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';

/// Machado et al. (2009) matrices at full severity, applied to linear RGB.
const Map<String, List<List<double>>> _simulations = {
  'protanopia': [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  'deuteranopia': [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ],
  'tritanopia': [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ],
};

/// The progressive phases must differ by at least this much relative
/// luminance (0–1) for the dial to read without hue (spec US14, FR-051).
const _minimumLuminanceGap = 0.2;

/// Whether the progressive palette stays readable for color vision
/// deficiency (research R9; spec US6/US14).
void main() {
  final phases = {
    'start': DialPalettes.colorAt(PaletteId.progressive, 1),
    'middle': DialPalettes.colorAt(PaletteId.progressive, 0.35),
    'end': DialPalettes.colorAt(PaletteId.progressive, 0),
  };

  for (final MapEntry(key: condition, value: matrix) in {
    'normal vision': null,
    ..._simulations,
  }.entries) {
    test('progressive phases differ in luminance for $condition', () {
      final luminances = {
        for (final MapEntry(:key, :value) in phases.entries)
          key: _luminance(matrix == null ? value : _simulate(value, matrix)),
      };

      for (final (first, second) in [
        ('start', 'middle'),
        ('middle', 'end'),
        ('start', 'end'),
      ]) {
        final gap = (luminances[first]! - luminances[second]!).abs();
        expect(
          gap,
          greaterThanOrEqualTo(_minimumLuminanceGap),
          reason: '$first vs $second: $luminances',
        );
      }
    });
  }
}

/// The color as seen with the deficiency [matrix].
Color _simulate(Color color, List<List<double>> matrix) {
  final linear = [_toLinear(color.r), _toLinear(color.g), _toLinear(color.b)];
  double channel(int row) => [
    for (var column = 0; column < 3; column++)
      matrix[row][column] * linear[column],
  ].reduce((a, b) => a + b).clamp(0.0, 1.0);
  return Color.from(
    alpha: 1,
    red: _fromLinear(channel(0)),
    green: _fromLinear(channel(1)),
    blue: _fromLinear(channel(2)),
  );
}

double _luminance(Color color) =>
    0.2126 * _toLinear(color.r) +
    0.7152 * _toLinear(color.g) +
    0.0722 * _toLinear(color.b);

double _toLinear(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _fromLinear(double channel) => channel <= 0.0031308
    ? channel * 12.92
    : 1.055 * math.pow(channel, 1 / 2.4).toDouble() - 0.055;
