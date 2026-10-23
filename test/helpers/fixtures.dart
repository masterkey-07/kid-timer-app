import 'dart:convert';
import 'dart:io';

/// Reads a JSON fixture from `test/fixtures/`.
Map<String, Object?> readJsonFixture(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync())
        as Map<String, Object?>;
