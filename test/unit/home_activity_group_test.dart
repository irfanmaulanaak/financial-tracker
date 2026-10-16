import 'package:financial_tracker/src/core/formatters.dart';
import 'package:financial_tracker/src/features/expenses/expense.dart';
import 'package:financial_tracker/src/features/home/widgets/home_activity_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Expense _exp(DateTime date, {int amount = 10000}) => Expense(
      id: 'e${date.microsecondsSinceEpoch}',
      amount: amount,
      categoryId: 'food',
      note: null,
      spentBy: 'u1',
      date: date,
      recurring: false,
      cardId: null,
      installmentPlanId: null,
      sourceAccountId: null,
      createdAt: date,
      createdBy: 'u1',
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  final now = DateTime(2026, 10, 16, 12); // Jumat

  group('activityDayLabel', () {
    test('today is "Hari ini"', () {
      expect(activityDayLabel(DateTime(2026, 10, 16, 9), now), 'Hari ini');
    });

    test('yesterday is "Kemarin, <d MMM>"', () {
      final y = DateTime(2026, 10, 15);
      expect(activityDayLabel(y, now), 'Kemarin, ${Dates.dayMonth(y)}');
    });

    test('older is "<weekday>, <d MMM>"', () {
      final d = DateTime(2026, 10, 14);
      expect(activityDayLabel(d, now), '${Dates.weekday(d)}, ${Dates.dayMonth(d)}');
    });
  });

  group('groupActivityByDay', () {
    test('buckets newest-first, preserving order', () {
      final items = [
        _exp(DateTime(2026, 10, 16, 11), amount: 1),
        _exp(DateTime(2026, 10, 16, 8), amount: 2),
        _exp(DateTime(2026, 10, 15, 20), amount: 3),
        _exp(DateTime(2026, 10, 14, 9), amount: 4),
      ];
      final groups = groupActivityByDay(items, now);

      expect(groups.length, 3);
      expect(groups[0].label, 'Hari ini');
      expect(groups[0].items.length, 2);
      expect(groups[1].label, 'Kemarin, ${Dates.dayMonth(DateTime(2026, 10, 15))}');
      expect(groups[1].items.length, 1);
      expect(groups[2].items.single.amount, 4);
    });

    test('empty input yields no groups', () {
      expect(groupActivityByDay(const [], now), isEmpty);
    });
  });
}
