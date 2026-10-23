import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/persistence/boxes.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';

/// The schema version every document box is migrated to.
const currentSchemaVersion = 1;

/// Opens every box and migrates its documents; Hive must already be
/// initialized (`Hive.initFlutter()` in the app, a temporary directory in
/// tests).
Future<PersistenceBoxes> openPersistence({required Clock clock}) async {
  final migrator = Migrator(currentVersion: currentSchemaVersion, clock: clock);
  final documentBoxes = <String, Box<Map<dynamic, dynamic>>>{};
  final failures = <BoxMigrationFailure>[];

  for (final name in BoxNames.documentBoxes) {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(name);
    final report = await migrator.migrateBox(box);
    failures.addAll(
      report.failures.map(
        (failure) => BoxMigrationFailure(box: name, failure: failure),
      ),
    );
    documentBoxes[name] = box;
  }

  return PersistenceBoxes(
    settings: documentBoxes[BoxNames.settings]!,
    presets: documentBoxes[BoxNames.presets]!,
    routines: documentBoxes[BoxNames.routines]!,
    session: documentBoxes[BoxNames.session]!,
    userImagesMeta: documentBoxes[BoxNames.userImagesMeta]!,
    userImages: await Hive.openLazyBox<Uint8List>(BoxNames.userImages),
    migrationFailures: failures,
  );
}

/// The opened boxes, handed to the repositories.
@immutable
final class PersistenceBoxes {
  /// Groups the opened boxes.
  const new({
    required this.settings,
    required this.presets,
    required this.routines,
    required this.session,
    required this.userImagesMeta,
    required this.userImages,
    required this.migrationFailures,
  });

  /// AppSettings.
  final Box<Map<dynamic, dynamic>> settings;

  /// Presets.
  final Box<Map<dynamic, dynamic>> presets;

  /// Routines (v1.x).
  final Box<Map<dynamic, dynamic>> routines;

  /// The active session.
  final Box<Map<dynamic, dynamic>> session;

  /// Own image metadata.
  final Box<Map<dynamic, dynamic>> userImagesMeta;

  /// Own image bytes.
  final LazyBox<Uint8List> userImages;

  /// Documents that could not be migrated, for the one-time notice.
  final List<BoxMigrationFailure> migrationFailures;
}

/// A migration failure and the box it happened in.
@immutable
final class BoxMigrationFailure {
  /// Creates the failure record.
  const new({required this.box, required this.failure});

  /// The box name.
  final String box;

  /// The failed document.
  final MigrationFailure failure;
}
