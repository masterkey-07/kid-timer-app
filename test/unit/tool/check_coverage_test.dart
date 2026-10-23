import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/check_coverage.dart';

void main() {
  group('parseLcov', () {
    test('counts found and hit lines per file from DA records', () {
      const lcov = '''
SF:lib/core/a.dart
DA:1,1
DA:2,0
DA:3,4
end_of_record
SF:lib/app/b.dart
DA:1,0
end_of_record
''';

      final files = parseLcov(lcov);

      expect(files['lib/core/a.dart']!.linesFound, 3);
      expect(files['lib/core/a.dart']!.linesHit, 2);
      expect(files['lib/app/b.dart']!.linesFound, 1);
      expect(files['lib/app/b.dart']!.linesHit, 0);
    });

    test('normalizes absolute source paths to lib/-relative paths', () {
      const lcov = '''
SF:/home/dev/kid-timer-app/lib/core/a.dart
DA:1,1
end_of_record
''';

      expect(parseLcov(lcov).keys, ['lib/core/a.dart']);
    });

    test('normalizes Windows separators', () {
      const lcov = r'''
SF:C:\src\app\lib\core\a.dart
DA:1,1
end_of_record
''';

      expect(parseLcov(lcov).keys, ['lib/core/a.dart']);
    });
  });

  group('isExcluded', () {
    test('excludes exactly the testing-strategy list', () {
      expect(isExcluded('lib/core/domain/x.g.dart'), isTrue);
      expect(isExcluded('lib/l10n/generated/app_localizations.dart'), isTrue);
      expect(isExcluded('lib/main.dart'), isTrue);
      expect(isExcluded('lib/main_development.dart'), isTrue);
      expect(isExcluded('lib/core/platform/alarm/impl/foo.dart'), isTrue);
      expect(isExcluded('lib/core/platform/impl/foo.dart'), isTrue);
    });

    test('keeps everything else', () {
      expect(isExcluded('lib/core/domain/timer_config.dart'), isFalse);
      expect(isExcluded('lib/core/platform/alarm/alarm_scheduler.dart'), isFalse);
      expect(isExcluded('lib/app/main_menu.dart'), isFalse);
      expect(isExcluded('lib/bootstrap.dart'), isFalse);
    });
  });

  group('evaluateCoverage', () {
    Map<String, FileCoverage> files(Map<String, (int, int)> entries) => {
      for (final MapEntry(:key, :value) in entries.entries)
        key: FileCoverage(linesFound: value.$1, linesHit: value.$2),
    };

    RuleResult result(List<RuleResult> results, String name) =>
        results.singleWhere((r) => r.name == name);

    test('passes when every threshold is met', () {
      final results = evaluateCoverage(
        files({
          'lib/core/a.dart': (100, 95),
          'lib/features/timer/application/c.dart': (100, 85),
          'lib/features/timer/presentation/p.dart': (100, 60),
        }),
      );

      expect(results.every((r) => r.passed), isTrue);
    });

    test('fails lib/core below 95%', () {
      final results = evaluateCoverage(files({'lib/core/a.dart': (100, 94)}));

      expect(result(results, 'lib/core').passed, isFalse);
    });

    test('fails feature application code below 85%', () {
      final results = evaluateCoverage(
        files({
          'lib/features/timer/application/c.dart': (100, 84),
          'lib/features/timer/presentation/p.dart': (1000, 1000),
        }),
      );

      final application = result(results, 'lib/features/**/application');
      expect(application.passed, isFalse);
      expect(application.linesFound, 100);
    });

    test('fails overall below 80%', () {
      final results = evaluateCoverage(files({'lib/app/a.dart': (100, 79)}));

      expect(result(results, 'overall').passed, isFalse);
    });

    test('ignores excluded files in every rule', () {
      final results = evaluateCoverage(
        files({
          'lib/core/a.dart': (100, 100),
          'lib/core/platform/alarm/impl/x.dart': (100, 0),
          'lib/l10n/generated/l.dart': (100, 0),
        }),
      );

      expect(results.every((r) => r.passed), isTrue);
      expect(result(results, 'overall').linesFound, 100);
    });

    test('a rule without matching lines passes', () {
      final results = evaluateCoverage(files({'lib/app/a.dart': (10, 10)}));

      expect(result(results, 'lib/core').passed, isTrue);
      expect(result(results, 'lib/core').linesFound, 0);
    });
  });

  group('runCoverageCheck', () {
    late Directory tempDir;

    setUp(() => tempDir = Directory.systemTemp.createTempSync('coverage_'));
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('returns 0 and reports each rule when thresholds pass', () {
      final lcov = File('${tempDir.path}/lcov.info')
        ..writeAsStringSync('SF:lib/core/a.dart\nDA:1,1\nend_of_record\n');
      final out = StringBuffer();

      expect(runCoverageCheck(lcov.path, out), 0);
      expect(out.toString(), contains('lib/core'));
      expect(out.toString(), contains('100.0%'));
    });

    test('returns 1 when a threshold fails', () {
      final lcov = File('${tempDir.path}/lcov.info')
        ..writeAsStringSync('SF:lib/core/a.dart\nDA:1,0\nend_of_record\n');

      expect(runCoverageCheck(lcov.path, StringBuffer()), 1);
    });

    test('returns 2 when the lcov file is missing', () {
      final out = StringBuffer();

      expect(runCoverageCheck('${tempDir.path}/missing.info', out), 2);
      expect(out.toString(), contains('flutter test --coverage'));
    });
  });
}
