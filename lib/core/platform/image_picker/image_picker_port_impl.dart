import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:image_picker/image_picker.dart';
import 'package:visual_time_counter/core/platform/image_picker/image_picker_port.dart';
import 'package:visual_time_counter/core/platform/providers.dart';

/// [ImagePickerPort] over the system photo picker (`image_picker`) on
/// mobile and the Web, and the file dialog (`file_selector`) on desktops.
/// Neither asks for gallery or storage permission (FR-021).
final class ImagePickerPortImpl implements ImagePickerPort {
  /// Creates the port over `pickFile`; [ImagePickerPortImpl.forPlatform]
  /// picks the real one.
  new({required this._pickFile});

  /// The picker for [platform]; [fileTypeLabel] names the image filter in
  /// desktop file dialogs.
  factory forPlatform(AppPlatform platform, {required String fileTypeLabel}) {
    if (!usesFileDialog(platform)) {
      // Without full metadata, iOS needs no photo library permission.
      return ImagePickerPortImpl(
        pickFile: () => ImagePicker().pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        ),
      );
    }
    final images = file_selector.XTypeGroup(
      label: fileTypeLabel,
      extensions: _imageExtensions,
      mimeTypes: _imageMimeTypes,
      uniformTypeIdentifiers: const ['public.image'],
    );
    return ImagePickerPortImpl(
      pickFile: () => file_selector.openFile(acceptedTypeGroups: [images]),
    );
  }

  /// The formats `ImageProcessor` decodes.
  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
  static const _imageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/bmp',
  ];

  final Future<XFile?> Function() _pickFile;

  /// Whether [platform] picks images through a file dialog.
  static bool usesFileDialog(AppPlatform platform) => switch (platform) {
    AppPlatform.macos || AppPlatform.windows || AppPlatform.linux => true,
    AppPlatform.android || AppPlatform.ios || AppPlatform.web => false,
  };

  @override
  Future<PickedImage?> pickImage() async {
    final file = await _pickFile();
    if (file == null) return null;
    return PickedImage(
      bytes: await file.readAsBytes(),
      mimeType: file.mimeType,
      name: file.name,
    );
  }
}
