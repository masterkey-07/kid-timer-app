import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/duration_format.dart';

void main() {
  group('formatRemaining (FR-004)', () {
    final cases = <Duration, String>{
      Duration.zero: '00:00',
      const Duration(seconds: 9): '00:09',
      const Duration(minutes: 5): '05:00',
      const Duration(minutes: 59, seconds: 59): '59:59',
      const Duration(hours: 1): '1:00:00',
      const Duration(hours: 1, minutes: 5, seconds: 7): '1:05:07',
      const Duration(hours: 2): '2:00:00',
      const Duration(hours: 12): '12:00:00',
    };

    for (final MapEntry(key: duration, value: text) in cases.entries) {
      test('$duration → $text', () {
        expect(formatRemaining(duration), text);
      });
    }

    test('rounds partial seconds up so 00:00 only shows at the end', () {
      expect(formatRemaining(const Duration(milliseconds: 1)), '00:01');
      expect(
        formatRemaining(
          const Duration(minutes: 4, seconds: 59, milliseconds: 1),
        ),
        '05:00',
      );
      expect(
        formatRemaining(
          const Duration(minutes: 59, seconds: 59, milliseconds: 500),
        ),
        '1:00:00',
      );
    });

    test('shows negative durations as 00:00', () {
      expect(formatRemaining(const Duration(seconds: -3)), '00:00');
    });
  });
}
