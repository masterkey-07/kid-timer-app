import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

/// Points Hive at a fresh temporary directory for each test in the enclosing
/// group and deletes it afterwards, so tests never touch the user's real
/// boxes (testing-strategy §2 rule 3).
///
/// Returns a getter for the current test's directory.
Directory Function() useTemporaryHive() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    directory.deleteSync(recursive: true);
  });

  return () => directory;
}
