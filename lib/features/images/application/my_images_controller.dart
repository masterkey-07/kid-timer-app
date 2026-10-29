import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/features/images/application/decoded_image_cache.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';

/// The own-image repository over the stored boxes, changing settings
/// through [appSettingsProvider].
final userImageRepositoryProvider = Provider<UserImageRepository>((ref) {
  final storage = ref.watch(userImageStorageProvider);
  return UserImageRepository(
    meta: storage.meta,
    bytes: storage.bytes,
    presets: ref.watch(presetRepositoryProvider),
    readSettings: () => ref.read(appSettingsProvider),
    updateSettings: (change) =>
        ref.read(appSettingsProvider.notifier).update(change),
    clock: ref.watch(clockProvider),
    newId: ref.watch(userImageIdGeneratorProvider),
  );
});

/// The own images, oldest first (contracts/ui/04 §4.3).
final userImagesProvider =
    NotifierProvider<MyImagesController, List<UserImageAsset>>(
      MyImagesController.new,
    );

/// Adds, renames and deletes own images, keeping the list current.
class MyImagesController extends Notifier<List<UserImageAsset>> {
  UserImageRepository get _repository => ref.read(userImageRepositoryProvider);

  @override
  List<UserImageAsset> build() => ref.watch(userImageRepositoryProvider).list();

  /// Whether another image fits under the limit.
  bool get hasRoom => state.length < UserImageRepository.maxImages;

  /// Stores [image]; errors from the repository propagate.
  Future<UserImageAsset> add(ProcessedImage image, {String? label}) async {
    final added = await _repository.add(image, label: label);
    state = _repository.list();
    return added;
  }

  /// Gives the image [id] a new [label].
  Future<void> rename(String id, String? label) async {
    await _repository.rename(id, label);
    state = _repository.list();
  }

  /// Where the image [id] is used.
  ImageReferences referencesTo(String id) => _repository.referencesTo(id);

  /// Deletes the image [id]; what showed it switches to colors (FR-024).
  Future<void> delete(String id) async {
    await _repository.delete(id);
    ref.read(decodedImageCacheProvider).evict(id);
    ref.invalidate(presetsProvider);
    state = _repository.list();
  }
}
