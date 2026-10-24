import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/features/images/data/image_processor_impl.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/images/domain/frame_spec.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// An own image survives closing and reopening the real storage of each
/// platform, bytes intact: files on Android and Linux, IndexedDB on the
/// Web (FR-023, contracts/persistence-schema).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const clock = Clock();
  const storageFolder = 'user_image_persist_test';
  var settings = AppSettings.initial;

  setUp(() => Hive.initFlutter(storageFolder));

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  UserImageRepository repositoryOver(PersistenceBoxes boxes) =>
      UserImageRepository(
        meta: boxes.userImagesMeta,
        bytes: boxes.userImages,
        presets: boxes.presets,
        readSettings: () => settings,
        updateSettings: (change) async => settings = change(settings),
        clock: clock,
        newId: () => 'persisted',
      );

  /// Closes everything, as killing the app would, and opens it again.
  Future<UserImageRepository> reopen() async {
    await Hive.close();
    await Hive.initFlutter(storageFolder);
    return repositoryOver(await openPersistence(clock: clock));
  }

  testWidgets('a saved image comes back with the same bytes', (tester) async {
    final photo = img.Image(width: 1600, height: 1200);
    for (final pixel in photo) {
      pixel
        ..r = pixel.x % 256
        ..g = pixel.y % 256
        ..b = 90;
    }
    final processed = (await tester.runAsync(
      () => ImageProcessorImpl().process(
        img.encodeJpg(photo),
        FrameSpec.centered,
      ),
    ))!;
    final boxes = await openPersistence(clock: clock);
    final saved = await repositoryOver(boxes).add(processed, label: 'Park');

    final reopened = await reopen();

    expect(reopened.find(saved.id), saved);
    expect(await reopened.readBytes(saved.id), processed.jpegBytes);
  });

  testWidgets('a deleted image stays deleted', (tester) async {
    final boxes = await openPersistence(clock: clock);
    final repository = repositoryOver(boxes);
    final processed = (await tester.runAsync(
      () => ImageProcessorImpl().process(
        img.encodePng(img.Image(width: 64, height: 64)),
        FrameSpec.centered,
      ),
    ))!;
    final saved = await repository.add(processed);
    await repository.delete(saved.id);

    final reopened = await reopen();

    expect(reopened.find(saved.id), isNull);
    expect(await reopened.readBytes(saved.id), isNull);
  });
}
