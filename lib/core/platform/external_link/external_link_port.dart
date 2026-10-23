/// Opens links outside the app; only called after the parental gate and a
/// confirmation (Constitution II).
abstract interface class ExternalLinkPort {
  /// Opens [uri]; returns whether it was opened.
  Future<bool> open(Uri uri);
}
