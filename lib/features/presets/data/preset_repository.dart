import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';
import 'package:visual_time_counter/features/presets/data/preset_seeds.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The `presets` box; bootstrap provides it.
final presetStorageProvider = Provider<Box<Map<dynamic, dynamic>>>(
  (ref) =>
      throw StateError('presetStorageProvider must be overridden in bootstrap'),
);

/// Creates the id of each new preset (a UUID); tests override it.
final presetIdGeneratorProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

/// Thrown when adding a preset beyond [PresetRepository.maxPresets].
final class PresetLimitReached implements Exception {
  /// Creates the error.
  const new();

  @override
  String toString() => 'PresetLimitReached';
}

/// Stores presets in the `presets` box, one document per id
/// (contracts/persistence-schema), keeping `order` 0..n-1 without gaps.
/// Every write is flushed before it returns; storage errors propagate.
final class PresetRepository {
  /// Creates the repository; settings are read and changed through the
  /// callbacks so the in-memory settings stay the source of truth.
  new({
    required Box<Map<dynamic, dynamic>> presets,
    required this._readSettings,
    required this._updateSettings,
    required this._clock,
    required this._newId,
  }) : _box = presets;

  /// The most presets the app keeps (FR-042).
  static const maxPresets = 100;

  final Box<Map<dynamic, dynamic>> _box;
  final AppSettings Function() _readSettings;
  final Future<void> Function(AppSettings Function(AppSettings current))
  _updateSettings;
  final Clock _clock;
  final String Function() _newId;

  /// How many presets are stored.
  int get count => _box.length;

  /// Whether another preset fits under the limit.
  bool get hasRoom => count < maxPresets;

  /// The presets in list order; unreadable documents are left out.
  List<Preset> list() =>
      _box.keys.map((key) => find('$key')).nonNulls.toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// The preset with [id], or null when there is none or it is unreadable.
  Preset? find(String id) {
    final stored = _box.get(id);
    if (stored == null) return null;
    try {
      return Preset.fromJson(toDocument(stored));
    } on FormatException catch (error) {
      debugPrint('Skipping unreadable preset $id: $error');
      return null;
    }
  }

  /// Adds a preset at the end of the list; throws [PresetLimitReached] at
  /// the limit and an [ArgumentError] for an invalid name.
  Future<Preset> create({
    required String name,
    required TimerConfig config,
    bool isExample = false,
  }) async {
    if (!hasRoom) throw const PresetLimitReached();
    final now = _now();
    final preset = Preset(
      id: _newId(),
      name: name,
      order: count,
      config: config,
      isExample: isExample,
      createdAt: now,
      updatedAt: now,
    );
    await _write([preset]);
    return preset;
  }

  /// Replaces the name and configuration of the preset [id]; returns null
  /// when it no longer exists and throws an [ArgumentError] for an invalid
  /// name.
  Future<Preset?> update(
    String id, {
    required String name,
    required TimerConfig config,
  }) async {
    final preset = find(id);
    if (preset == null) return null;
    final updated = preset.copyWith(
      name: name,
      config: config,
      updatedAt: _now(),
    );
    await _write([updated]);
    return updated;
  }

  /// Adds a copy of the preset [id] right after it, named with [suffix]
  /// (shortening the name to fit); returns null when the preset no longer
  /// exists and throws [PresetLimitReached] at the limit.
  Future<Preset?> duplicate(String id, {required String suffix}) async {
    final presets = list();
    final index = presets.indexWhere((preset) => preset.id == id);
    if (index < 0) return null;
    if (!hasRoom) throw const PresetLimitReached();

    final original = presets[index];
    final now = _now();
    final copy = Preset(
      id: _newId(),
      name: _copyName(original.name, suffix),
      order: index + 1,
      config: original.config,
      createdAt: now,
      updatedAt: now,
    );
    await _write(renumbered(presets..insert(index + 1, copy)));
    return copy;
  }

  /// Moves the preset [id] to [toIndex] (clamped to the list).
  Future<void> move(String id, int toIndex) async {
    final presets = list();
    final index = presets.indexWhere((preset) => preset.id == id);
    if (index < 0) return;
    final preset = presets.removeAt(index);
    presets.insert(toIndex.clamp(0, presets.length), preset);
    await _write(renumbered(presets));
  }

  /// Deletes the preset [id] and closes the gap; returns it for undo, or
  /// null when there was none.
  Future<Preset?> delete(String id) async {
    final preset = find(id);
    if (preset == null) return null;
    await _box.delete(id);
    await _write(renumbered(list()));
    return preset;
  }

  /// Puts a deleted [preset] back at its former position (undo).
  Future<void> restore(Preset preset) async {
    final presets = list()..removeWhere((stored) => stored.id == preset.id);
    presets.insert(preset.order.clamp(0, presets.length), preset);
    await _write(renumbered(presets));
  }

  /// Creates [seeds] as example presets on first use only (FR-042). The
  /// flag is written first: losing the examples to a later failure is
  /// harmless, seeding them twice is not.
  Future<void> seedExamples(List<PresetSeed> seeds) async {
    if (_readSettings().onboarding.examplesSeeded) return;
    await _updateSettings(
      (settings) => settings.copyWith(
        onboarding: settings.onboarding.copyWith(examplesSeeded: true),
      ),
    );
    for (final seed in seeds.take(maxPresets - count)) {
      await create(name: seed.name, config: seed.config, isExample: true);
    }
  }

  /// The names of the presets showing [visual], in list order.
  List<String> namesUsing(VisualSource visual) => [
    for (final preset in list())
      if (preset.config.visual == visual) preset.name,
  ];

  /// Makes every preset showing [from] show [to] instead.
  Future<void> replaceVisual(VisualSource from, VisualSource to) async {
    final now = _now();
    await _write([
      for (final preset in list())
        if (preset.config.visual == from)
          preset.copyWith(
            config: preset.config.copyWith(visual: to),
            updatedAt: now,
          ),
    ]);
  }

  DateTime _now() => _clock.now().toUtc();

  Future<void> _write(Iterable<Preset> presets) async {
    await _box.putAll({
      for (final preset in presets) preset.id: preset.toJson(),
    });
    await _box.flush();
  }

  static String _copyName(String name, String suffix) {
    final room = Preset.maxNameLength - Preset.nameLength(suffix) - 1;
    final runes = name.runes;
    final base = runes.length <= room
        ? name
        : String.fromCharCodes(runes.take(room)).trimRight();
    return '$base $suffix';
  }
}
