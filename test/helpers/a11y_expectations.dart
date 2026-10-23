import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

/// The largest font scale the app must support without losing content
/// (Constitution V).
const maxTextScale = 2.0;

/// Expects the current screen to meet the four accessibility guidelines that
/// every screen is tested with (testing-strategy §2 rule 6).
Future<void> expectMeetsA11yGuidelines(WidgetTester tester) async {
  final semantics = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  } finally {
    semantics.dispose();
  }
}

/// Pumps [widget] at 200% font scale and expects no layout overflow.
Future<void> expectNoOverflowAt200Percent(
  WidgetTester tester,
  Widget widget, {
  ScreenClass screen = ScreenClass.compact,
}) async {
  await tester.pumpApp(widget, screen: screen, textScale: maxTextScale);
  expect(tester.takeException(), isNull);
}
