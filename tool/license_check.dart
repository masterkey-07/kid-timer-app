// Fails when a bundled asset is not recorded in its folder's LICENSES.md or
// uses a license the project does not allow (Constitution IX).
//
// Usage: dart run tool/license_check.dart [project root]
import 'dart:io';

const _exitPassed = 0;
const _exitViolations = 1;

const _assetRoots = ['assets/images', 'assets/sounds', 'assets/fonts'];
const _licensesFileName = 'LICENSES.md';

/// Bookkeeping files that are not distributed assets themselves.
const Set<String> _exemptFileNames = {
  _licensesFileName,
  'manifest.json',
  '.gitkeep',
};

const _allowedLicenses = {
  'CC0-1.0',
  'CC-BY-4.0',
  'MIT',
  'Apache-2.0',
  'OFL-1.1',
};

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  exitCode = runLicenseCheck(root, stdout);
}

/// Runs the check on [root], reports to [out] and returns the exit code.
int runLicenseCheck(Directory root, StringSink out) {
  final violations = checkLicenses(root);
  if (violations.isEmpty) {
    out.writeln('License check passed.');
    return _exitPassed;
  }
  out.writeln('License check failed:');
  for (final violation in violations) {
    out.writeln('  - $violation');
  }
  return _exitViolations;
}

/// Returns one message per licensing problem found under [root].
List<String> checkLicenses(Directory root) {
  final violations = <String>[];

  for (final assetRoot in _assetRoots) {
    final dir = Directory('${root.path}/$assetRoot');
    if (!dir.existsSync()) continue;

    for (final asset in _assetFiles(dir)) {
      final assetPath = _relative(root, asset);
      final licenses = _nearestLicensesFile(asset.parent, dir);
      final entry = licenses == null
          ? null
          : _readEntries(licenses)[_relative(licenses.parent, asset)];

      if (entry == null) {
        violations.add('$assetPath: not listed in a $_licensesFileName');
        continue;
      }
      if (!_allowedLicenses.contains(entry)) {
        violations.add('$assetPath: license "$entry" is not allowed');
      }
    }

    violations.addAll(_staleEntries(root, dir));
  }
  return violations;
}

Iterable<File> _assetFiles(Directory dir) =>
    dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => !_exemptFileNames.contains(_name(file)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Entries listed in a LICENSES.md whose file does not exist.
Iterable<String> _staleEntries(Directory root, Directory assetRoot) sync* {
  final licensesFiles = assetRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => _name(file) == _licensesFileName);
  for (final licenses in licensesFiles) {
    for (final listed in _readEntries(licenses).keys) {
      if (!File('${licenses.parent.path}/$listed').existsSync()) {
        yield '${_relative(root, licenses)}: lists missing file $listed';
      }
    }
  }
}

/// Walks up from [dir] to [assetRoot] looking for a LICENSES.md.
File? _nearestLicensesFile(Directory dir, Directory assetRoot) {
  var current = dir;
  while (true) {
    final candidate = File('${current.path}/$_licensesFileName');
    if (candidate.existsSync()) return candidate;
    if (current.path == assetRoot.path) return null;
    current = current.parent;
  }
}

/// Maps each file listed in a LICENSES.md table to its license.
Map<String, String> _readEntries(File licenses) {
  final rows = licenses
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.startsWith('|'))
      .map(_cells)
      .toList();
  if (rows.isEmpty) return const {};

  final header = rows.first.map((cell) => cell.toLowerCase()).toList();
  final fileColumn = header.indexOf('file');
  final licenseColumn = header.indexOf('license');
  if (fileColumn == -1 || licenseColumn == -1) return const {};

  return {
    for (final row in rows.skip(1))
      if (!_isSeparatorRow(row) && row.length > licenseColumn)
        row[fileColumn].replaceAll('`', ''): row[licenseColumn],
  };
}

List<String> _cells(String row) {
  final cells = row.split('|').map((cell) => cell.trim()).toList();
  // Drop the empty strings before the first and after the last pipe.
  return cells.sublist(1, cells.length - 1);
}

bool _isSeparatorRow(List<String> row) =>
    row.every((cell) => RegExp(r'^:?-+:?$').hasMatch(cell));

String _name(File file) => file.uri.pathSegments.last;

String _relative(Directory base, File file) =>
    file.path.substring(base.path.length + 1).replaceAll(r'\', '/');
