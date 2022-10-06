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
