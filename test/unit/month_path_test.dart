import 'package:financial_tracker/src/core/month_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthPathEndMonth', () {
    test('12 months from Agu 2026 lands on Jul 2027 (year rollover)', () {
      final end = monthPathEndMonth(DateTime(2026, 8, 10), 12);
      expect(end.year, 2027);
      expect(end.month, 7);
    });

    test('1 month plan ends the same month it started', () {
      final end = monthPathEndMonth(DateTime(2026, 8, 10), 1);
      expect(end.year, 2026);
      expect(end.month, 8);
    });

    test('6 months within the same year', () {
      final end = monthPathEndMonth(DateTime(2026, 6, 27), 6);
      expect(end.year, 2026);
      expect(end.month, 11);
    });

    test('monthsTotal below 1 is clamped to 1', () {
      final end = monthPathEndMonth(DateTime(2026, 8, 10), 0);
      expect(end.year, 2026);
      expect(end.month, 8);
    });
  });

  group('monthPathBumpLine', () {
    test('renders the remaining-months line', () {
      expect(monthPathBumpLine(8), 'Mantap! Tinggal 8 bulan lagi.');
    });
  });
}
