import 'package:flutter/widgets.dart';
import 'package:visual_time_counter/app/theme/tokens.dart';

/// The size classes of contracts/ui/00 §3.
enum SizeClass {
  /// Narrower than 600 dp.
  compact,

  /// 600–839 dp.
  medium,

  /// 840 dp and wider.
  expanded,
}

/// How a screen of a given size is laid out (contracts/ui/00 §3).
@immutable
final class ScreenLayout {
  /// Classifies [size].
  factory of(Size size) => ScreenLayout._(
    sizeClass: size.width >= _expandedMinWidth
        ? SizeClass.expanded
        : size.width >= _mediumMinWidth
        ? SizeClass.medium
        : SizeClass.compact,
    isLandscape: size.width > size.height,
    isShort: size.height < _shortMaxHeight,
  );

  const new _({
    required this.sizeClass,
    required this.isLandscape,
    required this.isShort,
  });

  static const _mediumMinWidth = 600.0;
  static const _expandedMinWidth = 840.0;
  static const _shortMaxHeight = 480.0;
  static const _expandedPanelWidth = 360.0;
  static const _landscapePanelShare = 0.45;

  /// The width class.
  final SizeClass sizeClass;

  /// Whether the screen is wider than tall.
  final bool isLandscape;

  /// Whether the height is under 480 dp (a phone sideways).
  final bool isShort;

  /// The page margin.
  double get margin => switch (sizeClass) {
    SizeClass.compact => AppTokens.marginCompact,
    SizeClass.medium => AppTokens.marginMedium,
    SizeClass.expanded => AppTokens.marginExpanded,
  };

  /// Whether the dial and the controls sit side by side: on expanded
  /// screens, and in landscape on medium or short screens.
  bool get isSideBySide =>
      sizeClass == SizeClass.expanded ||
      (isLandscape && (sizeClass == SizeClass.medium || isShort));

  /// The controls panel width when [isSideBySide].
  double sidePanelWidth(Size size) => sizeClass == SizeClass.expanded
      ? _expandedPanelWidth
      : size.width * _landscapePanelShare;
}
