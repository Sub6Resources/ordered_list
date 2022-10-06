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
