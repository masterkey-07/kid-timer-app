import 'dart:math';
import 'dart:ui';

/// WCAG 2.2 contrast ratio between two opaque colors (1 to 21).
double contrastRatio(Color a, Color b) {
  final lighter = max(_luminance(a), _luminance(b));
  final darker = min(_luminance(a), _luminance(b));
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color color) =>
    0.2126 * _channel(color.r) +
    0.7152 * _channel(color.g) +
    0.0722 * _channel(color.b);

double _channel(double value) => value <= 0.04045
    ? value / 12.92
    : pow((value + 0.055) / 1.055, 2.4).toDouble();
