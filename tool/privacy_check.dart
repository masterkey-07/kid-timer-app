// Fails when the project could send data off the device (Constitution I;
// research R20 and R22).
//
// Usage: dart run tool/privacy_check.dart [project root]
// Run it after a release APK build so the merged Android manifest is checked;
// without one, the main source manifest is checked instead.
import 'dart:io';

const _exitPassed = 0;
const _exitViolations = 1;

const _mergedManifestsDir = 'build/app/intermediates/merged_manifests/release';
const _mainManifest = 'android/app/src/main/AndroidManifest.xml';

/// The only external link allowed in Web metadata.
const _repositoryUrl = 'https://github.com/masterkey-07/kid-timer-app';

const _forbiddenAndroidPermissions = [
  'INTERNET',
  'READ_EXTERNAL_STORAGE',
  'WRITE_EXTERNAL_STORAGE',
  'MANAGE_EXTERNAL_STORAGE',
  'READ_MEDIA_IMAGES',
  'READ_MEDIA_VIDEO',
  'READ_MEDIA_AUDIO',
  'READ_MEDIA_VISUAL_USER_SELECTED',
];

final _deniedPackagePatterns = [
  RegExp('^firebase_'),
  RegExp(r'^google_mobile_ads$'),
  RegExp('analytics'),
  RegExp('^sentry'),
  RegExp('crashlytics'),
];

final _networkImport = RegExp(r'''(import|export)\s+['"]package:(http|dio)/''');
final _networkClasses = RegExp(r'\b(HttpClient|WebSocket)\b');

/// Flutter's debug tooling needs `network.server` to attach to the Dart VM
/// service; the debug entitlements never ship.
const _debugEntitlements = 'DebugProfile.entitlements';
final _networkEntitlement = RegExp(
  r'<key>com\.apple\.security\.network\.(client|server)</key>\s*<true\s*/>',
);

final _externalUrl = RegExp(r'''https?://[^\s"'<>)]+''');
final _sameOriginFontFallback = RegExp(
  r'''fontFallbackBaseUrl\s*:\s*['"](?!https?:|//)''',
);
const _localCanvasKit = '"useLocalCanvasKit":true';

final _nativeNetworkApi = RegExp(
  r'winhttp|wininet|libcurl|curl/curl\.h|libsoup',
  caseSensitive: false,
);
const _nativeSourceExtensions = ['.c', '.cc', '.cpp', '.h', '.txt', '.cmake'];

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  exitCode = runPrivacyCheck(root, stdout);
}

/// Runs every check on [root], reports to [out] and returns the exit code.
int runPrivacyCheck(Directory root, StringSink out) {
  final violations = checkPrivacy(root);
  if (violations.isEmpty) {
    out.writeln('Privacy check passed.');
    return _exitPassed;
  }
  out.writeln('Privacy check failed:');
  for (final violation in violations) {
    out.writeln('  - $violation');
  }
  return _exitViolations;
}

/// Returns one message per privacy violation found under [root].
List<String> checkPrivacy(Directory root) {
  final project = _Project(root);
  return [
    ..._checkAndroidManifest(project),
    ..._checkPubspecLock(project),
    ..._checkLibNetworking(project),
    ..._checkMacosEntitlements(project),
    ..._checkAppTransportSecurity(project),
    ..._checkWebSources(project),
    ..._checkWebBuild(project),
    ..._checkNativeRunners(project),
  ];
}

Iterable<String> _checkAndroidManifest(_Project project) sync* {
  final merged = project
      .filesUnder(_mergedManifestsDir)
      .where((file) => file.path.endsWith('AndroidManifest.xml'))
      .toList();
  final manifests = merged.isNotEmpty
      ? merged
      : [project.file(_mainManifest)].where((file) => file.existsSync());

  for (final manifest in manifests) {
    final declared = _declaredPermissions(manifest.readAsStringSync());
    for (final permission in _forbiddenAndroidPermissions) {
      if (declared.contains(permission)) {
        yield '${project.relative(manifest)}: declares '
            'android.permission.$permission';
      }
    }
  }
}

Set<String> _declaredPermissions(String manifest) {
  final elements = RegExp('<uses-permission[^>]*>').allMatches(manifest);
  return {
    for (final element in elements.map((match) => match[0]!))
      if (!element.contains('tools:node="remove"'))
        ?RegExp(r'android:name="android\.permission\.(\w+)"')
            .firstMatch(element)?[1],
  };
}

Iterable<String> _checkPubspecLock(_Project project) sync* {
  final lock = project.file('pubspec.lock');
  if (!lock.existsSync()) return;

  for (final package in _lockedPackages(lock.readAsLinesSync())) {
    if (_deniedPackagePatterns.any((pattern) => pattern.hasMatch(package))) {
      yield 'pubspec.lock: depends on denylisted package $package';
    }
  }
}

Iterable<String> _lockedPackages(List<String> lines) sync* {
  final packageLine = RegExp(r'^  ([A-Za-z0-9_]+):\s*$');
  var inPackages = false;
  for (final line in lines) {
    if (!line.startsWith(' ')) inPackages = line.startsWith('packages:');
    final match = inPackages ? packageLine.firstMatch(line) : null;
    if (match != null) yield match[1]!;
  }
}

Iterable<String> _checkLibNetworking(_Project project) sync* {
  final dartFiles = project
      .filesUnder('lib')
      .where((file) => file.path.endsWith('.dart'));
  for (final file in dartFiles) {
    final code = _stripDartComments(file.readAsStringSync());
    final path = project.relative(file);
    if (_networkImport.hasMatch(code)) {
      yield '$path: imports a networking package';
    }
    for (final match in _networkClasses.allMatches(code)) {
      yield '$path: uses ${match[1]}';
    }
  }
}

Iterable<String> _checkMacosEntitlements(_Project project) sync* {
  final entitlements = project
      .filesUnder('macos/Runner', recursive: false)
      .where((file) => file.path.endsWith('.entitlements'));
  for (final file in entitlements) {
    final isDebug = file.path.endsWith(_debugEntitlements);
    for (final match in _networkEntitlement.allMatches(
      file.readAsStringSync(),
    )) {
      final kind = match[1]!;
      if (isDebug && kind == 'server') continue;
      yield '${project.relative(file)}: allows network.$kind';
    }
  }
}

Iterable<String> _checkAppTransportSecurity(_Project project) sync* {
  for (final path in ['ios/Runner/Info.plist', 'macos/Runner/Info.plist']) {
    final plist = project.file(path);
    if (plist.existsSync() &&
        plist.readAsStringSync().contains(
          '<key>NSAppTransportSecurity</key>',
        )) {
      yield '$path: declares NSAppTransportSecurity exceptions';
    }
  }
}

Iterable<String> _checkWebSources(_Project project) sync* {
  if (!project.directory('web').existsSync()) return;

  for (final path in [
    'web/index.html',
    'web/manifest.json',
    'web/flutter_bootstrap.js',
  ]) {
    yield* _externalUrlsIn(project, path);
  }

  final bootstrap = project.file('web/flutter_bootstrap.js');
  if (!bootstrap.existsSync() ||
      !_sameOriginFontFallback.hasMatch(bootstrap.readAsStringSync())) {
    yield 'web/flutter_bootstrap.js: must set a same-origin '
        'fontFallbackBaseUrl (the engine default is fonts.gstatic.com)';
  }
}

Iterable<String> _checkWebBuild(_Project project) sync* {
  if (!project.directory('build/web').existsSync()) return;

  final bootstrapFile = project.file('build/web/flutter_bootstrap.js');
  final bootstrap = bootstrapFile.existsSync()
      ? bootstrapFile.readAsStringSync()
      : '';
  if (!bootstrap.contains(_localCanvasKit)) {
    yield 'build/web: CanvasKit loads from www.gstatic.com; '
        'build with --no-web-resources-cdn';
  }
  if (!_sameOriginFontFallback.hasMatch(bootstrap)) {
    yield 'build/web: font fallback loads from fonts.gstatic.com; '
        'set fontFallbackBaseUrl in web/flutter_bootstrap.js';
  }
  yield* _externalUrlsIn(project, 'build/web/index.html');
}

Iterable<String> _externalUrlsIn(_Project project, String path) sync* {
  final file = project.file(path);
  if (!file.existsSync()) return;

  final content = _stripMarkupComments(file.readAsStringSync());
  for (final match in _externalUrl.allMatches(content)) {
    final url = match[0]!;
    if (url.startsWith(_repositoryUrl)) continue;
    yield '$path: references external URL $url';
  }
}

Iterable<String> _checkNativeRunners(_Project project) sync* {
  final sources = [
    ...project.filesUnder('windows/runner'),
    ...project
        .filesUnder('linux')
        .where((file) => !file.path.contains('/flutter/ephemeral/')),
  ].where((file) => _isNativeSource(file.path));

  for (final file in sources) {
    final match = _nativeNetworkApi.firstMatch(file.readAsStringSync());
    if (match != null) {
      yield '${project.relative(file)}: uses networking API ${match[0]}';
    }
  }
}

bool _isNativeSource(String path) => _nativeSourceExtensions.any(path.endsWith);

String _stripDartComments(String code) => code
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'(^|\s)//.*$', multiLine: true), '');

String _stripMarkupComments(String content) => content
    .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'(^|\s)//.*$', multiLine: true), '');

/// File access relative to the project root, with `/`-separated paths.
class _Project {
  const new(this.root);

  final Directory root;

  File file(String path) => File('${root.path}/$path');

  Directory directory(String path) => Directory('${root.path}/$path');

  List<File> filesUnder(String path, {bool recursive = true}) {
    final dir = directory(path);
    if (!dir.existsSync()) return const [];
    return dir.listSync(recursive: recursive).whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  String relative(File file) => file.path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}
