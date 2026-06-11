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
