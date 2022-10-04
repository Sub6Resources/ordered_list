library list_counter;

/// A counter class that follows the specification outlined at
/// https://www.w3.org/TR/css-lists-3/#auto-numbering.
///
/// Essentially, the created Counter stores a value that can be incremented by
/// a given value (even negative numbers).
class Counter {
  final String name;
  int value;

  Counter(this.name, [this.value = 0]);

  void increment([int byValue = 1]) {
    value += byValue;
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
  }): _algorithm = algorithm,
        _negative = negative,
        _prefix = prefix,
        _suffix = suffix,
        _range = range,
        _padLength = padLength,
        _padCharacter = padCharacter,
        _fallbackStyle = fallbackStyle;

  factory CounterStyle.define({
    required String name,
    System system = System.symbolic,
    String negative = '-',
    String prefix = '',
    String suffix = '\u002E\u0020',
    IntRange? range,
    /// Must be greater than or equal to 0.
    int padLength = 0,
    String padCharacter = '',
    String fallback = 'decimal',
    List<String> symbols = const [],
    Map<int, String> additiveSymbols = const {},
    //TODO speak-as descriptor (https://www.w3.org/TR/css-counter-styles-3/#counter-style-speak-as)
  }) {
    assert(padLength >= 0);
    assert(symbols.isNotEmpty || additiveSymbols.isNotEmpty);

    range ??= system.range;

    algorithm(int count) {

      if(!range!.withinRange(count)) {
        return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
      }

      switch (system) {
        case System.cyclic:
          assert(symbols.isNotEmpty);
          return symbols[(count - 1) % symbols.length];
        case System.fixed:
          assert(symbols.isNotEmpty);
          int firstSymbolValue = 1; //TODO this could potentially be defined by the user (see https://www.w3.org/TR/css-counter-styles-3/#fixed-system)
          if(count >= firstSymbolValue && count < firstSymbolValue + symbols.length) {
            return symbols[count - firstSymbolValue];
          } else {
            return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
          }
        case System.numeric:
          assert(symbols.length >= 2);
          int n = symbols.length;
          String result = '';

          int value = count;
          if(value == 0) {
            result = symbols[0];
            break;
          }

          while(value != 0) {
            result = '${symbols[value % n]}$result';
            value = value ~/ n;
          }

          return result;
        case System.alphabetic:
          assert(symbols.length >= 2);
          int n = symbols.length;
          String result = '';

          int value = count;
          while(value != 0) {
            value--;
            result = '${symbols[value % n]}$result';
            value = value ~/ n;
          }
          return result;
        case System.symbolic:
          int n = symbols.length;
          final representation = StringBuffer();
          for(int i = 0; i < ((count ~/ n) + 1); i++) {
            representation.write(symbols[(count - 1) % n]);
          }
          return representation.toString();
        case System.additive:
          assert(additiveSymbols.isNotEmpty);
          int value = count;
          final tuples = additiveSymbols.entries;

          if(value == 0) {
            if(additiveSymbols.containsKey(0)) {
              return additiveSymbols[0]!;
            }

            return PredefinedCounterStyles.lookup(fallback)._algorithm(count);
          }

          final buffer = StringBuffer();
          for(var tuple in tuples) {
            final weight = tuple.key;
            final symbol = tuple.value;

            if(weight == 0 || weight > value) continue;

            final reps = value ~/ weight;
            for(int i = 0; i < reps; i++) {
              buffer.write(symbol);
            }
            value -= weight * reps;
            if(value == 0) {
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

    if(!_range.withinRange(count)) {
      return PredefinedCounterStyles.lookup(_fallbackStyle)._algorithm(count);
    }

    final initialCounterContent = _algorithm(count.abs());

    if(count < 0) {
      final padded = initialCounterContent.padLeft(_padLength - _negative.length, _padCharacter);
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

  const IntRange({this.min, this.max});

  const IntRange.infinite(): min = null, max = null;

  bool withinRange(int value) {
    if(min != null && min! > value) {
      return false;
    }
    if(max != null && max! < value) {
      return false;
    }

    return true;
  }
}

enum System {
  cyclic(IntRange.infinite()),
  numeric(IntRange.infinite()),
  fixed(IntRange.infinite()),
  alphabetic(IntRange(min: 1)),
  symbolic(IntRange(min: 1)),
  additive(IntRange(min: 0));

  final IntRange range;

  const System(this.range);
}

/// Defines default counter-styles
/// (ref: https://www.w3.org/TR/css-counter-styles-3/#predefined-counters)
///
/// For more beyond what are defined here,
/// see https://www.w3.org/TR/predefined-counter-styles/
class PredefinedCounterStyles {
  // This class isn't meant to be instantiated.
  PredefinedCounterStyles._();

  static CounterStyle lookup(String name) {
    switch(name) {
      case 'arabic-indic': return arabicIndic;
      case 'bengali': return bengali;
      case 'cambodian': return cambodian;
      case 'khmer': return khmer;
      case 'circle': return circle;
      case 'cjk-decimal': return cjkDecimal;
      case 'cjk-earthly-branch': return cjkEarthlyBranch;
      case 'cjk-heavenly-stem': return cjkHeavenlyStem;
      case 'decimal': return decimal;
      case 'decimal-leading-zero': return decimalLeadingZero;
      case 'devanagari': return devanagari;
      case 'disc': return disc;
      case 'disclosure-closed': return disclosureClosed;
      case 'disclosure-open': return disclosureOpen;
      case 'gujarati': return gujarati;
      case 'gurmukhi': return gurmukhi;
      case 'hiragana': return hiragana;
      case 'hiragana-iroha': return hiraganaIroha;
      case 'kannada': return kannada;
      case 'katakana': return katakana;
      case 'katakana-iroha': return katakanaIroha;
      case 'lao': return lao;
      case 'lower-alpha': return lowerAlpha;
      case 'lower-greek': return lowerGreek;
      case 'lower-latin': return lowerLatin;
      case 'lower-roman': return lowerRoman;
      case 'malayalam': return malayalam;
      case 'mongolian': return mongolian;
      case 'myanmar': return myanmar;
      case 'oriya': return oriya;
      case 'persian': return persian;
      case 'square': return square;
      case 'tamil': return tamil;
      case 'telugu': return telugu;
      case 'thai': return thai;
      case 'tibetan': return tibetan;
      case 'upper-alpha': return upperAlpha;
      case 'upper-latin': return upperLatin;
      case 'upper-roman': return upperRoman;
      default: return decimal;
    }
  }
  static final arabicIndic = CounterStyle.define(
    name: 'arabic-indic',
    system: System.numeric,
    symbols: const ['\u0660', '\u0661', '\u0662', '\u0663', '\u0664', '\u0665', '\u0666', '\u0667', '\u0668', '\u0669'],
  );
  //TODO armenian, upper-armenian, and lower-armenian
  static final bengali = CounterStyle.define(
    name: 'bengali',
    system: System.numeric,
    symbols: const ['\u09E6', '\u09E7', '\u09E8', '\u09E9', '\u09EA', '\u09EB', '\u09EC', '\u09ED', '\u09EE', '\u09EF'],
    /* ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯ */
  );
  static final cambodian = CounterStyle.define(
    name: 'cambodian',
    system: System.numeric,
    symbols: const ['\u17E0', '\u17E1', '\u17E2', '\u17E3', '\u17E4', '\u17E5', '\u17E6', '\u17E7', '\u17E8', '\u17E9'],
    /* ០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩ */
  );
  static final khmer = CounterStyle.define(
    name: 'khmer', //Extends 'cambodian'
    system: System.numeric,
    symbols: const ['\u17E0', '\u17E1', '\u17E2', '\u17E3', '\u17E4', '\u17E5', '\u17E6', '\u17E7', '\u17E8', '\u17E9'],
    /* ០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩ */
  );
  static final circle = CounterStyle.define(
    name: 'circle',
    system: System.cyclic,
    symbols: ['\u25E6'],
    /* ◦ */
    suffix: ' ',
  );
  static final cjkDecimal = CounterStyle.define(
    name: 'cjk-decimal',
    system: System.numeric,
    symbols: const ['\u3007', '\u4E00', '\u4E8C', '\u4E09', '\u56DB', '\u4E94', '\u516D', '\u4E03', '\u516B', '\u4E5D'],
    /* 〇 一 二 三 四 五 六 七 八 九 */
    suffix: '\u3001',
    /* "、" */
  );
  static final cjkEarthlyBranch = CounterStyle.define(
    name: 'cjk-earthly-branch',
    system: System.fixed,
    symbols: ['\u5B50', '\u4E11', '\u5BC5', '\u536F', '\u8FB0', '\u5DF3', '\u5348', '\u672A', '\u7533', '\u9149', '\u620C', '\u4EA5'],
    /* 子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥 */
    suffix: '、',
  );
  static final cjkHeavenlyStem = CounterStyle.define(
    name: 'cjk-heavenly-stem',
    system: System.fixed,
    symbols: ['\u7532', '\u4E59', '\u4E19', '\u4E01', '\u620A', '\u5DF1', '\u5E9A', '\u8F9B', '\u58EC', '\u7678'],
    /* 甲 乙 丙 丁 戊 己 庚 辛 壬 癸 */
    suffix: '、',
  );
  //TODO cjk-ideographic
  static final decimal = CounterStyle.define(
    name: 'decimal',
    system: System.numeric,
    symbols: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
  );
  static final decimalLeadingZero = CounterStyle.define(
    name: 'decimal-leading-zero',
    system: System.numeric,
    symbols: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    padCharacter: '0',
    padLength: 2,
  );
  static final devanagari = CounterStyle.define(
    name: 'devanagari',
    system: System.numeric,
    symbols: ['\u0966', '\u0967', '\u0968', '\u0969', '\u096A', '\u096B', '\u096C', '\u096D', '\u096E', '\u096F'],
    /* ० १ २ ३ ४ ५ ६ ७ ८ ९ */
  );
  static final disc = CounterStyle.define(
    name: 'disc',
    system: System.cyclic,
    symbols: ['\u2022'],
    /* • */
    suffix: ' ',
  );
  static final disclosureClosed = CounterStyle.define(
    name: 'disclosure-closed',
    system: System.cyclic,
    symbols: ['\u25B8'], //TODO for rtl use \u25C2 (◂)
    /* ▸ */
    suffix: ' ',
  );
  static final disclosureOpen = CounterStyle.define(
    name: 'disclosure-open',
    system: System.cyclic,
    symbols: ['\u25BE'],
    /* ▾ */
    suffix: ' ',
  );
  //TODO ethiopic-numeric
  //TODO georgian
  static final gujarati = CounterStyle.define(
    name: 'gujarati',
    system: System.numeric,
    symbols: ['\u0AE6', '\u0AE7', '\u0AE8', '\u0AE9', '\u0AEA', '\u0AEB', '\u0AEC', '\u0AED', '\u0AEE', '\u0AEF'],
    /* ૦ ૧ ૨ ૩ ૪ ૫ ૬ ૭ ૮ ૯ */
  );
  static final gurmukhi = CounterStyle.define(
    name: 'gurmukhi',
    system: System.numeric,
    symbols: ['\u0A66', '\u0A67', '\u0A68', '\u0A69', '\u0A6A', '\u0A6B', '\u0A6C', '\u0A6D', '\u0A6E', '\u0A6F'],
    /* ੦ ੧ ੨ ੩ ੪ ੫ ੬ ੭ ੮ ੯ */
  );
  //TODO hebrew
  static final hiragana = CounterStyle.define(
    name: 'hiragana',
    system: System.alphabetic,
    symbols: ['\u3042', '\u3044', '\u3046', '\u3048', '\u304A', '\u304B', '\u304D', '\u304F', '\u3051', '\u3053', '\u3055', '\u3057', '\u3059', '\u305B', '\u305D', '\u305F', '\u3061', '\u3064', '\u3066', '\u3068', '\u306A', '\u306B', '\u306C', '\u306D', '\u306E', '\u306F', '\u3072', '\u3075', '\u3078', '\u307B', '\u307E', '\u307F', '\u3080', '\u3081', '\u3082', '\u3084', '\u3086', '\u3088', '\u3089', '\u308A', '\u308B', '\u308C', '\u308D', '\u308F', '\u3090', '\u3091', '\u3092', '\u3093'],
    /* あ い う え お か き く け こ さ し す せ そ た ち つ て と な に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ ろ わ ゐ ゑ を ん */
    suffix: '、',
  );
  static final hiraganaIroha = CounterStyle.define(
    name: 'hiragana-iroha',
    system: System.alphabetic,
    symbols: ['\u3044', '\u308D', '\u306F', '\u306B', '\u307B', '\u3078', '\u3068', '\u3061', '\u308A', '\u306C', '\u308B', '\u3092', '\u308F', '\u304B', '\u3088', '\u305F', '\u308C', '\u305D', '\u3064', '\u306D', '\u306A', '\u3089', '\u3080', '\u3046', '\u3090', '\u306E', '\u304A', '\u304F', '\u3084', '\u307E', '\u3051', '\u3075', '\u3053', '\u3048', '\u3066', '\u3042', '\u3055', '\u304D', '\u3086', '\u3081', '\u307F', '\u3057', '\u3091', '\u3072', '\u3082', '\u305B', '\u3059'],
    /* い ろ は に ほ へ と ち り ぬ る を わ か よ た れ そ つ ね な ら む う ゐ の お く や ま け ふ こ え て あ さ き ゆ め み し ゑ ひ も せ す */
    suffix: '、',
  );
  //TODO japanese-informal
  //TODO japanese-formal
  static final kannada = CounterStyle.define(
    name: 'kannada',
    system: System.numeric,
    symbols: ['\u0CE6', '\u0CE7', '\u0CE8', '\u0CE9', '\u0CEA', '\u0CEB', '\u0CEC', '\u0CED', '\u0CEE', '\u0CEF'],
    /* ೦ ೧ ೨ ೩ ೪ ೫ ೬ ೭ ೮ ೯ */
  );
  static final katakana = CounterStyle.define(
    name: 'katakana',
    system: System.alphabetic,
    symbols: ['\u30A2', '\u30A4', '\u30A6', '\u30A8', '\u30AA', '\u30AB', '\u30AD', '\u30AF', '\u30B1', '\u30B3', '\u30B5', '\u30B7', '\u30B9', '\u30BB', '\u30BD', '\u30BF', '\u30C1', '\u30C4', '\u30C6', '\u30C8', '\u30CA', '\u30CB', '\u30CC', '\u30CD', '\u30CE', '\u30CF', '\u30D2', '\u30D5', '\u30D8', '\u30DB', '\u30DE', '\u30DF', '\u30E0', '\u30E1', '\u30E2', '\u30E4', '\u30E6', '\u30E8', '\u30E9', '\u30EA', '\u30EB', '\u30EC', '\u30ED', '\u30EF', '\u30F0', '\u30F1', '\u30F2', '\u30F3'],
    /* ア イ ウ エ オ カ キ ク ケ コ サ シ ス セ ソ タ チ ツ テ ト ナ ニ ヌ ネ ノ ハ ヒ フ ヘ ホ マ ミ ム メ モ ヤ ユ ヨ ラ リ ル レ ロ ワ ヰ ヱ ヲ ン */
    suffix: '、',
  );
  static final katakanaIroha = CounterStyle.define(
    name: 'katakana-iroha',
    system: System.alphabetic,
    symbols: ['\u30A4', '\u30ED', '\u30CF', '\u30CB', '\u30DB', '\u30D8', '\u30C8', '\u30C1', '\u30EA', '\u30CC', '\u30EB', '\u30F2', '\u30EF', '\u30AB', '\u30E8', '\u30BF', '\u30EC', '\u30BD', '\u30C4', '\u30CD', '\u30CA', '\u30E9', '\u30E0', '\u30A6', '\u30F0', '\u30CE', '\u30AA', '\u30AF', '\u30E4', '\u30DE', '\u30B1', '\u30D5', '\u30B3', '\u30A8', '\u30C6', '\u30A2', '\u30B5', '\u30AD', '\u30E6', '\u30E1', '\u30DF', '\u30B7', '\u30F1', '\u30D2', '\u30E2', '\u30BB', '\u30B9'],
    /* イ ロ ハ ニ ホ ヘ ト チ リ ヌ ル ヲ ワ カ ヨ タ レ ソ ツ ネ ナ ラ ム ウ ヰ ノ オ ク ヤ マ ケ フ コ エ テ ア サ キ ユ メ ミ シ ヱ ヒ モ セ ス */
    suffix: '、',
  );
  //TODO korean-hangul-formal
  //TODO korean-hanja-formal
  //TODO korean-hanja-informal
  static final lao = CounterStyle.define(
    name: 'lao',
    system: System.numeric,
    symbols: ['\u0ED0', '\u0ED1', '\u0ED2', '\u0ED3', '\u0ED4', '\u0ED5', '\u0ED6', '\u0ED7', '\u0ED8', '\u0ED9'],
    /* ໐ ໑ ໒ ໓ ໔ ໕ ໖ ໗ ໘ ໙ */
  );
  static final lowerAlpha = CounterStyle.define(
    name: 'lower-alpha',
    system: System.alphabetic,
    symbols: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'],
  );
  static final lowerGreek = CounterStyle.define(
    name: 'lower-greek',
    system: System.alphabetic,
    symbols: ['\u03B1', '\u03B2', '\u03B3', '\u03B4', '\u03B5', '\u03B6', '\u03B7', '\u03B8', '\u03B9', '\u03BA', '\u03BB', '\u03BC', '\u03BD', '\u03BE', '\u03BF', '\u03C0', '\u03C1', '\u03C3', '\u03C4', '\u03C5', '\u03C6', '\u03C7', '\u03C8', '\u03C9'],
    /* α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω */
  );
  static final lowerLatin = CounterStyle.define(
    name: 'lower-latin',
    system: System.alphabetic,
    symbols: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'],
  );
  static final lowerRoman = CounterStyle.define(
    name: 'lower-roman',
    system: System.additive,
    range: const IntRange(min: 1, max: 3999),
    additiveSymbols: {1000: 'm', 900: 'cm', 500: 'd', 400: 'cd', 100: 'c', 90: 'xc', 50: 'l', 40: 'xl', 10: 'x', 9: 'ix', 5: 'v', 4: 'iv', 1: 'i'},
  );
  static final malayalam = CounterStyle.define(
    name: 'malayalam',
    system: System.numeric,
    symbols: ['\u0D66', '\u0D67', '\u0D68', '\u0D69', '\u0D6A', '\u0D6B', '\u0D6C', '\u0D6D', '\u0D6E', '\u0D6F'],
    /* ൦ ൧ ൨ ൩ ൪ ൫ ൬ ൭ ൮ ൯ */
  );
  static final mongolian = CounterStyle.define(
    name: 'mongolian',
    system: System.numeric,
    symbols: ['\u1810', '\u1811', '\u1812', '\u1813', '\u1814', '\u1815', '\u1816', '\u1817', '\u1818', '\u1819'],
    /* ᠐ ᠑ ᠒ ᠓ ᠔ ᠕ ᠖ ᠗ ᠘ ᠙ */
  );
  static final myanmar = CounterStyle.define(
    name: 'myanmar',
    system: System.numeric,
    symbols: ['\u1040', '\u1041', '\u1042', '\u1043', '\u1044', '\u1045', '\u1046', '\u1047', '\u1048', '\u1049'],
    /* ၀ ၁ ၂ ၃ ၄ ၅ ၆ ၇ ၈ ၉ */
  );
  static final oriya = CounterStyle.define(
    name: 'oriya',
    system: System.numeric,
    symbols: ['\u0B66', '\u0B67', '\u0B68', '\u0B69', '\u0B6A', '\u0B6B', '\u0B6C', '\u0B6D', '\u0B6E', '\u0B6F'],
    /* ୦ ୧ ୨ ୩ ୪ ୫ ୬ ୭ ୮ ୯ */
  );
  static final persian = CounterStyle.define(
    name: 'persian',
    system: System.numeric,
    symbols: ['\u06F0', '\u06F1', '\u06F2', '\u06F3', '\u06F4', '\u06F5', '\u06F6', '\u06F7', '\u06F8', '\u06F9'],
    /* ۰ ۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹ */
  );
  //TODO simp-chinese-formal
  //TODO simp-chinese-informal
  static final square = CounterStyle.define(
    name: 'square',
    system: System.cyclic,
    symbols: ['\u25AA'],
    /* ▪ */
    suffix: ' ',
  );
  static final tamil = CounterStyle.define(
    name: 'tamil',
    system: System.numeric,
    symbols: ['\u0BE6', '\u0BE7', '\u0BE8', '\u0BE9', '\u0BEA', '\u0BEB', '\u0BEC', '\u0BED', '\u0BEE', '\u0BEF'],
    /* ௦ ௧ ௨ ௩ ௪ ௫ ௬ ௭ ௮ ௯ */
  );
  static final telugu = CounterStyle.define(
    name: 'telugu',
    system: System.numeric,
    symbols: ['\u0C66', '\u0C67', '\u0C68', '\u0C69', '\u0C6A', '\u0C6B', '\u0C6C', '\u0C6D', '\u0C6E', '\u0C6F'],
    /* ౦ ౧ ౨ ౩ ౪ ౫ ౬ ౭ ౮ ౯ */
  );
  static final thai = CounterStyle.define(
    name: 'thai',
    system: System.numeric,
    symbols: ['\u0E50', '\u0E51', '\u0E52', '\u0E53', '\u0E54', '\u0E55', '\u0E56', '\u0E57', '\u0E58', '\u0E59'],
    /* ๐ ๑ ๒ ๓ ๔ ๕ ๖ ๗ ๘ ๙ */
  );
  static final tibetan = CounterStyle.define(
    name: 'tibetan',
    system: System.numeric,
    symbols: ['\u0F20', '\u0F21', '\u0F22', '\u0F23', '\u0F24', '\u0F25', '\u0F26', '\u0F27', '\u0F28', '\u0F29'],
    /* ༠ ༡ ༢ ༣ ༤ ༥ ༦ ༧ ༨ ༩ */
  );
  //TODO trad-chinese-formal
  //TODO trad-chinese-informal
  static final upperAlpha = CounterStyle.define(
    name: 'upper-alpha',
    system: System.alphabetic,
    symbols: ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
  );
  static final upperLatin = CounterStyle.define(
    name: 'upper-latin',
    system: System.alphabetic,
    symbols: ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
  );
  static final upperRoman = CounterStyle.define(
    name: 'lower-roman',
    system: System.additive,
    range: const IntRange(min: 1, max: 3999),
    additiveSymbols: {1000: 'M', 900: 'CM', 500: 'D', 400: 'CD', 100: 'C', 90: 'XC', 50: 'L', 40: 'XL', 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I'},
  );
}
