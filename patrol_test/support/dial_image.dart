import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_painter.dart';

/// How long decoding an image for the dial may take on a slow emulator.
const _decodeTimeout = Duration(seconds: 10);
const _pollInterval = Duration(milliseconds: 200);

/// Waits until the dial under [dialKey] paints an image instead of colors.
Future<void> waitUntilDialShowsImage(
  PatrolIntegrationTester $,
  String dialKey,
) async {
  final deadline = DateTime.now().add(_decodeTimeout);
  while (!_dialShowsImage(dialKey)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('$dialKey still paints colors after $_decodeTimeout');
    }
    await $.pump(_pollInterval);
  }
}

bool _dialShowsImage(String dialKey) => find
    .descendant(
      of: find.byKey(Key(dialKey)),
      matching: find.byType(CustomPaint),
    )
    .evaluate()
    .map((element) => (element.widget as CustomPaint).painter)
    .whereType<DialPainter>()
    .any((painter) => painter.image != null);
