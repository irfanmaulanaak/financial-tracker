import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/split_expense.dart';

void main() {
  group('validateSplit', () {
    test('valid: 2 bagian, jumlah pas', () {
      expect(
        validateSplit(100, [
          (categoryId: 'a', amount: 60),
          (categoryId: 'b', amount: 40),
        ]),
        isNull,
      );
    });

    test('kurang dari 2 bagian', () {
      expect(
        validateSplit(100, [(categoryId: 'a', amount: 100)]),
        'min_two',
      );
    });

    test('ada bagian 0', () {
      expect(
        validateSplit(100, [
          (categoryId: 'a', amount: 100),
          (categoryId: 'b', amount: 0),
        ]),
        'zero_amount',
      );
    });

    test('ada bagian tanpa kategori', () {
      expect(
        validateSplit(100, [
          (categoryId: 'a', amount: 60),
          (categoryId: null, amount: 40),
        ]),
        'no_category',
      );
    });

    test('melebihi total', () {
      expect(
        validateSplit(100, [
          (categoryId: 'a', amount: 80),
          (categoryId: 'b', amount: 40),
        ]),
        'over',
      );
    });

    test('masih sisa', () {
      expect(
        validateSplit(100, [
          (categoryId: 'a', amount: 50),
          (categoryId: 'b', amount: 40),
        ]),
        'under',
      );
    });
  });

  test('splitRemainder', () {
    expect(
      splitRemainder(100, [
        (categoryId: null, amount: 30),
        (categoryId: null, amount: 30),
      ]),
      40,
    );
  });
}
