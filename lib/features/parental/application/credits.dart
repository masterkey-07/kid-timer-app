import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/parental/data/asset_licenses.dart';

/// Who made what the app ships (contracts/ui/07 §7.2).
final class Credits {
  /// Creates the credits.
  const new({required this.images, required this.soundsLicenseText});

  /// The library images with author, license and source.
  final List<BankImageAsset> images;

  /// The sounds' `LICENSES.md`; the sound manifest has no per-file credits.
  final String soundsLicenseText;
}

/// The credits, read from the bundled manifests.
final creditsProvider = FutureProvider<Credits>((ref) async {
  final images = await ref.watch(bankImagesProvider.future);
  final soundsLicenseText = await rootBundle.loadString(
    assetLicensePaths['Sounds']!,
  );
  return Credits(images: images, soundsLicenseText: soundsLicenseText);
});

/// All the assets' `LICENSES.md` joined, shown when [creditsProvider] fails.
final creditsFallbackTextProvider = FutureProvider<String>((ref) async {
  final texts = [
    for (final path in assetLicensePaths.values)
      await rootBundle.loadString(path),
  ];
  return texts.join('\n\n');
});
