import 'package:visual_time_counter/core/platform/image_picker/image_picker_port.dart';

/// Returns [nextResult] once, then null (as if cancelled).
class FakeImagePicker implements ImagePickerPort {
  PickedImage? nextResult;
  int pickCount = 0;

  @override
  Future<PickedImage?> pickImage() async {
    pickCount++;
    final result = nextResult;
    nextResult = null;
    return result;
  }
}
