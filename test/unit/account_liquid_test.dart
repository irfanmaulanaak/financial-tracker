import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/features/accounts/account.dart';

void main() {
  group('Account.liquid', () {
    test('tabungan: liquid tersimpan dan terbaca', () {
      final a = Account(
        id: 'depo',
        kind: AccountKind.savings,
        label: 'Deposito BCA',
        hint: null,
        value: 10_000_000,
        sortOrder: 0,
        liquid: false,
      );
      final m = a.toMap();
      expect(m['liquid'], false);
      expect(Account.fromMap(m, AccountKind.savings).liquid, false);
    });

    test('tabungan lama tanpa field: default liquid true', () {
      final a = Account.fromMap(
        {'id': 'jago', 'label': 'Jago', 'value': 1}, AccountKind.savings);
      expect(a.liquid, true);
    });

    test('tunai: selalu liquid, field tidak ditulis', () {
      final a = Account(
        id: 'bca',
        kind: AccountKind.cash,
        label: 'BCA',
        hint: null,
        value: 1,
        sortOrder: 0,
        liquid: false,
      );
      expect(a.toMap().containsKey('liquid'), false);
      expect(Account.fromMap(a.toMap(), AccountKind.cash).liquid, true);
    });
  });
}
