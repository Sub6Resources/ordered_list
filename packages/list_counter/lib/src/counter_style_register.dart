import 'package:list_counter/list_counter.dart';

/// Creates a static registry of all available [CounterStyle] options.
///
/// Initially contains all predefined counter styles found in
/// [PredefinedCounterStyle]
class CounterStyleRegistry {
  // This is a static class
  CounterStyleRegistry._();

  /// A map of the names of all predefined counter styles to their definition.
  static final _styleMap = {
    'arabic-indic': PredefinedCounterStyle.arabicIndic,
    'armenian': PredefinedCounterStyle.armenian,
    'lower-armenian': PredefinedCounterStyle.lowerArmenian,
    'upper-armenian': PredefinedCounterStyle.upperArmenian,
    'bengali': PredefinedCounterStyle.bengali,
    'cambodian': PredefinedCounterStyle.cambodian,
    'khmer': PredefinedCounterStyle.khmer,
    'circle': PredefinedCounterStyle.circle,
    'cjk-decimal': PredefinedCounterStyle.cjkDecimal,
    'cjk-earthly-branch': PredefinedCounterStyle.cjkEarthlyBranch,
    'cjk-heavenly-stem': PredefinedCounterStyle.cjkHeavenlyStem,
    'cjk-ideographic': PredefinedCounterStyle.cjkIdeographic,
    'decimal': PredefinedCounterStyle.decimal,
    'decimal-leading-zero': PredefinedCounterStyle.decimalLeadingZero,
    'devanagari': PredefinedCounterStyle.devanagari,
    'disc': PredefinedCounterStyle.disc,
    'disclosure-closed': PredefinedCounterStyle.disclosureClosed,
    'disclosure-open': PredefinedCounterStyle.disclosureOpen,
    'ethiopic-numeric': PredefinedCounterStyle.ethiopicNumeric,
    'georgian': PredefinedCounterStyle.georgian,
    'gujarati': PredefinedCounterStyle.gujarati,
    'gurmukhi': PredefinedCounterStyle.gurmukhi,
    'hebrew': PredefinedCounterStyle.hebrew,
    'hiragana': PredefinedCounterStyle.hiragana,
    'hiragana-iroha': PredefinedCounterStyle.hiraganaIroha,
    'japanese-formal': PredefinedCounterStyle.japaneseFormal,
    'japanese-informal': PredefinedCounterStyle.japaneseInformal,
    'kannada': PredefinedCounterStyle.kannada,
    'katakana': PredefinedCounterStyle.katakana,
    'katakana-iroha': PredefinedCounterStyle.katakanaIroha,
    'korean-hangul-formal': PredefinedCounterStyle.koreanHangulFormal,
    'korean-hanja-informal': PredefinedCounterStyle.koreanHanjaInformal,
    'korean-hanja-formal': PredefinedCounterStyle.koreanHanjaFormal,
    'lao': PredefinedCounterStyle.lao,
    'lower-alpha': PredefinedCounterStyle.lowerAlpha,
    'lower-greek': PredefinedCounterStyle.lowerGreek,
    'lower-latin': PredefinedCounterStyle.lowerLatin,
    'lower-roman': PredefinedCounterStyle.lowerRoman,
    'malayalam': PredefinedCounterStyle.malayalam,
    'mongolian': PredefinedCounterStyle.mongolian,
    'myanmar': PredefinedCounterStyle.myanmar,
    'oriya': PredefinedCounterStyle.oriya,
    'persian': PredefinedCounterStyle.persian,
    'simp-chinese-formal': PredefinedCounterStyle.simpChineseFormal,
    'simp-chinese-informal': PredefinedCounterStyle.simpChineseInformal,
    'square': PredefinedCounterStyle.square,
    'tamil': PredefinedCounterStyle.tamil,
    'telugu': PredefinedCounterStyle.telugu,
    'thai': PredefinedCounterStyle.thai,
    'tibetan': PredefinedCounterStyle.tibetan,
    'trad-chinese-formal': PredefinedCounterStyle.tradChineseFormal,
    'trad-chinese-informal': PredefinedCounterStyle.tradChineseInformal,
    'upper-alpha': PredefinedCounterStyle.upperAlpha,
    'upper-latin': PredefinedCounterStyle.upperLatin,
    'upper-roman': PredefinedCounterStyle.upperRoman,
  };

  /// Lookup a predefined CounterStyle by name (constant-time lookup)
  ///
  /// Defaults to the 'decimal' style if no style is found with the given name.
  static CounterStyle lookup(String name) {
    return _styleMap[name] ?? _styleMap['decimal']!;
  }

  /// Register a new style to the CounterStyle registry. It can then be used as
  /// a fallback in other styles or looked up by name.
  static register(CounterStyle styleToRegister) {
    _styleMap[styleToRegister.name] = styleToRegister;
  }

  /// Registers a list of styles to the CounterStyle registry.
  static registerAll(Iterable<CounterStyle> stylesToRegister) {
    for (var value in stylesToRegister) {
      register(value);
    }
  }
}
