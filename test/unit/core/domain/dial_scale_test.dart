import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';

void main() {
  test('offers the 5, 10, 15, 30, 60 and 120 min scales (FR-050)', () {
    expect(DialScale.values.map((scale) => scale.span.inMinutes), [
      5,
      10,
      15,
      30,
      60,
      120,
    ]);
  });

  test('defaults to 60 min', () {
    expect(DialScale.defaultScale, DialScale.min60);
  });

  group('fractionOf', () {
    test('is remaining divided by the scale', () {
      expect(DialScale.min60.fractionOf(const Duration(minutes: 15)), 0.25);
      expect(DialScale.min15.fractionOf(const Duration(minutes: 15)), 1);
    });

    test('is clamped to [0, 1]', () {
      expect(DialScale.min5.fractionOf(const Duration(minutes: 20)), 1);
      expect(DialScale.min5.fractionOf(const Duration(seconds: -3)), 0);
    });
  });

  test('serializes by name', () {
    expect(DialScale.min30.toJson(), 'min30');
    expect(DialScale.fromJson('min30'), DialScale.min30);
    expect(() => DialScale.fromJson('min45'), throwsFormatException);
  });
}
