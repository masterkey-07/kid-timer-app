/// Spells numbers and the gate question in words, so the question is read
/// the same way by eye and by screen reader (FR-063).
abstract final class NumberWords {
  static const _maxSpelled = 99;
  static const _firstTens = 20;
  static const _tensStep = 10;

  static const _portuguese = _Vocabulary(
    smallNumbers: [
      'zero',
      'um',
      'dois',
      'três',
      'quatro',
      'cinco',
      'seis',
      'sete',
      'oito', //
      'nove', 'dez', 'onze', 'doze', 'treze', 'catorze', 'quinze',
      'dezesseis', 'dezessete', 'dezoito', 'dezenove',
    ],
    tens: [
      'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta', //
      'oitenta', 'noventa',
    ],
    tensJoiner: ' e ',
    times: 'vezes',
  );

  static const _english = _Vocabulary(
    smallNumbers: [
      'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', //
      'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
      'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
    ],
    tens: [
      'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', //
      'ninety',
    ],
    tensJoiner: '-',
    times: 'times',
  );

  /// Spells [number] (0–99) in [languageCode]; unsupported languages read
  /// in English.
  static String spell(int number, {required String languageCode}) {
    RangeError.checkValueInInterval(number, 0, _maxSpelled, 'number');
    final vocabulary = _vocabularyFor(languageCode);
    if (number < _firstTens) return vocabulary.smallNumbers[number];

    final tens = vocabulary.tens[number ~/ _tensStep - _firstTens ~/ _tensStep];
    final unit = number % _tensStep;
    if (unit == 0) return tens;
    return '$tens${vocabulary.tensJoiner}${vocabulary.smallNumbers[unit]}';
  }

  /// The question "[left] times [right]" in words.
  static String multiplication(
    int left,
    int right, {
    required String languageCode,
  }) {
    final vocabulary = _vocabularyFor(languageCode);
    final leftWords = spell(left, languageCode: languageCode);
    final rightWords = spell(right, languageCode: languageCode);
    return '$leftWords ${vocabulary.times} $rightWords';
  }

  static _Vocabulary _vocabularyFor(String languageCode) =>
      languageCode == 'pt' ? _portuguese : _english;
}

class _Vocabulary {
  const new({
    required this.smallNumbers,
    required this.tens,
    required this.tensJoiner,
    required this.times,
  });

  /// 0–19.
  final List<String> smallNumbers;

  /// 20, 30 … 90.
  final List<String> tens;

  /// Between the tens and the unit ("vinte e um", "twenty-one").
  final String tensJoiner;

  final String times;
}
