import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  String spoken(Duration duration, [AppLocalizations? l10n]) =>
      spokenDuration(l10n ?? en, duration);

  test('says a single unit alone', () {
    expect(spoken(const Duration(minutes: 5)), '5 minutes');
    expect(spoken(const Duration(minutes: 1)), '1 minute');
    expect(spoken(const Duration(seconds: 10)), '10 seconds');
    expect(spoken(const Duration(hours: 2)), '2 hours');
  });

  test('joins the last part with "and"', () {
    expect(
      spoken(const Duration(minutes: 4, seconds: 12)),
      '4 minutes and 12 seconds',
    );
    expect(
      spoken(const Duration(hours: 1, minutes: 5, seconds: 1)),
      '1 hour, 5 minutes and 1 second',
    );
  });

  test('rounds partial seconds up, like the digits', () {
    expect(spoken(const Duration(milliseconds: 59100)), '1 minute');
  });

  test('says zero seconds when time is up', () {
    expect(spoken(Duration.zero), '0 seconds');
  });

  test('speaks Portuguese', () {
    expect(
      spoken(const Duration(minutes: 1, seconds: 30), pt),
      '1 minuto e 30 segundos',
    );
  });
}
