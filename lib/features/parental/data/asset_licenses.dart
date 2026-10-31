import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The `LICENSES.md` files of the bundled assets, listed on the licenses
/// page next to the packages' (contracts/ui/07 §7.2).
const assetLicensePaths = {
  'Images': 'assets/images/bank/LICENSES.md',
  'Sounds': 'assets/sounds/LICENSES.md',
  'Fonts': 'assets/fonts/LICENSES.md',
};

/// Adds the asset licenses read from [bundle] to the [LicenseRegistry].
void registerAssetLicenses(AssetBundle bundle) {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in assetLicensePaths.entries) {
      final text = await bundle.loadString(path);
      yield LicenseEntryWithLineBreaks(['Kid Timer assets: $name'], text);
    }
  });
}
