import 'package:flutter/widgets.dart';

const _brazilianPortuguese = Locale('pt', 'BR');
const _english = Locale('en');

/// Picks the app language from the system's [preferred] locales, in order:
/// any Portuguese variant uses pt-BR, any English variant uses en, and
/// unsupported languages fall back to en (FR-061, research R13).
Locale resolveAppLocale(List<Locale>? preferred) {
  for (final locale in preferred ?? const <Locale>[]) {
    switch (locale.languageCode) {
      case 'pt':
        return _brazilianPortuguese;
      case 'en':
        return _english;
    }
  }
  return _english;
}
