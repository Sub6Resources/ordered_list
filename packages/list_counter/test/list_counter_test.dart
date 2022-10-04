import 'package:test/test.dart';
import 'package:list_counter/list_counter.dart';

void main() {
  test("Basic counter test", () {
    final Counter counter = Counter('basic');

    expect(counter.value, equals(0));

    counter.increment();

    expect(counter.value, equals(1));

    counter.increment();

    expect(counter.value, equals(2));

  });

  test('Custom increment counter test', () {
    final Counter counter = Counter('basic');

    expect(counter.value, equals(0));

    counter.increment(3);

    expect(counter.value, equals(3));

    counter.increment(2);

    expect(counter.value, equals(5));

    counter.increment();

    expect(counter.value, equals(6));
  });

  test('Negative counter', () {
    final Counter counter = Counter('negative');

    expect(counter.value, equals(0));

    counter.increment(-1);

    expect(counter.value, equals(-1));

    counter.increment(-1);

    expect(counter.value, equals(-2));
  });

  test('Decrementing counter', () {
    final Counter counter = Counter('reverse', 10);

    expect(counter.value, equals(10));

    counter.increment(-1);

    expect(counter.value, equals(9));

    counter.increment(-1);

    expect(counter.value, equals(8));

    counter.increment(-8);

    expect(counter.value, equals(0));
  });

  test('Basic CounterStyle test', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.decimal;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('1'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('1. '));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('2'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('2. '));

    counter.increment(10);

    expect(styleToUse.generateCounterContent(counter.value), equals('12'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('12. '));

  });

  test('Padded CounterStyle test', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.decimalLeadingZero;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('01'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('01. '));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('02'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('02. '));

    counter.increment(10);

    expect(styleToUse.generateCounterContent(counter.value), equals('12'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('12. '));

    counter.increment(100);

    expect(styleToUse.generateCounterContent(counter.value), equals('112'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('112. '));

  });

  test('Negative padded CounterStyle test', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.decimalLeadingZero;

    counter.increment(-1);

    expect(styleToUse.generateCounterContent(counter.value), equals('-1'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('-1. '));

    counter.increment(-1);

    expect(styleToUse.generateCounterContent(counter.value), equals('-2'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('-2. '));

    counter.increment(-10);

    expect(styleToUse.generateCounterContent(counter.value), equals('-12'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('-12. '));

    counter.increment(-100);

    expect(styleToUse.generateCounterContent(counter.value), equals('-112'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('-112. '));

  });

  test('Hiragana CounterStyle test', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.hiragana;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('あ'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('あ、'));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('い'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('い、'));

  });

  test('Alphabetic CounterStyle Wrapping Test', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.lowerAlpha;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('a'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('a. '));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('b'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('b. '));

    counter.increment(24);

    expect(styleToUse.generateCounterContent(counter.value), equals('z'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('z. '));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('aa'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('aa. '));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('ab'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('ab. '));

  });

  test('Counter out of range', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.lowerRoman;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('i'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('i. '));

    counter.increment(10000);

    expect(styleToUse.generateCounterContent(counter.value), equals('10001'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('10001. '));

  });

  test('Test additive system - roman numerals', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyles.upperRoman;

    counter.increment(); //1

    expect(styleToUse.generateCounterContent(counter.value), equals('I'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('I. '));

    counter.increment(); //2

    expect(styleToUse.generateCounterContent(counter.value), equals('II'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('II. '));

    counter.increment(); //3

    expect(styleToUse.generateCounterContent(counter.value), equals('III'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('III. '));

    counter.increment(); //4

    expect(styleToUse.generateCounterContent(counter.value), equals('IV'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('IV. '));

    counter.increment(); //5

    expect(styleToUse.generateCounterContent(counter.value), equals('V'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('V. '));

    counter.increment(100); //105

    expect(styleToUse.generateCounterContent(counter.value), equals('CV'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('CV. '));

    counter.increment(); //106

    expect(styleToUse.generateCounterContent(counter.value), equals('CVI'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('CVI. '));

    counter.increment(13); //119

    expect(styleToUse.generateCounterContent(counter.value), equals('CXIX'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('CXIX. '));

    counter.increment(1900); //2019

    expect(styleToUse.generateCounterContent(counter.value), equals('MMXIX'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('MMXIX. '));

    counter.increment(30); //2049

    expect(styleToUse.generateCounterContent(counter.value), equals('MMXLIX'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('MMXLIX. '));

  });

  //TODO test fixed, cyclic, complex (once they are added)
}
