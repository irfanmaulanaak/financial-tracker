import 'package:financial_tracker/src/features/home/widgets/home_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compactMoney', () {
    test('id-ID style: comma decimal, one space before the unit', () {
      expect(compactMoney(89100000), 'Rp89,1 jt');
      expect(compactMoney(43500000), 'Rp43,5 jt');
      expect(compactMoney(25000), 'Rp25 rb');
      expect(compactMoney(2500000000), 'Rp2,5 M');
    });

    test('drops the trailing ,0', () {
      expect(compactMoney(2000000), 'Rp2 jt');
    });

    test('falls back to the full grouped amount under Rp1.000', () {
      expect(compactMoney(950), 'Rp950');
    });

    test('keeps the minus sign out front', () {
      expect(compactMoney(-89100000), '-Rp89,1 jt');
    });
  });
}
