import 'package:financial_tracker/src/core/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCsv', () {
    test('empty rows → empty string', () {
      expect(buildCsv([]), '');
    });

    test('simple rows', () {
      final s = buildCsv([
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
      expect(s, 'a,b,c\n1,2,3\n');
    });

    test('null cells become empty', () {
      final s = buildCsv([
        ['x', null, 'y'],
      ]);
      expect(s, 'x,,y\n');
    });

    test('quotes fields containing comma', () {
      final s = buildCsv([
        ['hello, world', 'plain'],
      ]);
      expect(s, '"hello, world",plain\n');
    });

    test('escapes internal quotes (double them)', () {
      final s = buildCsv([
        ['she said "hi"', 'ok'],
      ]);
      expect(s, '"she said ""hi""",ok\n');
    });

    test('quotes fields containing newline', () {
      final s = buildCsv([
        ['line1\nline2'],
      ]);
      expect(s, '"line1\nline2"\n');
    });

    test('non-string types are stringified', () {
      final s = buildCsv([
        [42, 3.14, true],
      ]);
      expect(s, '42,3.14,true\n');
    });
  });

  group('expensesToCsv', () {
    test('header + rows with ISO dates', () {
      final s = expensesToCsv([
        (
          date: DateTime(2025, 1, 5),
          amount: 50000,
          category: 'Makanan',
          paymentMethod: 'Tunai',
          spentBy: 'Andi',
          note: null,
        ),
        (
          date: DateTime(2025, 11, 30),
          amount: 100000,
          category: 'Belanja, harian',
          paymentMethod: 'Debit',
          spentBy: 'Siti',
          note: 'beli "sayur"',
        ),
      ]);
      expect(s, '''
date,amount,category,paymentMethod,spentBy,note
2025-01-05,50000,Makanan,Tunai,Andi,
2025-11-30,100000,"Belanja, harian",Debit,Siti,"beli ""sayur"""
''');
    });

    test('empty list → header only', () {
      final s = expensesToCsv([]);
      expect(s, 'date,amount,category,paymentMethod,spentBy,note\n');
    });
  });
}
