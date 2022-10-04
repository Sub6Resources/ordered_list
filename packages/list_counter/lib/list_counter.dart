library list_counter;

/// A counter class that follows the specification outlined at
/// https://www.w3.org/TR/css-lists-3/#auto-numbering.
///
/// Essentially, the created Counter stores a value that can be incremented by
/// a given value (even negative numbers).
class Counter {
  final String name;
  int value;

  /// Initialize a new counter with a given name and value (default 0)
  Counter(this.name, [this.value = 0]);

  /// Increment the counter by a given value (default is 1)
  void increment([int byValue = 1]) {
    value += byValue;
  }

  /// Reset the counter to 0.
  void reset() {
    value = 0;
  }
}

/// The [CounterStyle] class represents styles that can be used to generate a
/// text representation of the given counter's value (such as a 'iv' for 4,
/// or 'β' for 2).
///
/// See https://www.w3.org/TR/css-counter-styles-3/#counter-styles for
/// more details.
class CounterStyle {
  /// Identifies the style
  final String name;

  /// Transforms integer counter values into a basic string representation
  final String Function(int) _algorithm;

  /// Prepended or appended to the representation of a negative counter value
  final String _negative;

  /// A prefix, to prepend to the representation
  final String _prefix;

  /// A suffix, to append to the representation
  final String _suffix;

  /// A range, which limits the values that a counter style handles
  final IntRange _range;

  /// Keeps track of pad characters and length for this CounterStyle.
  final int _padLength;
  final String _padCharacter;

  /// a fallback style, to render the representation with when the counter
  /// value is outside the counter style’s range or the counter style otherwise
  /// can’t render the counter value
  final String _fallbackStyle;

  const CounterStyle._({
    required this.name,
    required String Function(int) algorithm,
    required String negative,
    required String prefix,
    required String suffix,
    required IntRange range,
    required int padLength,
    required String padCharacter,
    required String fallbackStyle,
  })  : _algorithm = algorithm,
        _negative = negative,
        _prefix = prefix,
        _suffix = suffix,
        _range = range,
        _padLength = padLength,
        _padCharacter = padCharacter,
        _fallbackStyle = fallbackStyle;

  /// A simple way to define CounterStyle. Based off of systems defined at
  /// https://www.w3.org/TR/css-counter-styles-3/#counter-style-system
  factory CounterStyle.define({
    /// The name of the system. Not used internally, but could be used in a
    /// list of CounterStyle's to lookup a given style.
    required String name,

    /// The system type. See [System] for more details.
    System system = System.symbolic,

    /// The character to prepend to negative values.
    String negative = '-',
    // TODO add negativeSuffix

    /// A prefix to add when generating marker content
    String prefix = '',

    /// A suffix to add when generating marker content (Defaults to
    /// a full stop followed by a space: ". ").
    String suffix = '\u002E\u0020',

    /// The range of values this CounterStyle can accept. If a counter value is
    /// given outside of this range, then the CounterStyle will fall back on
    /// the CounterStyle defined by [fallback].
    ///
    /// If null, defaults to the given [System]'s range
    IntRange? range,

    /// The length each output must have at minimum, including negative symbols, but not
    /// including any suffix or prefix symbols.
    /// padLength must be greater than or equal to 0.
    int padLength = 0,

    /// The character with which to pad the output to reach the given padLength.
    /// If more than one character is given in [padCharacter], then the output
    /// will be longer than [padLength] (but never shorter).
    String padCharacter = '',

    /// The CounterStyle to fall back on if the given algorithm can't compute
    /// an output or is given out-of-range input.
    String fallback = 'decimal',

    /// The list of symbols used by this algorithm
    List<String> symbols = const [],

    /// A map of weights to symbols used by the additive algorithm
    Map<int, String> additiveSymbols = const {},

    //TODO speak-as descriptor (https://www.w3.org/TR/css-counter-styles-3/#counter-style-speak-as)
  }) {
    assert(padLength >= 0);
    assert(symbols.isNotEmpty || additiveSymbols.isNotEmpty);

    range ??= system.range;

    algorithm(int count) {
      if (!range!.withinRange(count)) {
        return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
      }

      switch (system) {
        case System.cyclic:
          assert(symbols.isNotEmpty);
          return symbols[(count - 1) % symbols.length];
        case System.fixed:
          assert(symbols.isNotEmpty);
          int firstSymbolValue =
              1; //TODO this could potentially be defined by the user (see https://www.w3.org/TR/css-counter-styles-3/#fixed-system)
          if (count >= firstSymbolValue &&
              count < firstSymbolValue + symbols.length) {
            return symbols[count - firstSymbolValue];
          } else {
            return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
          }
        case System.numeric:
          assert(symbols.length >= 2);
          int n = symbols.length;
          String result = '';

          int value = count;
          if (value == 0) {
            result = symbols[0];
            break;
          }

          while (value != 0) {
            result = '${symbols[value % n]}$result';
            value = value ~/ n;
          }

          return result;
        case System.alphabetic:
          assert(symbols.length >= 2);
          int n = symbols.length;
          String result = '';

          int value = count;
          while (value != 0) {
            value--;
            result = '${symbols[value % n]}$result';
            value = value ~/ n;
          }
          return result;
        case System.symbolic:
          int n = symbols.length;
          final representation = StringBuffer();
          for (int i = 0; i < ((count ~/ n) + 1); i++) {
            representation.write(symbols[(count - 1) % n]);
          }
          return representation.toString();
        case System.additive:
          assert(additiveSymbols.isNotEmpty);
          int value = count;
          final tuples = additiveSymbols.entries;

          if (value == 0) {
            if (additiveSymbols.containsKey(0)) {
              return additiveSymbols[0]!;
            }

            return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
          }

          final buffer = StringBuffer();
          for (var tuple in tuples) {
            final weight = tuple.key;
            final symbol = tuple.value;

            if (weight == 0 || weight > value) continue;

            final reps = value ~/ weight;
            for (int i = 0; i < reps; i++) {
              buffer.write(symbol);
            }
            value -= weight * reps;
            if (value == 0) {
              return buffer.toString();
            }
          }

          return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
      }

      return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
    }

    return CounterStyle._(
      name: name,
      algorithm: algorithm,
      negative: negative,
      prefix: prefix,
      suffix: suffix,
      range: range,
      padLength: padLength,
      padCharacter: padCharacter,
      fallbackStyle: fallback,
    );
  }

  String generateMarkerContent(int count) {
    return '$_prefix${generateCounterContent(count)}$_suffix';
  }

  String generateCounterContent(int count) {
    if (!_range.withinRange(count)) {
      return PredefinedCounterStyles.lookup(_fallbackStyle)._algorithm(count);
    }

    final initialCounterContent = _algorithm(count.abs());

    if (count < 0) {
      final padded = initialCounterContent.padLeft(
          _padLength - _negative.length, _padCharacter);
      return '$_negative$padded';
    }

    final padded = initialCounterContent.padLeft(_padLength, _padCharacter);
    return padded;
  }
}

/// A basic representation of an inclusive range of integers.
/// If min or max are null, they represent negative infinity
/// or positive infinity respectively.
class IntRange {
  final int? min;
  final int? max;

  /// Defines a range of integers. Min and max are inclusive, and default to
  /// negative and positive infinity (subject to integer size limitations),
  /// respectively, if not declared.
  const IntRange({this.min, this.max});

  /// Helper method to declare an infinite range of integers.
  /// This is equivalent to IntRange() with no arguments, but is included
  /// for clarity.
  const IntRange.infinite()
      : min = null,
        max = null;

  /// Tests whether the given value is within this range.
  bool withinRange(int value) {
    if (min != null && min! > value) {
      return false;
    }
    if (max != null && max! < value) {
      return false;
    }

    return true;
  }
}

/// Declares the predefined CounterStyle systems.
enum System {
  /// Cycles repeatedly through its provided symbols, looping back to the beginning
  /// when it reaches the end of the list.
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#cyclic-system
  cyclic(IntRange.infinite()),

  /// Interprets the list of symbols as digits to a "place-value" numbering
  /// system (i.e. first symbol represents 0, second represents 1, and so on).
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#numeric-system
  numeric(IntRange.infinite()),

  /// Runs through its list of provided symbols once, then falls back on
  /// the fallback counter style's algorithm.
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#fixed-system
  fixed(IntRange.infinite()),

  /// Interprets the the list of counter symbols as digits to an alphabetic
  /// numbering system. (e.g. a, b, c, ... z, aa, ab, ac, etc.)
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#alphabetic-system
  alphabetic(IntRange(min: 1)),

  /// Cycles repeatedly through its provided symbols, doubling, tripling, etc.
  /// the symbols on each successive pass through the list.
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#symbolic-system
  symbolic(IntRange(min: 1)),

  /// Used to represent "sign-value" numbering systems, where the value of a
  /// number is obtained by adding the digits together. (e.g. Roman numerals)
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#additive-system
  additive(IntRange(min: 0));

  /// The default range of the given [System].
  final IntRange range;

  /// Constructs a System with the given range.
  const System(this.range);
}

/// Defines a list of predefined counter-styles
/// (ref: https://www.w3.org/TR/css-counter-styles-3/#predefined-counters)
///
/// For examples of more common systems beyond what are defined here,
/// see https://www.w3.org/TR/predefined-counter-styles/
class PredefinedCounterStyles {
  /// This class isn't meant to be instantiated.
  PredefinedCounterStyles._();

  /// A map of the names of all predefined counter styles to their definition.
  static final styleMap = {
    'arabic-indic': arabicIndic,
    'armenian': armenian,
    'lower-armenian': lowerArmenian,
    'upper-armenian': upperArmenian,
    'bengali': bengali,
    'cambodian': cambodian,
    'khmer': khmer,
    'circle': circle,
    'cjk-decimal': cjkDecimal,
    'cjk-earthly-branch': cjkEarthlyBranch,
    'cjk-heavenly-stem': cjkHeavenlyStem,
    'decimal': decimal,
    'decimal-leading-zero': decimalLeadingZero,
    'devanagari': devanagari,
    'disc': disc,
    'disclosure-closed': disclosureClosed,
    'disclosure-open': disclosureOpen,
    'georgian': georgian,
    'gujarati': gujarati,
    'gurmukhi': gurmukhi,
    'hebrew': hebrew,
    'hiragana': hiragana,
    'hiragana-iroha': hiraganaIroha,
    'japanese-formal': japaneseFormal,
    'japanese-informal': japaneseInformal,
    'kannada': kannada,
    'katakana': katakana,
    'katakana-iroha': katakanaIroha,
    'korean-hangul-formal': koreanHangulFormal,
    'korean-hanja-informal': koreanHanjaInformal,
    'korean-hanja-formal': koreanHanjaFormal,
    'lao': lao,
    'lower-alpha': lowerAlpha,
    'lower-greek': lowerGreek,
    'lower-latin': lowerLatin,
    'lower-roman': lowerRoman,
    'malayalam': malayalam,
    'mongolian': mongolian,
    'myanmar': myanmar,
    'oriya': oriya,
    'persian': persian,
    'square': square,
    'tamil': tamil,
    'telugu': telugu,
    'thai': thai,
    'tibetan': tibetan,
    'upper-alpha': upperAlpha,
    'upper-latin': upperLatin,
    'upper-roman': upperRoman,
  };

  /// Lookup a predefined CounterStyle by name (used to find a fallback style)
  static CounterStyle lookup(String name) {
    return styleMap[name] ?? styleMap['decimal']!;
  }

  /// Arabic-indic numbering (e.g., ١‎, ٢‎, ٣‎, ٤‎, ..., ٩٨‎, ٩٩‎, ١٠٠‎).
  static final arabicIndic = CounterStyle.define(
    name: 'arabic-indic',
    system: System.numeric,
    symbols: const [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669'
    ],
  );

  /// Traditional uppercase Armenian numbering (e.g., Ա, Բ, Գ, ..., ՂԸ, ՂԹ, Ճ).
  static final armenian = CounterStyle.define(
    name: 'armenian',
    system: System.additive,
    range: IntRange(min: 1, max: 9999),
    additiveSymbols: {
      9000: '\u0554',
      8000: '\u0553',
      7000: '\u0552',
      6000: '\u0551',
      5000: '\u0550',
      4000: '\u054F',
      3000: '\u054E',
      2000: '\u054D',
      1000: '\u054C',
      900: '\u054B',
      800: '\u054A',
      700: '\u0549',
      600: '\u0548',
      500: '\u0547',
      400: '\u0546',
      300: '\u0545',
      200: '\u0544',
      100: '\u0543',
      90: '\u0542',
      80: '\u0541',
      70: '\u0540',
      60: '\u053F',
      50: '\u053E',
      40: '\u053D',
      30: '\u053C',
      20: '\u053B',
      10: '\u053A',
      9: '\u0539',
      8: '\u0538',
      7: '\u0537',
      6: '\u0536',
      5: '\u0535',
      4: '\u0534',
      3: '\u0533',
      2: '\u0532',
      1: '\u0531',
    },
    /* 9000 Ք, 8000 Փ, 7000 Ւ, 6000 Ց, 5000 Ր, 4000 Տ, 3000 Վ, 2000 Ս, 1000 Ռ, 900 Ջ, 800 Պ, 700 Չ, 600 Ո, 500 Շ, 400 Ն, 300 Յ, 200 Մ, 100 Ճ, 90 Ղ, 80 Ձ, 70 Հ, 60 Կ, 50 Ծ, 40 Խ, 30 Լ, 20 Ի, 10 Ժ, 9 Թ, 8 Ը, 7 Է, 6 Զ, 5 Ե, 4 Դ, 3 Գ, 2 Բ, 1 Ա */
  );

  /// Lowercase Armenian numbering (e.g., ա, բ, գ, ..., ղը, ղթ, ճ).
  static final lowerArmenian = CounterStyle.define(
    name: 'lower-armenian',
    system: System.additive,
    range: IntRange(min: 1, max: 9999),
    additiveSymbols: {
      9000: '\u0584',
      8000: '\u0583',
      7000: '\u0582',
      6000: '\u0581',
      5000: '\u0580',
      4000: '\u057F',
      3000: '\u057E',
      2000: '\u057D',
      1000: '\u057C',
      900: '\u057B',
      800: '\u057A',
      700: '\u0579',
      600: '\u0578',
      500: '\u0577',
      400: '\u0576',
      300: '\u0575',
      200: '\u0574',
      100: '\u0573',
      90: '\u0572',
      80: '\u0571',
      70: '\u0570',
      60: '\u056F',
      50: '\u056E',
      40: '\u056D',
      30: '\u056C',
      20: '\u056B',
      10: '\u056A',
      9: '\u0569',
      8: '\u0568',
      7: '\u0567',
      6: '\u0566',
      5: '\u0565',
      4: '\u0564',
      3: '\u0563',
      2: '\u0562',
      1: '\u0561',
    },
    /* 9000 ք, 8000 փ, 7000 ւ, 6000 ց, 5000 ր, 4000 տ, 3000 վ, 2000 ս, 1000 ռ, 900 ջ, 800 պ, 700 չ, 600 ո, 500 շ, 400 ն, 300 յ, 200 մ, 100 ճ, 90 ղ, 80 ձ, 70 հ, 60 կ, 50 ծ, 40 խ, 30 լ, 20 ի, 10 ժ, 9 թ, 8 ը, 7 է, 6 զ, 5 ե, 4 դ, 3 գ, 2 բ, 1 ա */
  );

  /// Traditional uppercase Armenian numbering (e.g., Ա, Բ, Գ, ..., ՂԸ, ՂԹ, Ճ).
  static final upperArmenian = CounterStyle.define(
    name: 'upper-armenian',
    system: System.additive,
    range: IntRange(min: 1, max: 9999),
    additiveSymbols: {
      9000: '\u0554',
      8000: '\u0553',
      7000: '\u0552',
      6000: '\u0551',
      5000: '\u0550',
      4000: '\u054F',
      3000: '\u054E',
      2000: '\u054D',
      1000: '\u054C',
      900: '\u054B',
      800: '\u054A',
      700: '\u0549',
      600: '\u0548',
      500: '\u0547',
      400: '\u0546',
      300: '\u0545',
      200: '\u0544',
      100: '\u0543',
      90: '\u0542',
      80: '\u0541',
      70: '\u0540',
      60: '\u053F',
      50: '\u053E',
      40: '\u053D',
      30: '\u053C',
      20: '\u053B',
      10: '\u053A',
      9: '\u0539',
      8: '\u0538',
      7: '\u0537',
      6: '\u0536',
      5: '\u0535',
      4: '\u0534',
      3: '\u0533',
      2: '\u0532',
      1: '\u0531',
    },
    /* 9000 Ք, 8000 Փ, 7000 Ւ, 6000 Ց, 5000 Ր, 4000 Տ, 3000 Վ, 2000 Ս, 1000 Ռ, 900 Ջ, 800 Պ, 700 Չ, 600 Ո, 500 Շ, 400 Ն, 300 Յ, 200 Մ, 100 Ճ, 90 Ղ, 80 Ձ, 70 Հ, 60 Կ, 50 Ծ, 40 Խ, 30 Լ, 20 Ի, 10 Ժ, 9 Թ, 8 Ը, 7 Է, 6 Զ, 5 Ե, 4 Դ, 3 Գ, 2 Բ, 1 Ա */
  );

  /// Bengali numbering (e.g., ১, ২, ৩, ..., ৯৮, ৯৯, ১০০).
  static final bengali = CounterStyle.define(
    name: 'bengali',
    system: System.numeric,
    symbols: const [
      '\u09E6',
      '\u09E7',
      '\u09E8',
      '\u09E9',
      '\u09EA',
      '\u09EB',
      '\u09EC',
      '\u09ED',
      '\u09EE',
      '\u09EF'
    ],
    /* ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯ */
  );

  /// Cambodian/Khmer numbering (e.g., ១, ២, ៣, ..., ៩៨, ៩៩, ១០០).
  static final cambodian = CounterStyle.define(
    name: 'cambodian',
    system: System.numeric,
    symbols: const [
      '\u17E0',
      '\u17E1',
      '\u17E2',
      '\u17E3',
      '\u17E4',
      '\u17E5',
      '\u17E6',
      '\u17E7',
      '\u17E8',
      '\u17E9'
    ],
    /* ០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩ */
  );

  /// Cambodian/Khmer numbering (e.g., ១, ២, ៣, ..., ៩៨, ៩៩, ១០០).
  static final khmer = CounterStyle.define(
    name: 'khmer', //Extends 'cambodian'
    system: System.numeric,
    symbols: const [
      '\u17E0',
      '\u17E1',
      '\u17E2',
      '\u17E3',
      '\u17E4',
      '\u17E5',
      '\u17E6',
      '\u17E7',
      '\u17E8',
      '\u17E9'
    ],
    /* ០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩ */
  );

  /// A hollow circle, similar to ◦ U+25E6 WHITE BULLET.
  static final circle = CounterStyle.define(
    name: 'circle',
    system: System.cyclic,
    symbols: ['\u25E6'],
    /* ◦ */
    suffix: ' ',
  );

  /// Han decimal numbers (e.g., 一, 二, 三, ..., 九八, 九九, 一〇〇).
  static final cjkDecimal = CounterStyle.define(
    name: 'cjk-decimal',
    system: System.numeric,
    symbols: const [
      '\u3007',
      '\u4E00',
      '\u4E8C',
      '\u4E09',
      '\u56DB',
      '\u4E94',
      '\u516D',
      '\u4E03',
      '\u516B',
      '\u4E5D'
    ],
    /* 〇 一 二 三 四 五 六 七 八 九 */
    suffix: '\u3001',
    /* "、" */
  );

  /// Han "Earthly Branch" ordinals (e.g., 子, 丑, 寅, ..., 亥).
  static final cjkEarthlyBranch = CounterStyle.define(
    name: 'cjk-earthly-branch',
    system: System.fixed,
    symbols: [
      '\u5B50',
      '\u4E11',
      '\u5BC5',
      '\u536F',
      '\u8FB0',
      '\u5DF3',
      '\u5348',
      '\u672A',
      '\u7533',
      '\u9149',
      '\u620C',
      '\u4EA5'
    ],
    /* 子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥 */
    suffix: '、',
  );

  /// Han "Heavenly Stem" ordinals (e.g., 甲, 乙, 丙, ..., 癸).
  static final cjkHeavenlyStem = CounterStyle.define(
    name: 'cjk-heavenly-stem',
    system: System.fixed,
    symbols: [
      '\u7532',
      '\u4E59',
      '\u4E19',
      '\u4E01',
      '\u620A',
      '\u5DF1',
      '\u5E9A',
      '\u8F9B',
      '\u58EC',
      '\u7678'
    ],
    /* 甲 乙 丙 丁 戊 己 庚 辛 壬 癸 */
    suffix: '、',
  );

  //TODO cjk-ideographic

  /// Western decimal numbers (e.g., 1, 2, 3, ..., 98, 99, 100).
  static final decimal = CounterStyle.define(
    name: 'decimal',
    system: System.numeric,
    symbols: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
  );

  /// Decimal numbers padded by initial zeros (e.g., 01, 02, 03, ..., 98, 99, 100).
  static final decimalLeadingZero = CounterStyle.define(
    name: 'decimal-leading-zero',
    system: System.numeric,
    symbols: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    padCharacter: '0',
    padLength: 2,
  );

  /// devanagari numbering (e.g., १, २, ३, ..., ९८, ९९, १००).
  static final devanagari = CounterStyle.define(
    name: 'devanagari',
    system: System.numeric,
    symbols: [
      '\u0966',
      '\u0967',
      '\u0968',
      '\u0969',
      '\u096A',
      '\u096B',
      '\u096C',
      '\u096D',
      '\u096E',
      '\u096F'
    ],
    /* ० १ २ ३ ४ ५ ६ ७ ८ ९ */
  );

  /// A filled circle, similar to • U+2022 BULLET.
  static final disc = CounterStyle.define(
    name: 'disc',
    system: System.cyclic,
    symbols: ['\u2022'],
    /* • */
    suffix: ' ',
  );

  /// U+25B8 BLACK RIGHT-POINTING SMALL TRIANGLE (▸)
  static final disclosureClosed = CounterStyle.define(
    name: 'disclosure-closed',
    system: System.cyclic,
    symbols: ['\u25B8'], //TODO for rtl use \u25C2 (◂)
    /* ▸ */
    suffix: ' ',
  );

  /// U+25BE BLACK DOWN-POINTING SMALL TRIANGLE (▾).
  static final disclosureOpen = CounterStyle.define(
    name: 'disclosure-open',
    system: System.cyclic,
    symbols: ['\u25BE'],
    /* ▾ */
    suffix: ' ',
  );

  //TODO ethiopic-numeric

  /// Traditional Georgian numbering (e.g., ა, ბ, გ, ..., ჟჱ, ჟთ, რ).
  static final georgian = CounterStyle.define(
    name: 'georgian',
    system: System.additive,
    range: IntRange(min: 1, max: 19999),
    additiveSymbols: {
      10000: '\u10F5',
      9000: '\u10F0',
      8000: '\u10EF',
      7000: '\u10F4',
      6000: '\u10EE',
      5000: '\u10ED',
      4000: '\u10EC',
      3000: '\u10EB',
      2000: '\u10EA',
      1000: '\u10E9',
      900: '\u10E8',
      800: '\u10E7',
      700: '\u10E6',
      600: '\u10E5',
      500: '\u10E4',
      400: '\u10F3',
      300: '\u10E2',
      200: '\u10E1',
      100: '\u10E0',
      90: '\u10DF',
      80: '\u10DE',
      70: '\u10DD',
      60: '\u10F2',
      50: '\u10DC',
      40: '\u10DB',
      30: '\u10DA',
      20: '\u10D9',
      10: '\u10D8',
      9: '\u10D7',
      8: '\u10F1',
      7: '\u10D6',
      6: '\u10D5',
      5: '\u10D4',
      4: '\u10D3',
      3: '\u10D2',
      2: '\u10D1',
      1: '\u10D0',
    },
    /* 10000 ჵ, 9000 ჰ, 8000 ჯ, 7000 ჴ, 6000 ხ, 5000 ჭ, 4000 წ, 3000 ძ, 2000 ც, 1000 ჩ, 900 შ, 800 ყ, 700 ღ, 600 ქ, 500 ფ, 400 ჳ, 300 ტ, 200 ს, 100 რ, 90 ჟ, 80 პ, 70 ო, 60 ჲ, 50 ნ, 40 მ, 30 ლ, 20 კ, 10 ი, 9 თ, 8 ჱ, 7 ზ, 6 ვ, 5 ე, 4 დ, 3 გ, 2 ბ, 1 ა */
  );

  /// Gujarati numbering (e.g., ૧, ૨, ૩, ..., ૯૮, ૯૯, ૧૦૦).
  static final gujarati = CounterStyle.define(
    name: 'gujarati',
    system: System.numeric,
    symbols: [
      '\u0AE6',
      '\u0AE7',
      '\u0AE8',
      '\u0AE9',
      '\u0AEA',
      '\u0AEB',
      '\u0AEC',
      '\u0AED',
      '\u0AEE',
      '\u0AEF'
    ],
    /* ૦ ૧ ૨ ૩ ૪ ૫ ૬ ૭ ૮ ૯ */
  );

  /// Gurmukhi numbering (e.g., ੧, ੨, ੩, ..., ੯੮, ੯੯, ੧੦੦).
  static final gurmukhi = CounterStyle.define(
    name: 'gurmukhi',
    system: System.numeric,
    symbols: [
      '\u0A66',
      '\u0A67',
      '\u0A68',
      '\u0A69',
      '\u0A6A',
      '\u0A6B',
      '\u0A6C',
      '\u0A6D',
      '\u0A6E',
      '\u0A6F'
    ],
    /* ੦ ੧ ੨ ੩ ੪ ੫ ੬ ੭ ੮ ੯ */
  );

  /// Traditional Hebrew numbering (e.g., א‎, ב‎, ג‎, ..., צח‎, צט‎, ק‎).
  static final hebrew = CounterStyle.define(
    name: 'hebrew',
    system: System.additive,
    range: IntRange(min: 1, max: 10999),
    additiveSymbols: {
      10000: '\u05D9\u05F3',
      9000: '\u05D8\u05F3',
      8000: '\u05D7\u05F3',
      7000: '\u05D6\u05F3',
      6000: '\u05D5\u05F3',
      5000: '\u05D4\u05F3',
      4000: '\u05D3\u05F3',
      3000: '\u05D2\u05F3',
      2000: '\u05D1\u05F3',
      1000: '\u05D0\u05F3',
      400: '\u05EA',
      300: '\u05E9',
      200: '\u05E8',
      100: '\u05E7',
      90: '\u05E6',
      80: '\u05E4',
      70: '\u05E2',
      60: '\u05E1',
      50: '\u05E0',
      40: '\u05DE',
      30: '\u05DC',
      20: '\u05DB',
      19: '\u05D9\u05D8',
      18: '\u05D9\u05D7',
      17: '\u05D9\u05D6',
      16: '\u05D8\u05D6',
      15: '\u05D8\u05D5',
      10: '\u05D9',
      9: '\u05D8',
      8: '\u05D7',
      7: '\u05D6',
      6: '\u05D5',
      5: '\u05D4',
      4: '\u05D3',
      3: '\u05D2',
      2: '\u05D1',
      1: '\u05D0',
    },
    /* 10000 י׳, 9000 ט׳, 8000 ח׳, 7000 ז׳, 6000 ו׳, 5000 ה׳, 4000 ד׳, 3000 ג׳, 2000 ב׳, 1000 א׳, 400 ת, 300 ש, 200 ר, 100 ק, 90 צ, 80 פ, 70 ע, 60 ס, 50 נ, 40 מ, 30 ל, 20 כ, 19 יט, 18 יח, 17 יז, 16 טז, 15 טו, 10 י, 9 ט, 8 ח, 7 ז, 6 ו, 5 ה, 4 ד, 3 ג, 2 ב, 1 א */
    /* This system manually specifies the values for 19-15 to force the correct display of 15 and 16, which are commonly rewritten to avoid a close resemblance to the Tetragrammaton. */
  );

  /// Dictionary-order hiragana lettering (e.g., あ, い, う, ..., ん, ああ, あい).
  static final hiragana = CounterStyle.define(
    name: 'hiragana',
    system: System.alphabetic,
    symbols: [
      '\u3042',
      '\u3044',
      '\u3046',
      '\u3048',
      '\u304A',
      '\u304B',
      '\u304D',
      '\u304F',
      '\u3051',
      '\u3053',
      '\u3055',
      '\u3057',
      '\u3059',
      '\u305B',
      '\u305D',
      '\u305F',
      '\u3061',
      '\u3064',
      '\u3066',
      '\u3068',
      '\u306A',
      '\u306B',
      '\u306C',
      '\u306D',
      '\u306E',
      '\u306F',
      '\u3072',
      '\u3075',
      '\u3078',
      '\u307B',
      '\u307E',
      '\u307F',
      '\u3080',
      '\u3081',
      '\u3082',
      '\u3084',
      '\u3086',
      '\u3088',
      '\u3089',
      '\u308A',
      '\u308B',
      '\u308C',
      '\u308D',
      '\u308F',
      '\u3090',
      '\u3091',
      '\u3092',
      '\u3093'
    ],
    /* あ い う え お か き く け こ さ し す せ そ た ち つ て と な に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ ろ わ ゐ ゑ を ん */
    suffix: '、',
  );

  /// Iroha-order hiragana lettering (e.g., い, ろ, は, ..., す, いい, いろ).
  static final hiraganaIroha = CounterStyle.define(
    name: 'hiragana-iroha',
    system: System.alphabetic,
    symbols: [
      '\u3044',
      '\u308D',
      '\u306F',
      '\u306B',
      '\u307B',
      '\u3078',
      '\u3068',
      '\u3061',
      '\u308A',
      '\u306C',
      '\u308B',
      '\u3092',
      '\u308F',
      '\u304B',
      '\u3088',
      '\u305F',
      '\u308C',
      '\u305D',
      '\u3064',
      '\u306D',
      '\u306A',
      '\u3089',
      '\u3080',
      '\u3046',
      '\u3090',
      '\u306E',
      '\u304A',
      '\u304F',
      '\u3084',
      '\u307E',
      '\u3051',
      '\u3075',
      '\u3053',
      '\u3048',
      '\u3066',
      '\u3042',
      '\u3055',
      '\u304D',
      '\u3086',
      '\u3081',
      '\u307F',
      '\u3057',
      '\u3091',
      '\u3072',
      '\u3082',
      '\u305B',
      '\u3059'
    ],
    /* い ろ は に ほ へ と ち り ぬ る を わ か よ た れ そ つ ね な ら む う ゐ の お く や ま け ふ こ え て あ さ き ゆ め み し ゑ ひ も せ す */
    suffix: '、',
  );

  /// Informal Japanese Kanji numbering (e.g., 千百十一)
  static final japaneseInformal = CounterStyle.define(
    name: 'japanese-informal',
    system: System.additive,
    range: IntRange(min: -9999, max: 9999),
    additiveSymbols: {
      9000: '\u4E5D\u5343',
      8000: '\u516B\u5343',
      7000: '\u4E03\u5343',
      6000: '\u516D\u5343',
      5000: '\u4E94\u5343',
      4000: '\u56DB\u5343',
      3000: '\u4E09\u5343',
      2000: '\u4E8C\u5343',
      1000: '\u5343',
      900: '\u4E5D\u767E',
      800: '\u516B\u767E',
      700: '\u4E03\u767E',
      600: '\u516D\u767E',
      500: '\u4E94\u767E',
      400: '\u56DB\u767E',
      300: '\u4E09\u767E',
      200: '\u4E8C\u767E',
      100: '\u767E',
      90: '\u4E5D\u5341',
      80: '\u516B\u5341',
      70: '\u4E03\u5341',
      60: '\u516D\u5341',
      50: '\u4E94\u5341',
      40: '\u56DB\u5341',
      30: '\u4E09\u5341',
      20: '\u4E8C\u5341',
      10: '\u5341',
      9: '\u4E5D',
      8: '\u516B',
      7: '\u4E03',
      6: '\u516D',
      5: '\u4E94',
      4: '\u56DB',
      3: '\u4E09',
      2: '\u4E8C',
      1: '\u4E00',
      0: '\u3007',
    },
    /* 9000 九千, 8000 八千, 7000 七千, 6000 六千, 5000 五千, 4000 四千, 3000 三千, 2000 二千, 1000 千, 900 九百, 800 八百, 700 七百, 600 六百, 500 五百, 400 四百, 300 三百, 200 二百, 100 百, 90 九十, 80 八十, 70 七十, 60 六十, 50 五十, 40 四十, 30 三十, 20 二十, 10 十, 9 九, 8 八, 7 七, 6 六, 5 五, 4 四, 3 三, 2 二, 1 一, 0 〇 */
    suffix: '\u3001',
    /* 、 */
    negative: '\u30DE\u30A4\u30CA\u30B9',
    /* マイナス */
    fallback: 'cjk-decimal',
  );

  /// Formal Japanese Kanji numbering (e.g. 壱阡壱百壱拾壱)
  static final japaneseFormal = CounterStyle.define(
    name: 'japanese-formal',
    system: System.additive,
    range: IntRange(min: -9999, max: 9999),
    additiveSymbols: {
      9000: '\u4E5D\u9621',
      8000: '\u516B\u9621',
      7000: '\u4E03\u9621',
      6000: '\u516D\u9621',
      5000: '\u4F0D\u9621',
      4000: '\u56DB\u9621',
      3000: '\u53C2\u9621',
      2000: '\u5F10\u9621',
      1000: '\u58F1\u9621',
      900: '\u4E5D\u767E',
      800: '\u516B\u767E',
      700: '\u4E03\u767E',
      600: '\u516D\u767E',
      500: '\u4F0D\u767E',
      400: '\u56DB\u767E',
      300: '\u53C2\u767E',
      200: '\u5F10\u767E',
      100: '\u58F1\u767E',
      90: '\u4E5D\u62FE',
      80: '\u516B\u62FE',
      70: '\u4E03\u62FE',
      60: '\u516D\u62FE',
      50: '\u4F0D\u62FE',
      40: '\u56DB\u62FE',
      30: '\u53C2\u62FE',
      20: '\u5F10\u62FE',
      10: '\u58F1\u62FE',
      9: '\u4E5D',
      8: '\u516B',
      7: '\u4E03',
      6: '\u516D',
      5: '\u4F0D',
      4: '\u56DB',
      3: '\u53C2',
      2: '\u5F10',
      1: '\u58F1',
      0: '\u96F6',
    },
    /* 9000 九阡, 8000 八阡, 7000 七阡, 6000 六阡, 5000 伍阡, 4000 四阡, 3000 参阡, 2000 弐阡, 1000 壱阡, 900 九百, 800 八百, 700 七百, 600 六百, 500 伍百, 400 四百, 300 参百, 200 弐百, 100 壱百, 90 九拾, 80 八拾, 70 七拾, 60 六拾, 50 伍拾, 40 四拾, 30 参拾, 20 弐拾, 10 壱拾, 9 九, 8 八, 7 七, 6 六, 5 伍, 4 四, 3 参, 2 弐, 1 壱, 0 零 */
    suffix: '\u3001',
    /* 、 */
    negative: '\u30DE\u30A4\u30CA\u30B9',
    /* マイナス */
    fallback: 'cjk-decimal',
  );

  /// Kannada numbering (e.g., ೧, ೨, ೩, ..., ೯೮, ೯೯, ೧೦೦).
  static final kannada = CounterStyle.define(
    name: 'kannada',
    system: System.numeric,
    symbols: [
      '\u0CE6',
      '\u0CE7',
      '\u0CE8',
      '\u0CE9',
      '\u0CEA',
      '\u0CEB',
      '\u0CEC',
      '\u0CED',
      '\u0CEE',
      '\u0CEF'
    ],
    /* ೦ ೧ ೨ ೩ ೪ ೫ ೬ ೭ ೮ ೯ */
  );

  /// Dictionary-order katakana lettering (e.g., ア, イ, ウ, ..., ン, アア, アイ).
  static final katakana = CounterStyle.define(
    name: 'katakana',
    system: System.alphabetic,
    symbols: [
      '\u30A2',
      '\u30A4',
      '\u30A6',
      '\u30A8',
      '\u30AA',
      '\u30AB',
      '\u30AD',
      '\u30AF',
      '\u30B1',
      '\u30B3',
      '\u30B5',
      '\u30B7',
      '\u30B9',
      '\u30BB',
      '\u30BD',
      '\u30BF',
      '\u30C1',
      '\u30C4',
      '\u30C6',
      '\u30C8',
      '\u30CA',
      '\u30CB',
      '\u30CC',
      '\u30CD',
      '\u30CE',
      '\u30CF',
      '\u30D2',
      '\u30D5',
      '\u30D8',
      '\u30DB',
      '\u30DE',
      '\u30DF',
      '\u30E0',
      '\u30E1',
      '\u30E2',
      '\u30E4',
      '\u30E6',
      '\u30E8',
      '\u30E9',
      '\u30EA',
      '\u30EB',
      '\u30EC',
      '\u30ED',
      '\u30EF',
      '\u30F0',
      '\u30F1',
      '\u30F2',
      '\u30F3'
    ],
    /* ア イ ウ エ オ カ キ ク ケ コ サ シ ス セ ソ タ チ ツ テ ト ナ ニ ヌ ネ ノ ハ ヒ フ ヘ ホ マ ミ ム メ モ ヤ ユ ヨ ラ リ ル レ ロ ワ ヰ ヱ ヲ ン */
    suffix: '、',
  );

  /// Iroha-order katakana lettering (e.g., イ, ロ, ハ, ..., ス, イイ, イロ)
  static final katakanaIroha = CounterStyle.define(
    name: 'katakana-iroha',
    system: System.alphabetic,
    symbols: [
      '\u30A4',
      '\u30ED',
      '\u30CF',
      '\u30CB',
      '\u30DB',
      '\u30D8',
      '\u30C8',
      '\u30C1',
      '\u30EA',
      '\u30CC',
      '\u30EB',
      '\u30F2',
      '\u30EF',
      '\u30AB',
      '\u30E8',
      '\u30BF',
      '\u30EC',
      '\u30BD',
      '\u30C4',
      '\u30CD',
      '\u30CA',
      '\u30E9',
      '\u30E0',
      '\u30A6',
      '\u30F0',
      '\u30CE',
      '\u30AA',
      '\u30AF',
      '\u30E4',
      '\u30DE',
      '\u30B1',
      '\u30D5',
      '\u30B3',
      '\u30A8',
      '\u30C6',
      '\u30A2',
      '\u30B5',
      '\u30AD',
      '\u30E6',
      '\u30E1',
      '\u30DF',
      '\u30B7',
      '\u30F1',
      '\u30D2',
      '\u30E2',
      '\u30BB',
      '\u30B9'
    ],
    /* イ ロ ハ ニ ホ ヘ ト チ リ ヌ ル ヲ ワ カ ヨ タ レ ソ ツ ネ ナ ラ ム ウ ヰ ノ オ ク ヤ マ ケ フ コ エ テ ア サ キ ユ メ ミ シ ヱ ヒ モ セ ス */
    suffix: '、',
  );

  /// Korean Hangul numbering (e.g., 일천일백일십일)
  static final koreanHangulFormal = CounterStyle.define(
    name: 'korean-hangul-formal',
    system: System.additive,
    range: IntRange(min: -9999, max: 9999),
    additiveSymbols: {
      9000: '\uAD6C\uCC9C',
      8000: '\uD314\uCC9C',
      7000: '\uCE60\uCC9C',
      6000: '\uC721\uCC9C',
      5000: '\uC624\uCC9C',
      4000: '\uC0AC\uCC9C',
      3000: '\uC0BC\uCC9C',
      2000: '\uC774\uCC9C',
      1000: '\uC77C\uCC9C',
      900: '\uAD6C\uBC31',
      800: '\uD314\uBC31',
      700: '\uCE60\uBC31',
      600: '\uC721\uBC31',
      500: '\uC624\uBC31',
      400: '\uC0AC\uBC31',
      300: '\uC0BC\uBC31',
      200: '\uC774\uBC31',
      100: '\uC77C\uBC31',
      90: '\uAD6C\uC2ED',
      80: '\uD314\uC2ED',
      70: '\uCE60\uC2ED',
      60: '\uC721\uC2ED',
      50: '\uC624\uC2ED',
      40: '\uC0AC\uC2ED',
      30: '\uC0BC\uC2ED',
      20: '\uC774\uC2ED',
      10: '\uC77C\uC2ED',
      9: '\uAD6C',
      8: '\uD314',
      7: '\uCE60',
      6: '\uC721',
      5: '\uC624',
      4: '\uC0AC',
      3: '\uC0BC',
      2: '\uC774',
      1: '\uC77C',
      0: '\uC601',
    },
    /* 9000 구천, 8000 팔천, 7000 칠천, 6000 육천, 5000 오천, 4000 사천, 3000 삼천, 2000 이천, 1000 일천, 900 구백, 800 팔백, 700 칠백, 600 육백, 500 오백, 400 사백, 300 삼백, 200 이백, 100 일백, 90 구십, 80 팔십, 70 칠십, 60 육십, 50 오십, 40 사십, 30 삼십, 20 이십, 10 일십, 9 구, 8 팔, 7 칠, 6 육, 5 오, 4 사, 3 삼, 2 이, 1 일, 0 영 */
    suffix: ', ',
    negative: '\uB9C8\uC774\uB108\uC2A4 ',
    /* 마이너스 (followed by a space) */
  );

  /// Formal Korean Han (Hanja) numbering (e.g., 壹仟壹百壹拾壹)
  static final koreanHanjaFormal = CounterStyle.define(
    name: 'korean-hanja-formal',
    system: System.additive,
    range: IntRange(min: -9999, max: 9999),
    additiveSymbols: {
      9000: '\u4E5D\u4EDF',
      8000: '\u516B\u4EDF',
      7000: '\u4E03\u4EDF',
      6000: '\u516D\u4EDF',
      5000: '\u4E94\u4EDF',
      4000: '\u56DB\u4EDF',
      3000: '\u53C3\u4EDF',
      2000: '\u8CB3\u4EDF',
      1000: '\u58F9\u4EDF',
      900: '\u4E5D\u767E',
      800: '\u516B\u767E',
      700: '\u4E03\u767E',
      600: '\u516D\u767E',
      500: '\u4E94\u767E',
      400: '\u56DB\u767E',
      300: '\u53C3\u767E',
      200: '\u8CB3\u767E',
      100: '\u58F9\u767E',
      90: '\u4E5D\u62FE',
      80: '\u516B\u62FE',
      70: '\u4E03\u62FE',
      60: '\u516D\u62FE',
      50: '\u4E94\u62FE',
      40: '\u56DB\u62FE',
      30: '\u53C3\u62FE',
      20: '\u8CB3\u62FE',
      10: '\u58F9\u62FE',
      9: '\u4E5D',
      8: '\u516B',
      7: '\u4E03',
      6: '\u516D',
      5: '\u4E94',
      4: '\u56DB',
      3: '\u53C3',
      2: '\u8CB3',
      1: '\u58F9',
      0: '\u96F6',
    },
    /* 9000 九仟, 8000 八仟, 7000 七仟, 6000 六仟, 5000 五仟, 4000 四仟, 3000 參仟, 2000 貳仟, 1000 壹仟, 900 九百, 800 八百, 700 七百, 600 六百, 500 五百, 400 四百, 300 參百, 200 貳百, 100 壹百, 90 九拾, 80 八拾, 70 七拾, 60 六拾, 50 五拾, 40 四拾, 30 參拾, 20 貳拾, 10 壹拾, 9 九, 8 八, 7 七, 6 六, 5 五, 4 四, 3 參, 2 貳, 1 壹, 0 零 */
    suffix: ', ',
    negative: '\uB9C8\uC774\uB108\uC2A4 ',
    /* 마이너스 (followed by a space) */
  );

  /// Informal Korean Hanja numbering (e.g., 千百十一)
  static final koreanHanjaInformal = CounterStyle.define(
    name: 'korean-hanja-informal',
    system: System.additive,
    range: IntRange(min: -9999, max: 9999),
    additiveSymbols: {
      9000: '\u4E5D\u5343',
      8000: '\u516B\u5343',
      7000: '\u4E03\u5343',
      6000: '\u516D\u5343',
      5000: '\u4E94\u5343',
      4000: '\u56DB\u5343',
      3000: '\u4E09\u5343',
      2000: '\u4E8C\u5343',
      1000: '\u5343',
      900: '\u4E5D\u767E',
      800: '\u516B\u767E',
      700: '\u4E03\u767E',
      600: '\u516D\u767E',
      500: '\u4E94\u767E',
      400: '\u56DB\u767E',
      300: '\u4E09\u767E',
      200: '\u4E8C\u767E',
      100: '\u767E',
      90: '\u4E5D\u5341',
      80: '\u516B\u5341',
      70: '\u4E03\u5341',
      60: '\u516D\u5341',
      50: '\u4E94\u5341',
      40: '\u56DB\u5341',
      30: '\u4E09\u5341',
      20: '\u4E8C\u5341',
      10: '\u5341',
      9: '\u4E5D',
      8: '\u516B',
      7: '\u4E03',
      6: '\u516D',
      5: '\u4E94',
      4: '\u56DB',
      3: '\u4E09',
      2: '\u4E8C',
      1: '\u4E00',
      0: '\u96F6',
    },
    /* 9000 九千, 8000 八千, 7000 七千, 6000 六千, 5000 五千, 4000 四千, 3000 三千, 2000 二千, 1000 千, 900 九百, 800 八百, 700 七百, 600 六百, 500 五百, 400 四百, 300 三百, 200 二百, 100 百, 90 九十, 80 八十, 70 七十, 60 六十, 50 五十, 40 四十, 30 三十, 20 二十, 10 十, 9 九, 8 八, 7 七, 6 六, 5 五, 4 四, 3 三, 2 二, 1 一, 0 零 */
    suffix: ', ',
    negative: '\uB9C8\uC774\uB108\uC2A4 ',
    /* 마이너스 (followed by a space) */
  );

  /// Laotian numbering (e.g., ໑, ໒, ໓, ..., ໙໘, ໙໙, ໑໐໐).
  static final lao = CounterStyle.define(
    name: 'lao',
    system: System.numeric,
    symbols: [
      '\u0ED0',
      '\u0ED1',
      '\u0ED2',
      '\u0ED3',
      '\u0ED4',
      '\u0ED5',
      '\u0ED6',
      '\u0ED7',
      '\u0ED8',
      '\u0ED9'
    ],
    /* ໐ ໑ ໒ ໓ ໔ ໕ ໖ ໗ ໘ ໙ */
  );

  /// Lowercase ASCII letters (e.g., a, b, c, ..., z, aa, ab).
  static final lowerAlpha = CounterStyle.define(
    name: 'lower-alpha',
    system: System.alphabetic,
    symbols: [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z'
    ],
  );

  /// Lowercase classical Greek (e.g., α, β, γ, ..., ω, αα, αβ).
  static final lowerGreek = CounterStyle.define(
    name: 'lower-greek',
    system: System.alphabetic,
    symbols: [
      '\u03B1',
      '\u03B2',
      '\u03B3',
      '\u03B4',
      '\u03B5',
      '\u03B6',
      '\u03B7',
      '\u03B8',
      '\u03B9',
      '\u03BA',
      '\u03BB',
      '\u03BC',
      '\u03BD',
      '\u03BE',
      '\u03BF',
      '\u03C0',
      '\u03C1',
      '\u03C3',
      '\u03C4',
      '\u03C5',
      '\u03C6',
      '\u03C7',
      '\u03C8',
      '\u03C9'
    ],
    /* α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω */
  );

  /// Lowercase ASCII letters (e.g., a, b, c, ..., z, aa, ab).
  static final lowerLatin = CounterStyle.define(
    name: 'lower-latin',
    system: System.alphabetic,
    symbols: [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z'
    ],
  );

  /// Lowercase ASCII Roman numerals (e.g., i, ii, iii, ..., xcviii, xcix, c).
  static final lowerRoman = CounterStyle.define(
    name: 'lower-roman',
    system: System.additive,
    range: const IntRange(min: 1, max: 3999),
    additiveSymbols: {
      1000: 'm',
      900: 'cm',
      500: 'd',
      400: 'cd',
      100: 'c',
      90: 'xc',
      50: 'l',
      40: 'xl',
      10: 'x',
      9: 'ix',
      5: 'v',
      4: 'iv',
      1: 'i'
    },
  );

  /// Malayalam numbering (e.g., ൧, ൨, ൩, ..., ൯൮, ൯൯, ൧൦൦).
  static final malayalam = CounterStyle.define(
    name: 'malayalam',
    system: System.numeric,
    symbols: [
      '\u0D66',
      '\u0D67',
      '\u0D68',
      '\u0D69',
      '\u0D6A',
      '\u0D6B',
      '\u0D6C',
      '\u0D6D',
      '\u0D6E',
      '\u0D6F'
    ],
    /* ൦ ൧ ൨ ൩ ൪ ൫ ൬ ൭ ൮ ൯ */
  );

  /// Mongolian numbering (e.g., ᠑, ᠒, ᠓, ..., ᠙᠘, ᠙᠙, ᠑᠐᠐).
  static final mongolian = CounterStyle.define(
    name: 'mongolian',
    system: System.numeric,
    symbols: [
      '\u1810',
      '\u1811',
      '\u1812',
      '\u1813',
      '\u1814',
      '\u1815',
      '\u1816',
      '\u1817',
      '\u1818',
      '\u1819'
    ],
    /* ᠐ ᠑ ᠒ ᠓ ᠔ ᠕ ᠖ ᠗ ᠘ ᠙ */
  );

  /// Myanmar (Burmese) numbering (e.g., ၁, ၂, ၃, ..., ၉၈, ၉၉, ၁၀၀).
  static final myanmar = CounterStyle.define(
    name: 'myanmar',
    system: System.numeric,
    symbols: [
      '\u1040',
      '\u1041',
      '\u1042',
      '\u1043',
      '\u1044',
      '\u1045',
      '\u1046',
      '\u1047',
      '\u1048',
      '\u1049'
    ],
    /* ၀ ၁ ၂ ၃ ၄ ၅ ၆ ၇ ၈ ၉ */
  );

  /// Oriya numbering (e.g., ୧, ୨, ୩, ..., ୯୮, ୯୯, ୧୦୦).
  static final oriya = CounterStyle.define(
    name: 'oriya',
    system: System.numeric,
    symbols: [
      '\u0B66',
      '\u0B67',
      '\u0B68',
      '\u0B69',
      '\u0B6A',
      '\u0B6B',
      '\u0B6C',
      '\u0B6D',
      '\u0B6E',
      '\u0B6F'
    ],
    /* ୦ ୧ ୨ ୩ ୪ ୫ ୬ ୭ ୮ ୯ */
  );

  /// Persian numbering (e.g., ۱, ۲, ۳, ۴, ..., ۹۸, ۹۹, ۱۰۰).
  static final persian = CounterStyle.define(
    name: 'persian',
    system: System.numeric,
    symbols: [
      '\u06F0',
      '\u06F1',
      '\u06F2',
      '\u06F3',
      '\u06F4',
      '\u06F5',
      '\u06F6',
      '\u06F7',
      '\u06F8',
      '\u06F9'
    ],
    /* ۰ ۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹ */
  );

  //TODO simp-chinese-formal
  //TODO simp-chinese-informal

  /// A filled square, similar to ▪ U+25AA BLACK SMALL SQUARE.
  static final square = CounterStyle.define(
    name: 'square',
    system: System.cyclic,
    symbols: ['\u25AA'],
    /* ▪ */
    suffix: ' ',
  );

  /// Tamil numbering (e.g., ௧, ௨, ௩, ..., ௯௮, ௯௯, ௧௦௦).
  static final tamil = CounterStyle.define(
    name: 'tamil',
    system: System.numeric,
    symbols: [
      '\u0BE6',
      '\u0BE7',
      '\u0BE8',
      '\u0BE9',
      '\u0BEA',
      '\u0BEB',
      '\u0BEC',
      '\u0BED',
      '\u0BEE',
      '\u0BEF'
    ],
    /* ௦ ௧ ௨ ௩ ௪ ௫ ௬ ௭ ௮ ௯ */
  );

  /// Telugu numbering (e.g., ౧, ౨, ౩, ..., ౯౮, ౯౯, ౧౦౦).
  static final telugu = CounterStyle.define(
    name: 'telugu',
    system: System.numeric,
    symbols: [
      '\u0C66',
      '\u0C67',
      '\u0C68',
      '\u0C69',
      '\u0C6A',
      '\u0C6B',
      '\u0C6C',
      '\u0C6D',
      '\u0C6E',
      '\u0C6F'
    ],
    /* ౦ ౧ ౨ ౩ ౪ ౫ ౬ ౭ ౮ ౯ */
  );

  /// Thai (Siamese) numbering (e.g., ๑, ๒, ๓, ..., ๙๘, ๙๙, ๑๐๐).
  static final thai = CounterStyle.define(
    name: 'thai',
    system: System.numeric,
    symbols: [
      '\u0E50',
      '\u0E51',
      '\u0E52',
      '\u0E53',
      '\u0E54',
      '\u0E55',
      '\u0E56',
      '\u0E57',
      '\u0E58',
      '\u0E59'
    ],
    /* ๐ ๑ ๒ ๓ ๔ ๕ ๖ ๗ ๘ ๙ */
  );

  /// Tibetan numbering (e.g., ༡, ༢, ༣, ..., ༩༨, ༩༩, ༡༠༠).
  static final tibetan = CounterStyle.define(
    name: 'tibetan',
    system: System.numeric,
    symbols: [
      '\u0F20',
      '\u0F21',
      '\u0F22',
      '\u0F23',
      '\u0F24',
      '\u0F25',
      '\u0F26',
      '\u0F27',
      '\u0F28',
      '\u0F29'
    ],
    /* ༠ ༡ ༢ ༣ ༤ ༥ ༦ ༧ ༨ ༩ */
  );

  //TODO trad-chinese-formal
  //TODO trad-chinese-informal

  /// Uppercase ASCII letters (e.g., A, B, C, ..., Z, AA, AB).
  static final upperAlpha = CounterStyle.define(
    name: 'upper-alpha',
    system: System.alphabetic,
    symbols: [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ],
  );

  /// Uppercase ASCII letters (e.g., A, B, C, ..., Z, AA, AB).
  static final upperLatin = CounterStyle.define(
    name: 'upper-latin',
    system: System.alphabetic,
    symbols: [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ],
  );

  /// Uppercase ASCII Roman numerals (e.g., I, II, III, ..., XCVIII, XCIX, C).
  static final upperRoman = CounterStyle.define(
    name: 'lower-roman',
    system: System.additive,
    range: const IntRange(min: 1, max: 3999),
    additiveSymbols: {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I'
    },
  );
}
