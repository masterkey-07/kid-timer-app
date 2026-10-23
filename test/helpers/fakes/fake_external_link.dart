import 'package:visual_time_counter/core/platform/external_link/external_link_port.dart';

/// Records opened links.
class FakeExternalLink implements ExternalLinkPort {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
