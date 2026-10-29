import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';

/// The preset repository over the stored box, changing settings through
/// [appSettingsProvider].
final presetRepositoryProvider = Provider<PresetRepository>(
  (ref) => PresetRepository(
    presets: ref.watch(presetStorageProvider),
    readSettings: () => ref.read(appSettingsProvider),
    updateSettings: (change) =>
        ref.read(appSettingsProvider.notifier).update(change),
    clock: ref.watch(clockProvider),
    newId: ref.watch(presetIdGeneratorProvider),
  ),
);

/// The presets in list order (contracts/ui/05).
final presetsProvider = NotifierProvider<PresetsController, List<Preset>>(
  PresetsController.new,
);

/// Creates, edits, reorders and deletes presets, keeping the list current.
/// Errors from the repository propagate after the list is refreshed, so
/// it always shows what storage holds.
class PresetsController extends Notifier<List<Preset>> {
  PresetRepository get _repository => ref.read(presetRepositoryProvider);

  @override
  List<Preset> build() => ref.watch(presetRepositoryProvider).list();

  /// Whether another preset fits under the limit (FR-042).
  bool get hasRoom => state.length < PresetRepository.maxPresets;

  /// The preset with [id], or null when there is none.
  Preset? find(String id) => _repository.find(id);

  /// Adds a preset at the end of the list.
  Future<Preset> create({required String name, required TimerConfig config}) =>
      _refreshAfter(() => _repository.create(name: name, config: config));

  /// Replaces the name and configuration of the preset [id].
  Future<Preset?> update(
    String id, {
    required String name,
    required TimerConfig config,
  }) => _refreshAfter(() => _repository.update(id, name: name, config: config));

  /// Adds a copy of the preset [id] right after it, named with [suffix].
  Future<Preset?> duplicate(String id, {required String suffix}) =>
      _refreshAfter(() => _repository.duplicate(id, suffix: suffix));

  /// Moves the preset [id] to [toIndex].
  Future<void> move(String id, int toIndex) =>
      _refreshAfter(() => _repository.move(id, toIndex));

  /// Deletes the preset [id]; returns it for undo.
  Future<Preset?> delete(String id) =>
      _refreshAfter(() => _repository.delete(id));

  /// Puts a deleted [preset] back where it was.
  Future<void> restore(Preset preset) =>
      _refreshAfter(() => _repository.restore(preset));

  Future<T> _refreshAfter<T>(Future<T> Function() change) async {
    try {
      return await change();
    } finally {
      state = _repository.list();
    }
  }
}
