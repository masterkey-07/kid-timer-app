// Copies the app sounds into the native bundles, where the OS plays them for
// notifications with the app closed (contracts/ui/08 §8.3): Android
// `res/raw/<id>.wav` and the iOS/macOS `Runner/Sounds/<id>.wav` resources.
// `assets/sounds/manifest.json` is the source of truth; copies of sounds no
// longer in it are removed.
//
// Usage: dart run tool/sounds/sync_notification_sounds.dart [--check] [root]
//   --check  only reports copies that are missing or out of date (CI)
import 'dart:convert';
import 'dart:io';

const _exitPassed = 0;
const _exitProblems = 1;

const _assetsDir = 'assets/sounds';
const _manifestFile = '$_assetsDir/manifest.json';
const _soundExtension = '.wav';

/// Where each platform bundles notification sounds.
const notificationSoundDirs = [
  'android/app/src/main/res/raw',
  'ios/Runner/Sounds',
  'macos/Runner/Sounds',
];

/// Android resource names allow only lowercase letters, digits and `_`.
final _androidResourceName = RegExp(r'^[a-z][a-z0-9_]*$');

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final paths = args.where((arg) => arg != '--check');
  final root = Directory(paths.isEmpty ? '.' : paths.first);
  exitCode = runSyncNotificationSounds(root, stdout, checkOnly: checkOnly);
}

/// Runs the sync (or the check) on [root], reports to [out] and returns the
/// exit code.
int runSyncNotificationSounds(
  Directory root,
  StringSink out, {
  bool checkOnly = false,
}) {
  final problems = syncNotificationSounds(root, checkOnly: checkOnly);
  if (problems.isEmpty) {
    out.writeln(
      checkOnly
          ? 'Notification sounds are in sync.'
          : 'Notification sounds synced.',
    );
    return _exitPassed;
  }
  out.writeln('Notification sounds need attention:');
  for (final problem in problems) {
    out.writeln('  - $problem');
  }
  if (checkOnly) {
    out.writeln('Run: dart run tool/sounds/sync_notification_sounds.dart');
  }
  return _exitProblems;
}

/// Brings every bundle in line with the manifest, or with [checkOnly] just
/// lists what differs. Returns one message per problem.
List<String> syncNotificationSounds(Directory root, {bool checkOnly = false}) {
  final manifest = File('${root.path}/$_manifestFile');
  if (!manifest.existsSync()) return ['$_manifestFile: not found'];

  final ids = _readSoundIds(manifest);
  final problems = _validate(root, ids);
  if (problems.isNotEmpty) return problems;

  for (final dir in notificationSoundDirs) {
    problems.addAll(_syncDir(root, dir, ids, checkOnly: checkOnly));
  }
  return problems;
}

List<String> _readSoundIds(File manifest) {
  final json = jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
  final sounds = json['sounds'] as List<dynamic>;
  return [
    for (final sound in sounds.cast<Map<String, dynamic>>())
      sound['id'] as String,
  ];
}

List<String> _validate(Directory root, List<String> ids) => [
  for (final id in ids)
    if (!_androidResourceName.hasMatch(id))
      '$id: not a valid Android resource name (lowercase, digits, _)'
    else if (!_source(root, id).existsSync())
      '$_assetsDir/$id$_soundExtension: not found',
];

List<String> _syncDir(
  Directory root,
  String dir,
  List<String> ids, {
  required bool checkOnly,
}) {
  final problems = <String>[];
  for (final id in ids) {
    final source = _source(root, id);
    final copy = File('${root.path}/$dir/$id$_soundExtension');
    final issue = !copy.existsSync()
        ? 'missing'
        : (_sameBytes(source, copy) ? null : 'out of date');
    if (issue == null) continue;

    if (checkOnly) {
      problems.add('$dir/$id$_soundExtension: $issue');
    } else {
      copy.parent.createSync(recursive: true);
      source.copySync(copy.path);
    }
  }

  for (final stale in _staleCopies(root, dir, ids)) {
    if (checkOnly) {
      problems.add('$dir/${_fileName(stale)}: not in the manifest');
    } else {
      stale.deleteSync();
    }
  }
  return problems;
}

/// Sound files in [dir] whose id left the manifest; other resources (such
/// as Android's keep.xml) are never touched.
Iterable<File> _staleCopies(Directory root, String dir, List<String> ids) {
  final folder = Directory('${root.path}/$dir');
  if (!folder.existsSync()) return const [];
  final expected = {for (final id in ids) '$id$_soundExtension'};
  return folder
      .listSync()
      .whereType<File>()
      .where((file) => _fileName(file).endsWith(_soundExtension))
      .where((file) => !expected.contains(_fileName(file)));
}

File _source(Directory root, String id) =>
    File('${root.path}/$_assetsDir/$id$_soundExtension');

String _fileName(File file) => file.uri.pathSegments.last;

bool _sameBytes(File a, File b) {
  final first = a.readAsBytesSync();
  final second = b.readAsBytesSync();
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
