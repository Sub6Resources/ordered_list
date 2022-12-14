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
    final styleToUse = PredefinedCounterStyle.decimal;

    expect(styleToUse.generateCounterContent(counter.value), equals('0'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('0. '));

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
    final styleToUse = PredefinedCounterStyle.decimalLeadingZero;

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
    final styleToUse = PredefinedCounterStyle.decimalLeadingZero;

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
    final styleToUse = PredefinedCounterStyle.hiragana;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('??????'));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('??????'));
  });

  test('Alphabetic CounterStyle Wrapping Test', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyle.lowerAlpha;

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
    final styleToUse = PredefinedCounterStyle.lowerRoman;

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('i'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('i. '));

    counter.increment(10000);

    expect(styleToUse.generateCounterContent(counter.value), equals('10001'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('10001. '));
  });

  test('Test additive system - roman numerals', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyle.upperRoman;

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

  test('Test fixed system', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyle.cjkHeavenlyStem;

    expect(styleToUse.generateCounterContent(counter.value), equals('0'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('11'));
  });

  test('Test cyclic system', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyle.disc;

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('??? '));

    counter.increment();

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('??? '));

    //Increment an arbitrary amount
    counter.increment(1464249);

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('??? '));

    //Now negative
    counter.reset();
    counter.increment(-12454);

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    expect(styleToUse.generateMarkerContent(counter.value), equals('??? '));
  });

  test('Test simp-chinese-informal', () {
    final Counter counter = Counter('basic');
    final styleToUse = PredefinedCounterStyle.simpChineseInformal;

    expect(styleToUse.generateCounterContent(counter.value), equals('???'));
    counter.increment();
    expect(styleToUse.generateCounterContent(counter.value), equals('???'));

    // Test random known values
    expect(styleToUse.generateCounterContent(10), equals('???'));
    expect(styleToUse.generateCounterContent(11), equals('??????'));
    expect(styleToUse.generateCounterContent(20), equals('??????'));
    expect(styleToUse.generateCounterContent(27), equals('?????????'));
    expect(styleToUse.generateCounterContent(63), equals('?????????'));
    expect(styleToUse.generateCounterContent(100), equals('??????'));
    expect(styleToUse.generateCounterContent(104), equals('????????????'));
    expect(styleToUse.generateCounterContent(519), equals('???????????????'));
    expect(styleToUse.generateCounterContent(120), equals('????????????'));

    //Test a negative value
    expect(styleToUse.generateCounterContent(-3104), equals('?????????????????????'));

    //Test an out-of-range value (falls back on cjk-decimal)
    expect(styleToUse.generateCounterContent(1234560), equals('?????????????????????'));
  });

  test('Test ethiopic-numeric style', () {
    final styleToUse = PredefinedCounterStyle.ethiopicNumeric;

    expect(styleToUse.generateCounterContent(100), equals('???'));
    expect(styleToUse.generateCounterContent(78010092), equals('?????????????????????'));
    expect(styleToUse.generateCounterContent(780100000092), equals('????????????????????????'));
  });
}
