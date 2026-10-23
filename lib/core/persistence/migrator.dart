import 'package:clock/clock.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:meta/meta.dart';

/// Upgrades a document from version `n` to `n + 1`.
///
/// Receives a private copy; the migrator stamps the new `schemaVersion`.
typedef Migration = Map<String, Object?> Function(
  Map<String, Object?> document,
);

/// Applies sequential schema migrations to the documents of a box
/// (contracts/persistence-schema.md, Migrations).
///
/// A document that cannot be migrated is copied to `<box>_backup` under
/// `<key>@<timestamp>` and left untouched, so nothing is lost and a newer
/// version is never overwritten; callers fall back to defaults.
final class Migrator {
  /// Creates a migrator up to [currentVersion]; [migrations] maps each
  /// source version to the step that upgrades it.
  new({
    required this.currentVersion,
    required this._clock,
    this.migrations = const {},
  });

  static const _versionKey = 'schemaVersion';
  static const _backupSuffix = '_backup';

  /// The version documents are migrated to.
  final int currentVersion;

  /// Steps keyed by the version they upgrade from.
  final Map<int, Migration> migrations;

  final Clock _clock;

  /// Migrates every document of [box] in place.
  Future<MigrationReport> migrateBox(Box<Map<dynamic, dynamic>> box) async {
    final migratedKeys = <String>[];
    final failures = <MigrationFailure>[];

    for (final key in box.keys.toList()) {
      final stored = box.get(key)!;
      switch (_migrate(toDocument(stored))) {
        case _Unchanged():
          continue;
        case _Migrated(:final document):
          await box.put(key, document);
          migratedKeys.add('$key');
        case _Failed(:final reason, :final isDowngrade):
          final isNewBackup = await _backup(box.name, '$key', stored);
          failures.add(
            MigrationFailure(
              key: '$key',
              reason: reason,
              isDowngrade: isDowngrade,
              isNewBackup: isNewBackup,
            ),
          );
      }
    }

    if (migratedKeys.isNotEmpty) await box.flush();
    return MigrationReport(migratedKeys: migratedKeys, failures: failures);
  }

  _Outcome _migrate(Map<String, Object?> document) {
    final version = document[_versionKey];
    if (version is! int) return const _Failed('missing $_versionKey');
    if (version > currentVersion) {
      return _Failed(
        '$_versionKey $version is newer than $currentVersion',
        isDowngrade: true,
      );
    }
    if (version == currentVersion) return const _Unchanged();

    var migrated = document;
    for (var from = version; from < currentVersion; from++) {
      final migration = migrations[from];
      if (migration == null) return _Failed('no migration from v$from');
      try {
        migrated = {...migration(_deepCopy(migrated)), _versionKey: from + 1};
      } on Object catch (error) {
        return _Failed('migration from v$from failed: $error');
      }
    }
    return _Migrated(migrated);
  }

  /// Stores [document] in the backup box unless an identical backup of
  /// [key] already exists; returns whether a new backup was written.
  Future<bool> _backup(
    String boxName,
    String key,
    Map<dynamic, dynamic> document,
  ) async {
    final backups = await Hive.openBox<Map<dynamic, dynamic>>(
      '$boxName$_backupSuffix',
    );
    final alreadyBackedUp = backups.keys.any(
      (backupKey) =>
          '$backupKey'.startsWith('$key@') &&
          _deepEquals(backups.get(backupKey), document),
    );
    if (alreadyBackedUp) return false;

    await backups.put(
      '$key@${_clock.now().toUtc().toIso8601String()}',
      document,
    );
    await backups.flush();
    return true;
  }
}

/// What happened to a box during migration.
@immutable
final class MigrationReport {
  /// Creates a report.
  const new({required this.migratedKeys, required this.failures});

  /// Keys whose documents were upgraded.
  final List<String> migratedKeys;

  /// Documents that could not be migrated.
  final List<MigrationFailure> failures;

  /// Whether any document failed (the app shows a one-time notice).
  bool get hasFailures => failures.isNotEmpty;
}

/// A document that could not be migrated.
@immutable
final class MigrationFailure {
  /// Creates a failure for [key].
  const new({
    required this.key,
    required this.reason,
    required this.isDowngrade,
    required this.isNewBackup,
  });

  /// The document key.
  final String key;

  /// Why migration failed.
  final String reason;

  /// Whether the document comes from a newer app version.
  final bool isDowngrade;

  /// Whether this run wrote a new backup (false when one already existed).
  final bool isNewBackup;
}

/// Converts a map read from Hive into a JSON-style document with
/// `String` keys at every level.
Map<String, Object?> toDocument(Map<dynamic, dynamic> stored) =>
    stored.map((key, value) => MapEntry('$key', _toJsonValue(value)));

Object? _toJsonValue(Object? value) => switch (value) {
  final Map<dynamic, dynamic> map => toDocument(map),
  final List<dynamic> list => list.map(_toJsonValue).toList(),
  _ => value,
};

Map<String, Object?> _deepCopy(Map<String, Object?> document) =>
    toDocument(document);

bool _deepEquals(Object? a, Object? b) => switch ((a, b)) {
  (final Map<dynamic, dynamic> x, final Map<dynamic, dynamic> y) =>
    x.length == y.length &&
        x.keys.every(
          (key) => y.containsKey(key) && _deepEquals(x[key], y[key]),
        ),
  (final List<dynamic> x, final List<dynamic> y) =>
    x.length == y.length &&
        Iterable<int>.generate(x.length).every((i) => _deepEquals(x[i], y[i])),
  _ => a == b,
};

sealed class _Outcome {
  const new();
}

final class _Unchanged extends _Outcome {
  const new();
}

final class _Migrated extends _Outcome {
  const new(this.document);

  final Map<String, Object?> document;
}

final class _Failed extends _Outcome {
  const new(this.reason, {this.isDowngrade = false});

  final String reason;
  final bool isDowngrade;
}
