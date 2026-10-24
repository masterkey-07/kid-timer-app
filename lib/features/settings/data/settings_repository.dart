import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The settings repository; bootstrap provides it over the opened box.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw StateError(
    'settingsRepositoryProvider must be overridden in bootstrap',
  ),
);

/// Stores [AppSettings] in the `settings` box under `"app"`.
final class SettingsRepository {
  /// Creates a repository over the opened `settings` box.
  new(this._box);

  static const _appKey = 'app';

  final Box<Map<dynamic, dynamic>> _box;

  /// The saved settings, or the defaults on first use.
  ///
  /// Throws a [FormatException] when the stored document is invalid.
  AppSettings load() {
    final stored = _box.get(_appKey);
    return stored == null
        ? AppSettings.initial
        : AppSettings.fromJson(toDocument(stored));
  }

  /// Writes [settings] and flushes; storage errors propagate.
  Future<void> save(AppSettings settings) async {
    await _box.put(_appKey, settings.toJson());
    await _box.flush();
  }
}
