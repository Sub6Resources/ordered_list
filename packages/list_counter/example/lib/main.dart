import 'package:list_counter/list_counter.dart';

/// Defines a counter and a counter style and then uses it to print out a list from 1-255:
void main() {
  //Here's how to define a simple binary counter style
  final counter = new Counter('binary-counter');

  final counterStyle = CounterStyle.define(
    name: 'binary',
    system: System.numeric,
    padLength: 8,
    padCharacter: '0',
    symbols: ['0','1'],
    range: IntRange(min: -255, max: 255), //Limiting to 255 isn't necessary (it could go on infinitely), but is given as an example
    fallback: 'decimal' //This is the default. Given as an example
  );

  print("Binary numbers 1 through 255");
  //Increment through the entire range
  for(int i = 0; i < 255; i++) {
    counter.increment();
    print(counterStyle.generateMarkerContent(counter.value));
  }

  print("A few out of range values:");
  //Increment out of the range a few times to show that it reverts to decimal
  for(int i = 0; i < 5; i++) {
    counter.increment();
    print(counterStyle.generateMarkerContent(counter.value));
  }

  //Reset to 0.
  counter.reset();

  //Now do it in reverse! Note that padLength includes the negative symbol.
  print("Negative values from -1 to -8");
  for(int i = 0; i > -8; i--) {
    counter.increment(-1);
    print(counterStyle.generateMarkerContent(counter.value));
  }
}