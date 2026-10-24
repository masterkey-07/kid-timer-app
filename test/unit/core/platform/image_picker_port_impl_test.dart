import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/image_picker/image_picker_port_impl.dart';
import 'package:visual_time_counter/core/platform/providers.dart';

void main() {
  final bytes = Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]);

  test('returns the picked file bytes, type and name', () async {
    final port = ImagePickerPortImpl(
      pickFile: () async =>
          XFile.fromData(bytes, mimeType: 'image/jpeg', name: 'park.jpg'),
    );

    final picked = await port.pickImage();

    expect(picked!.bytes, bytes);
    expect(picked.mimeType, 'image/jpeg');
    expect(picked.name, 'park.jpg');
  });

  test('returns null when the adult cancels', () async {
    final port = ImagePickerPortImpl(pickFile: () async => null);

    expect(await port.pickImage(), isNull);
  });

  test('desktops use the file dialog, the others the system photo picker', () {
    expect(
      [
        for (final platform in AppPlatform.values)
          if (ImagePickerPortImpl.usesFileDialog(platform)) platform,
      ],
      [AppPlatform.macos, AppPlatform.windows, AppPlatform.linux],
    );
  });
}
