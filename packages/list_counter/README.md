A `Counter` class that follows the specification outlined at https://www.w3.org/TR/css-lists-3/#auto-numbering.

The `CounterStyle` class represents styles that can be used to generate a 
text representation of the given counter's value (such as a 'iv' for 4,
 or 'β' for 2).

See https://www.w3.org/TR/css-counter-styles-3/#counter-styles for more details.


## Getting started

Getting started is simple:

```yaml
dependencies:
  list_counter: ^1.0.2
```

## Usage

```dart
void main() {
  final counter = Counter('named_counter'); //You can also start a counter at a specific integer value with Counter('name', VALUE);
  final listStyle = PredefinedCounterStyle.upperRoman;
  
  counter.increment(); // Adds 1 to the counter
  print(listStyle.generateMarkerContent(counter.value));
  // Prints "I. "
 
  counter.increment(2021); // Now the counter is at 2022
  print(listStyle.generateMarkerContent(conter.value));
  // Prints "MMXXII. "
 
  // Optionally, you can just print the result of the algorithm without any suffixes:
  print(listStyle.generateCounterContent(counter.value));
  // Prints "MMXXII"
}
```

## Predefined Counter Styles

A lengthy list of predefined counter styles is included!

Some of the most basic include:

 - `PredefinedCounterStyle.decimal` (A simple ordered list)
 - `PredefinedCounterStyle.disc` (A simple bulleted/unordered list)
 - `PredefinedCounterStyle.circle` (A bulleted list with open circles)
 - `PredefinedCounterStyle.square` (A bulleted list with square bullets)
 - `PredefinedCounterStyle.lowerAlpha` (a, b, c, ..., z, aa, ab)

As well as dozens of language-specific number/alphabet systems, such as:

 - `PredefinedCounterStyle.cjkDecimal` (〇 一 二 三 四 五 六 七 八 九 ...)
 - `PredefinedCounterStyle.cambodian` (០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩ ...)
 - `PredefinedCounterStyle.katakana` (ア イ ウ エ オ カ キ ク ...)
 - `PredefinedCounterStyle.koreanHangulFormal` (일천일백일십일, etc.)
 - `PredefinedCounterStyle.simpChineseFormal` (壹仟壹佰壹拾壹, etc.)

See https://www.w3.org/TR/css-counter-styles-3/#predefined-counters for the full list.

## Custom Counter Styles

Or, you can define your own style:

```dart
// Sample additive style taken from https://www.w3.org/TR/css-counter-styles-3/#additive-system
final diceStyle = CounterStyle.define(
  name: 'dice-style',
  system: System.additive,
  additiveSymbols: {6: '⚅', 5: '⚄', 4: '⚃', 3: '⚂', 2: '⚁', 1: '⚀'},
  suffix: " ",
);
```

`diceStyle` will then produce lists that look like:

```
⚀  One
⚁  Two
⚂  Three
...
⚅⚄  Eleven
⚅⚅  Twelve
⚅⚅⚀  Thirteen
```

## Using the `CounterStyleRegistry`

If wanted, you can also dynamically manage a library of `CounterStyle`s using
the static `CounterStyleRegistry`. It is automatically filled with all the
predefined styles.

Here's how it can be used:

```dart
void main() {
  // Optionally register your own styles:
  CounterStyleRegistry.register(myCustomStyle);
  // You can also overwrite any of the predefined styles:
  CounterStyleRegistry.register(customDisc); 
  // customDisc Has name "disc" to overwrite the default style in the registry
  
  // Elsewhere...
  
  // Lookup your custom style by its name to use it:
  CounterStyleRegistry.lookup('my-custom-style');
  // or lookup a predefined style:
  CounterStyleRegistry.lookup('ethiopic-numeric');
  
  // Optionally...
  CounterStyleRegistry.remove('my-custom-style');
}
```