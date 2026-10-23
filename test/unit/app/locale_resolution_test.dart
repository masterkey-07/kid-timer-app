import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/locale_resolution.dart';

void main() {
  const ptBr = Locale('pt', 'BR');
  const en = Locale('en');

  final cases = <String, (List<Locale>?, Locale)>{
    'pt-BR → pt-BR': ([const Locale('pt', 'BR')], ptBr),
    'pt-PT → pt-BR': ([const Locale('pt', 'PT')], ptBr),
    'pt → pt-BR': ([const Locale('pt')], ptBr),
    'en-US → en': ([const Locale('en', 'US')], en),
    'en-GB → en': ([const Locale('en', 'GB')], en),
    'fr-FR → en': ([const Locale('fr', 'FR')], en),
    'no preference → en': (null, en),
    'empty list → en': (<Locale>[], en),
    'first supported preference wins': (
      [const Locale('fr'), const Locale('pt', 'PT'), const Locale('en')],
      ptBr,
    ),
    'English before Portuguese': ([const Locale('en'), const Locale('pt')], en),
  };

  for (final MapEntry(key: name, value: (preferred, expected))
      in cases.entries) {
    test(name, () {
      expect(resolveAppLocale(preferred), expected);
    });
  }
}
