/// What the parent area says about the app. [version] and [build] repeat
/// `pubspec.yaml`; a unit test keeps them in step.
abstract final class AppInfo {
  /// The release version.
  static const version = '1.0.0';

  /// The build number.
  static const build = '1';

  /// The project repository, the only host the app links to.
  static const sourceUrl = 'https://github.com/masterkey-07/kid-timer-app';

  /// Where problems are reported.
  static const issuesUrl = '$sourceUrl/issues/new';
}
