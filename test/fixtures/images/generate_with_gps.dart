// Regenerates with_gps.jpg: a 640×480 photo-like JPEG whose EXIF carries a
// camera make/model and a GPS position, for the metadata-removal tests.
//
// Usage: dart run test/fixtures/images/generate_with_gps.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _width = 640;
const _height = 480;
const _outputPath = 'test/fixtures/images/with_gps.jpg';

void main() {
  final image = img.Image(width: _width, height: _height);
  for (final pixel in image) {
    pixel
      ..r = pixel.x * 255 ~/ _width
      ..g = pixel.y * 255 ~/ _height
      ..b = 128;
  }

  image.exif.imageIfd
    ..['Make'] = img.IfdValueAscii('KidTimerFixtureCam')
    ..['Model'] = img.IfdValueAscii('Model 1');
  // São Paulo, roughly: 23.55° S, 46.63° W. A single rational each, since
  // the package does not export the type for degree/minute/second lists.
  image.exif.gpsIfd
    ..['GPSLatitudeRef'] = img.IfdValueAscii('S')
    ..['GPSLatitude'] = img.IfdValueRational(2355, 100)
    ..['GPSLongitudeRef'] = img.IfdValueAscii('W')
    ..['GPSLongitude'] = img.IfdValueRational(4663, 100);

  File(_outputPath).writeAsBytesSync(img.encodeJpg(image));
}
