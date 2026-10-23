// Fails when line coverage is below the Constitution IV thresholds.
//
// Usage: dart run tool/check_coverage.dart [path/to/lcov.info]
// The excluded paths are exactly the testing-strategy §2 rule 8 list.
import 'dart:io';

const _defaultLcovPath = 'coverage/lcov.info';

const _exitPassed = 0;
const _exitBelowThreshold = 1;
const _exitMissingReport = 2;

final _excludedPatterns = [
  RegExp(r'^lib/.*\.g\.dart$'),
  RegExp('^lib/l10n/generated/'),
  RegExp(r'^lib/main[^/]*\.dart$'),
  RegExp('^lib/core/platform/(.+/)?impl/'),
];

final _rules = [
  CoverageRule(
    name: 'lib/core',
    minimumPercent: 95,
    matches: (path) => path.startsWith('lib/core/'),
  ),
  CoverageRule(
    name: 'lib/features/**/application',
    minimumPercent: 85,
    matches: RegExp('^lib/features/(.+/)?application/').hasMatch,
  ),
  CoverageRule(
    name: 'overall',
    minimumPercent: 80,
    matches: (path) => path.startsWith('lib/'),
  ),
];

void main(List<String> args) {
  final lcovPath = args.isEmpty ? _defaultLcovPath : args.first;
  exitCode = runCoverageCheck(lcovPath, stdout);
}

/// Checks [lcovPath] against every rule, writes a report to [out] and
/// returns the process exit code.
int runCoverageCheck(String lcovPath, StringSink out) {
  final lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    out.writeln(
      'Coverage report not found at $lcovPath. '
      'Run `flutter test --coverage` first.',
    );
    return _exitMissingReport;
  }

  final results = evaluateCoverage(parseLcov(lcovFile.readAsStringSync()));
  for (final result in results) {
    final status = result.passed ? 'OK  ' : 'FAIL';
    out.writeln(
      '$status ${result.name}: ${result.percent.toStringAsFixed(1)}% '
      '(${result.linesHit}/${result.linesFound} lines, '
      'minimum ${result.minimumPercent}%)',
    );
  }
  return results.every((result) => result.passed)
      ? _exitPassed
      : _exitBelowThreshold;
}

/// Line counts of one source file.
class FileCoverage {
  const new({required this.linesFound, required this.linesHit});

  final int linesFound;
  final int linesHit;
}

/// A minimum coverage applied to the files whose path [matches].
class CoverageRule {
  const new({
    required this.name,
    required this.minimumPercent,
    required this.matches,
  });

  final String name;
  final double minimumPercent;
  final bool Function(String path) matches;
}

/// The outcome of one [CoverageRule].
class RuleResult {
  const new({
    required this.name,
    required this.minimumPercent,
    required this.linesFound,
    required this.linesHit,
  });

  final String name;
  final double minimumPercent;
  final int linesFound;
  final int linesHit;

  /// A rule with no matching lines counts as fully covered.
  double get percent => linesFound == 0 ? 100 : linesHit * 100 / linesFound;

  bool get passed => percent >= minimumPercent;
}

/// Parses an lcov report into per-file line counts keyed by `lib/`-relative
/// path.
Map<String, FileCoverage> parseLcov(String lcov) {
  final files = <String, FileCoverage>{};
  String? currentPath;
  var found = 0;
  var hit = 0;

  for (final line in lcov.split('\n').map((line) => line.trim())) {
    if (line.startsWith('SF:')) {
      currentPath = _normalizePath(line.substring(3));
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:') && currentPath != null) {
      found++;
      final hits = int.parse(line.substring(3).split(',')[1]);
      if (hits > 0) hit++;
    } else if (line == 'end_of_record' && currentPath != null) {
      files[currentPath] = FileCoverage(linesFound: found, linesHit: hit);
      currentPath = null;
    }
  }
  return files;
}

/// Whether [path] is outside the coverage thresholds (testing-strategy §2
/// rule 8).
bool isExcluded(String path) =>
    _excludedPatterns.any((pattern) => pattern.hasMatch(path));

/// Applies every rule to the non-excluded [files].
List<RuleResult> evaluateCoverage(Map<String, FileCoverage> files) {
  final counted = {
    for (final MapEntry(:key, :value) in files.entries)
      if (!isExcluded(key)) key: value,
  };

  return [for (final rule in _rules) _evaluateRule(rule, counted)];
}

RuleResult _evaluateRule(CoverageRule rule, Map<String, FileCoverage> files) {
  var found = 0;
  var hit = 0;
  for (final MapEntry(key: path, value: coverage) in files.entries) {
    if (!rule.matches(path)) continue;
    found += coverage.linesFound;
    hit += coverage.linesHit;
  }
  return RuleResult(
    name: rule.name,
    minimumPercent: rule.minimumPercent,
    linesFound: found,
    linesHit: hit,
  );
}

String _normalizePath(String rawPath) {
  final path = rawPath.replaceAll(r'\', '/');
  if (path.startsWith('lib/')) return path;
  final libIndex = path.lastIndexOf('/lib/');
  return libIndex == -1 ? path : path.substring(libIndex + 1);
}
