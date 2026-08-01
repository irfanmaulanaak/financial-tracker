import 'package:financial_tracker/src/features/cards/cards_screen.dart';
import 'package:financial_tracker/src/features/cards/credit_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DSR counts only active multi-month installments', () {
    final installments = [
      _installment(monthly: 6215797, monthsTotal: 1),
      _installment(monthly: 2227733, monthsTotal: 3),
      _installment(monthly: 1000000, monthsTotal: 3, monthsPaid: 3),
    ];

    expect(monthlyInstallmentDsrTotal(installments), 2227733);
  });
}

Installment _installment({
  required int monthly,
  required int monthsTotal,
  int monthsPaid = 0,
}) {
  return Installment(
    id: 'installment-$monthly',
    cardId: 'card-1',
    expenseId: 'expense-$monthly',
    label: 'Test',
    total: monthly * monthsTotal,
    monthly: monthly,
    monthsTotal: monthsTotal,
    monthsPaid: monthsPaid,
    startedAt: DateTime(2026),
  );
}
