import 'package:financial_tracker/src/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID');
  });

  group('Money.format', () {
    test('formats with Rp prefix and dot thousands separators', () {
      expect(Money.format(1234567), 'Rp1.234.567');
      expect(Money.format(0), 'Rp0');
      expect(Money.format(500), 'Rp500');
    });
  });

  group('Money.parse', () {
    test('extracts digits from formatted input', () {
      expect(Money.parse('Rp 1.234.567'), 1234567);
      expect(Money.parse('1234567'), 1234567);
      expect(Money.parse('500'), 500);
    });

    test('returns null when no digits present', () {
      expect(Money.parse(''), isNull);
      expect(Money.parse('Rp'), isNull);
      expect(Money.parse('abc'), isNull);
    });
  });

  group('Money.evalExpression', () {
    test('sums a running +/- expression left-to-right', () {
      expect(Money.evalExpression('25.000+13.000'), 38000);
      expect(Money.evalExpression('25.000+13.000-500'), 37500);
      expect(Money.evalExpression('5.000'), 5000);
    });

    test('ignores a trailing operator', () {
      expect(Money.evalExpression('100+'), 100);
      expect(Money.evalExpression('100-'), 100);
    });

    test('can go negative (submit stays blocked upstream)', () {
      expect(Money.evalExpression('10.000-15.000'), -5000);
    });

    test('null when no digits', () {
      expect(Money.evalExpression(''), isNull);
      expect(Money.evalExpression('+'), isNull);
    });
  });

  group('Money.formatExpression', () {
    test('groups each term id-ID style', () {
      expect(Money.formatExpression('25000+13000'), '25.000+13.000');
      expect(Money.formatExpression('1.000+20000'), '1.000+20.000');
    });

    test('strips leading operators', () {
      expect(Money.formatExpression('+500'), '500');
      expect(Money.formatExpression('-500'), '500');
    });

    test('collapses doubled operators, last one wins', () {
      expect(Money.formatExpression('100+-'), '100-');
      expect(Money.formatExpression('100-+'), '100+');
    });

    test('drops junk chars and leading zeros per term', () {
      expect(Money.formatExpression('Rp 1.234+5'), '1.234+5');
      expect(Money.formatExpression('007+05'), '7+5');
    });
  });

  group('Dates', () {
    test('short format uses Indonesian locale', () {
      final s = Dates.short(DateTime(2025, 9, 30));
      expect(s, contains('2025'));
      expect(s, contains('Sep'));
    });

    test('dayKey strips time component', () {
      final k = Dates.dayKey(DateTime(2025, 9, 30, 14, 33, 12));
      expect(k, DateTime(2025, 9, 30));
    });

    test('cycleRange renders inclusive payday window', () {
      // Cycle [25 Apr, 25 Mei) → shown as 25 Apr–24 Mei.
      final s = Dates.cycleRange(DateTime(2026, 4, 25), DateTime(2026, 5, 25));
      expect(s, '25 Apr–24 Mei');
    });

    test('cycleRange handles year boundary', () {
      final s = Dates.cycleRange(DateTime(2025, 12, 25), DateTime(2026, 1, 23));
      expect(s, '25 Des–22 Jan');
    });
  });
}
