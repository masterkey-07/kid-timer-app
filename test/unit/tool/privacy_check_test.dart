import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/privacy_check.dart';

void main() {
  late Directory root;

  void write(String path, String content) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  void writeCleanProject() {
    write('android/app/src/main/AndroidManifest.xml', _manifest(''));
    write('pubspec.lock', _lock(['clock', 'hive_ce', 'http']));
    write('lib/main.dart', "import 'package:flutter/material.dart';\n");
    write('macos/Runner/Release.entitlements', _entitlements(''));
    write(
      'macos/Runner/DebugProfile.entitlements',
      _entitlements('<key>com.apple.security.network.server</key><true/>'),
    );
    write('ios/Runner/Info.plist', _plist(''));
    write('macos/Runner/Info.plist', _plist(''));
    write(
      'web/index.html',
      '<html><!-- see https://docs.flutter.dev -->'
          '<script src="flutter_bootstrap.js"></script></html>',
    );
    write('web/manifest.json', '{"start_url": "."}');
    write(
      'web/flutter_bootstrap.js',
      "{{flutter_js}}\n_flutter.loader.load({config: "
          "{fontFallbackBaseUrl: 'assets/fallback-fonts/'}});\n",
    );
    write('windows/runner/main.cpp', '#include <windows.h>\n');
    write('linux/runner/my_application.cc', '#include <gtk/gtk.h>\n');
  }

  List<String> violations() => checkPrivacy(root);

  setUp(() {
    root = Directory.systemTemp.createTempSync('privacy_');
    writeCleanProject();
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('a clean project has no violations', () {
    expect(violations(), isEmpty);
  });

  group('Android manifest', () {
    const mergedPath =
        'build/app/intermediates/merged_manifests/release/'
        'processReleaseManifest/AndroidManifest.xml';

    test('INTERNET in the merged release manifest fails', () {
      write(mergedPath, _manifest(_permission('INTERNET')));

      expect(violations(), [contains('android.permission.INTERNET')]);
    });

    test('falls back to the main manifest without a release build', () {
      write(
        'android/app/src/main/AndroidManifest.xml',
        _manifest(_permission('INTERNET')),
      );

      expect(violations(), [contains('android.permission.INTERNET')]);
    });

    test('the merged manifest takes precedence over the main one', () {
      write(
        'android/app/src/main/AndroidManifest.xml',
        _manifest(_permission('INTERNET')),
      );
      write(mergedPath, _manifest(''));

      expect(violations(), isEmpty);
    });

    for (final permission in [
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
      'MANAGE_EXTERNAL_STORAGE',
      'READ_MEDIA_IMAGES',
      'READ_MEDIA_VIDEO',
    ]) {
      test('broad storage permission $permission fails', () {
        write(mergedPath, _manifest(_permission(permission)));

        expect(violations(), [contains(permission)]);
      });
    }
  });

  group('pubspec.lock', () {
    for (final package in [
      'firebase_core',
      'google_mobile_ads',
      'unified_analytics',
      'sentry_flutter',
      'firebase_crashlytics',
    ]) {
      test('denylisted package $package fails', () {
        write('pubspec.lock', _lock(['clock', package]));

        expect(violations(), [contains(package)]);
      });
    }
  });

  group('lib/ networking', () {
    test('importing package:http fails', () {
      write('lib/a.dart', "import 'package:http/http.dart' as http;\n");

      expect(violations(), [contains('lib/a.dart')]);
    });

    test('importing package:dio fails', () {
      write('lib/a.dart', "import 'package:dio/dio.dart';\n");

      expect(violations(), [contains('lib/a.dart')]);
    });

    test('using HttpClient fails', () {
      write('lib/a.dart', 'final client = HttpClient();\n');

      expect(violations(), [contains('HttpClient')]);
    });

    test('using WebSocket fails', () {
      write('lib/a.dart', 'void f() => WebSocket.connect("x");\n');

      expect(violations(), [contains('WebSocket')]);
    });

    test('a mention inside a comment is ignored', () {
      write('lib/a.dart', '/// Never uses HttpClient or WebSocket.\n');

      expect(violations(), isEmpty);
    });
  });

  group('macOS entitlements', () {
    test('network.client in the release entitlements fails', () {
      write(
        'macos/Runner/Release.entitlements',
        _entitlements('<key>com.apple.security.network.client</key><true/>'),
      );

      expect(violations(), [contains('network.client')]);
    });

    test('network.server in the release entitlements fails', () {
      write(
        'macos/Runner/Release.entitlements',
        _entitlements('<key>com.apple.security.network.server</key><true/>'),
      );

      expect(violations(), [contains('network.server')]);
    });

    test('network.client in the debug entitlements fails', () {
      write(
        'macos/Runner/DebugProfile.entitlements',
        _entitlements('<key>com.apple.security.network.client</key><true/>'),
      );

      expect(violations(), [contains('network.client')]);
    });
  });

  test('App Transport Security exceptions fail on iOS and macOS', () {
    const ats = '<key>NSAppTransportSecurity</key><dict></dict>';
    write('ios/Runner/Info.plist', _plist(ats));
    write('macos/Runner/Info.plist', _plist(ats));

    expect(violations(), [
      contains('ios/Runner/Info.plist'),
      contains('macos/Runner/Info.plist'),
    ]);
  });

  group('web sources', () {
    test('an external script in index.html fails', () {
      write(
        'web/index.html',
        '<html><script src="https://cdn.example.com/x.js"></script></html>',
      );

      expect(violations(), [contains('cdn.example.com')]);
    });

    test('an external URL in manifest.json fails', () {
      write('web/manifest.json', '{"icons": [{"src": "https://x.io/i.png"}]}');

      expect(violations(), [contains('x.io')]);
    });

    test('the repository link is allowed', () {
      write(
        'web/manifest.json',
        '{"related": "https://github.com/masterkey-07/kid-timer-app"}',
      );

      expect(violations(), isEmpty);
    });

    test('a bootstrap without a same-origin font fallback fails', () {
      write('web/flutter_bootstrap.js', '{{flutter_js}}\n');

      expect(violations(), [contains('fontFallbackBaseUrl')]);
    });

    test('a bootstrap without a custom bootstrap file fails', () {
      File('${root.path}/web/flutter_bootstrap.js').deleteSync();

      expect(violations(), [contains('fontFallbackBaseUrl')]);
    });
  });

  group('build/web', () {
    void writeBuild({required String bootstrap}) {
      write('build/web/index.html', '<html></html>');
      write('build/web/flutter_bootstrap.js', bootstrap);
    }

    test('a build with local CanvasKit and font fallback passes', () {
      writeBuild(
        bootstrap:
            '{"useLocalCanvasKit":true} '
            "load({config: {fontFallbackBaseUrl: 'assets/fallback-fonts/'}})",
      );

      expect(violations(), isEmpty);
    });

    test('a build that loads CanvasKit from the CDN fails', () {
      writeBuild(
        bootstrap: "load({config: {fontFallbackBaseUrl: 'assets/f/'}})",
      );

      expect(violations(), [contains('gstatic.com')]);
    });

    test('a build without the font fallback override fails', () {
      writeBuild(bootstrap: '{"useLocalCanvasKit":true}');

      expect(violations(), [contains('fontFallbackBaseUrl')]);
    });

    test('an external URL in the built index.html fails', () {
      writeBuild(
        bootstrap:
            '{"useLocalCanvasKit":true} '
            "load({config: {fontFallbackBaseUrl: 'assets/f/'}})",
      );
      write(
        'build/web/index.html',
        '<link href="https://fonts.googleapis.com/css" rel="stylesheet">',
      );

      expect(violations(), [contains('fonts.googleapis.com')]);
    });
  });

  group('desktop runners', () {
    test('WinHTTP in the Windows runner fails', () {
      write('windows/runner/net.cpp', 'WinHttpOpen(L"x", 0, 0, 0, 0);\n');

      expect(violations(), [contains('windows/runner/net.cpp')]);
    });

    test('WinINet in the Windows runner fails', () {
      write('windows/runner/net.cpp', '#include <wininet.h>\n');

      expect(violations(), [contains('windows/runner/net.cpp')]);
    });

    test('libcurl in the Linux sources fails', () {
      write('linux/CMakeLists.txt', 'pkg_check_modules(CURL libcurl)\n');

      expect(violations(), [contains('linux/CMakeLists.txt')]);
    });

    test('libsoup in the Linux sources fails', () {
      write('linux/runner/net.cc', '#include <libsoup/soup.h>\n');

      expect(violations(), [contains('linux/runner/net.cc')]);
    });

    test('generated ephemeral files are ignored', () {
      write('linux/flutter/ephemeral/x.h', '#include <curl/curl.h>\n');

      expect(violations(), isEmpty);
    });
  });

  group('runPrivacyCheck', () {
    test('returns 0 for a clean project', () {
      expect(runPrivacyCheck(root, StringBuffer()), 0);
    });

    test('returns 1 and lists violations otherwise', () {
      write('lib/a.dart', "import 'package:dio/dio.dart';\n");
      final out = StringBuffer();

      expect(runPrivacyCheck(root, out), 1);
      expect(out.toString(), contains('lib/a.dart'));
    });
  });
}

String _permission(String name) =>
    '<uses-permission android:name="android.permission.$name"/>';

String _manifest(String permissions) =>
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
    '$permissions<application/></manifest>';

String _lock(List<String> packages) => [
  'packages:',
  for (final package in packages) ...[
    '  $package:',
    '    dependency: transitive',
  ],
  'sdks:',
  '  dart: ">=3.13.0 <4.0.0"',
].join('\n');

String _entitlements(String keys) =>
    '<plist version="1.0"><dict>'
    '<key>com.apple.security.app-sandbox</key><true/>$keys</dict></plist>';

String _plist(String keys) =>
    '<plist version="1.0"><dict><key>CFBundleName</key>'
    '<string>Kid Timer</string>$keys</dict></plist>';
