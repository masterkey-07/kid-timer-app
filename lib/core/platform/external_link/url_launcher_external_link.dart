import 'package:url_launcher/url_launcher.dart';
import 'package:visual_time_counter/core/platform/external_link/external_link_port.dart';

/// Opens links in the system browser with `url_launcher`.
final class UrlLauncherExternalLink implements ExternalLinkPort {
  /// Creates the port.
  const new();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      // No browser, or the platform refused: the caller tells the adult.
      return false;
    }
  }
}
