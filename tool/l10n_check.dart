// Fails when app_pt.arb and app_en.arb do not have the same message keys and
// placeholders, or when an asset manifest's localized names lack pt or en
// (Constitution V: pt-BR and en 100% translated).
//
// Usage: dart run tool/l10n_check.dart [project root]
import 'dart:convert';
import 'dart:io';

const _exitPassed = 0;
const _exitViolations = 1;

const _arbDir = 'lib/l10n';
const _locales = ['pt', 'en'];
const _assetsDir = 'assets';
const _manifestFileName = 'manifest.json';

/// Manifest fields that hold one localized text (or keyword list) per
/// language.
const _localizedFields = {'names', 'labels', 'keywords'};

/// `{name}` or `{name, plural|select, …}`; a `{` right after a word character
/// or `=` opens an ICU branch (`other{…}`, `=1{…}`), not a placeholder.
final _placeholder = RegExp(r'(?<![\w=])\{\s*([A-Za-z_]\w*)\s*[,}]');

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  exitCode = runL10nCheck(root, stdout);
}

/// Runs the check on [root], reports to [out] and returns the exit code.
int runL10nCheck(Directory root, StringSink out) {
  final violations = checkL10n(root);
  if (violations.isEmpty) {
    out.writeln('L10n check passed.');
    return _exitPassed;
  }
  out.writeln('L10n check failed:');
  for (final violation in violations) {
    out.writeln('  - $violation');
  }
  return _exitViolations;
}

/// Returns one message per key or placeholder mismatch between the ARB files
/// and per incomplete localized field in the asset manifests.
List<String> checkL10n(Directory root) => [
  ..._checkArbFiles(root),
  ..._checkAssetManifests(root),
];

List<String> _checkArbFiles(Directory root) {
  final violations = <String>[];
  final messagesByFile = <String, Map<String, String>>{};

  for (final locale in _locales) {
    final fileName = 'app_$locale.arb';
    final file = File('${root.path}/$_arbDir/$fileName');
    if (!file.existsSync()) {
      violations.add('$_arbDir/$fileName: file not found');
      continue;
    }
    messagesByFile[fileName] = _readMessages(file);
  }
  if (violations.isNotEmpty) return violations;

  final allKeys = {
    for (final messages in messagesByFile.values) ...messages.keys,
  };
  for (final key in allKeys.toList()..sort()) {
    violations.addAll(_compareKey(key, messagesByFile));
  }
  return violations;
}

Iterable<String> _compareKey(
  String key,
  Map<String, Map<String, String>> messagesByFile,
) sync* {
  final placeholdersByFile = <String, Set<String>>{};
  for (final MapEntry(key: fileName, value: messages)
      in messagesByFile.entries) {
    final message = messages[key];
    if (message == null) {
      yield '$_arbDir/$fileName: missing key "$key"';
    } else {
      placeholdersByFile[fileName] = _placeholdersOf(message);
    }
  }

  final distinct = placeholdersByFile.values.map(_describe).toSet();
  if (distinct.length > 1) {
    final details = placeholdersByFile.entries
        .map((entry) => '${entry.key} ${_describe(entry.value)}')
        .join(', ');
    yield '"$key": placeholders differ ($details)';
  }
}

Map<String, String> _readMessages(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in json.entries)
      if (!key.startsWith('@') && value is String) key: value,
  };
}

Set<String> _placeholdersOf(String message) =>
    _placeholder.allMatches(message).map((match) => match[1]!).toSet();

String _describe(Set<String> placeholders) =>
    '{${(placeholders.toList()..sort()).join(', ')}}';

Iterable<String> _checkAssetManifests(Directory root) sync* {
  final assets = Directory('${root.path}/$_assetsDir');
  if (!assets.existsSync()) return;

  final manifests =
      assets
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.uri.pathSegments.last == _manifestFileName)
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final manifest in manifests) {
    final path = manifest.path
        .substring(root.path.length + 1)
        .replaceAll(r'\', '/');
    yield* _incompleteFields(
      jsonDecode(manifest.readAsStringSync()),
      jsonPath: '',
    ).map((problem) => '$path: $problem');
  }
}

/// Walks [node] and reports each localized field missing a language.
Iterable<String> _incompleteFields(
  Object? node, {
  required String jsonPath,
}) sync* {
  switch (node) {
    case final List<Object?> list:
      for (final (index, item) in list.indexed) {
        yield* _incompleteFields(item, jsonPath: '$jsonPath[$index]');
      }
    case final Map<String, Object?> map:
      for (final MapEntry(:key, :value) in map.entries) {
        final childPath = jsonPath.isEmpty ? key : '$jsonPath.$key';
        if (_localizedFields.contains(key) && value is Map<String, Object?>) {
          for (final locale in _locales) {
            if (!_hasText(value[locale])) {
              yield '$childPath has no "$locale" text';
            }
          }
        } else {
          yield* _incompleteFields(value, jsonPath: childPath);
        }
      }
  }
}

bool _hasText(Object? value) => switch (value) {
  final String text => text.trim().isNotEmpty,
  final List<Object?> words => words.isNotEmpty,
  _ => false,
};
