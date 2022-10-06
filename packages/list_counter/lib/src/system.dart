import 'package:list_counter/src/int_range.dart';

/// Declares the predefined CounterStyle systems.
enum System {
  /// Cycles repeatedly through its provided symbols, looping back to the beginning
  /// when it reaches the end of the list.
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#cyclic-system
  cyclic(IntRange.infinite(), false),

  /// Interprets the list of symbols as digits to a "place-value" numbering
  /// system (i.e. first symbol represents 0, second represents 1, and so on).
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#numeric-system
  numeric(IntRange.infinite(), true),

  /// Runs through its list of provided symbols once, then falls back on
  /// the fallback counter style's algorithm.
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#fixed-system
  fixed(IntRange.infinite(), false),

  /// Interprets the the list of counter symbols as digits to an alphabetic
  /// numbering system. (e.g. a, b, c, ... z, aa, ab, ac, etc.)
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#alphabetic-system
  alphabetic(IntRange(min: 1), true),

  /// Cycles repeatedly through its provided symbols, doubling, tripling, etc.
  /// the symbols on each successive pass through the list.
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#symbolic-system
  symbolic(IntRange(min: 1), true),

  /// Used to represent "sign-value" numbering systems, where the value of a
  /// number is obtained by adding the digits together. (e.g. Roman numerals)
  ///
  /// See https://www.w3.org/TR/css-counter-styles-3/#additive-system
  additive(IntRange(min: 0), true);

  /// The default range of the given [System].
  final IntRange range;

  final bool usesNegative;

  /// Constructs a System with the given range.
  const System(this.range, this.usesNegative);
}
