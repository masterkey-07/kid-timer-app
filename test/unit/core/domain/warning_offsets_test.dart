import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/warning_offsets.dart';

void main() {
  test('is empty by default', () {
    expect(WarningOffsets.none.minutes, isEmpty);
  });

  test('accepts up to 2 values from {1, 2, 5, 10} minutes (FR-080)', () {
    expect(WarningOffsets({5, 1}).minutes, {1, 5});
  });

  test('rejects more than 2 values', () {
    expect(() => WarningOffsets({1, 2, 5}), throwsArgumentError);
  });

  test('rejects values outside the allowed set', () {
    expect(() => WarningOffsets({3}), throwsArgumentError);
  });

  test('ignores warnings greater than or equal to the duration', () {
    final offsets = WarningOffsets({1, 5});

    expect(offsets.effectiveFor(const Duration(minutes: 5)), [
      const Duration(minutes: 1),
    ]);
    expect(offsets.effectiveFor(const Duration(minutes: 30)), [
      const Duration(minutes: 5),
      const Duration(minutes: 1),
    ]);
  });

  test('has value equality', () {
    expect(WarningOffsets({1, 5}), WarningOffsets({5, 1}));
    expect(WarningOffsets({1, 5}).hashCode, WarningOffsets({5, 1}).hashCode);
    expect(WarningOffsets({1}), isNot(WarningOffsets({2})));
  });

  test('serializes as a sorted list of minutes', () {
    expect(WarningOffsets({5, 1}).toJson(), [1, 5]);
    expect(WarningOffsets.fromJson([5, 1]), WarningOffsets({1, 5}));
    expect(() => WarningOffsets.fromJson([7]), throwsFormatException);
    expect(() => WarningOffsets.fromJson('5'), throwsFormatException);
  });
}
