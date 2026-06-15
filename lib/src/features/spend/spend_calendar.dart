import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../home/widgets/recent_list.dart';
import '../household/household.dart';
import '../household/household_providers.dart';

/// Month calendar on `/spend` — each date cell also shows that day's spend
/// (compact `rb/jt`). Standalone month navigation, independent of the cycle
/// period chips above it. Tapping a day with spend opens [_DaySpendSheet].
///
/// Investment-category expenses are excluded so the daily totals match the
/// hero's "spend" figure (see `Household.investmentCategoryIds`).
class SpendCalendar extends ConsumerStatefulWidget {
  const SpendCalendar({super.key});

  @override
  ConsumerState<SpendCalendar> createState() => _SpendCalendarState();
}

class _SpendCalendarState extends ConsumerState<SpendCalendar> {
  /// First day of the displayed month.
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  static const _weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) return const SizedBox.shrink();

    final expenses =
        ref.watch(monthExpensesProvider(_month)).value ?? const <Expense>[];
    final invIds = household.investmentCategoryIds;

    // Per-day-of-month spend totals (consumption only).
    final byDay = <int, int>{};
    for (final e in expenses) {
      if (invIds.contains(e.categoryId)) continue;
      byDay.update(e.date.day, (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Sunday-first column index: Sun→0 … Sat→6 (DateTime.weekday: Mon=1…Sun=7).
    final leadingBlanks = _month.weekday % 7;
    final cellCount = leadingBlanks + daysInMonth;
    final rows = (cellCount / 7).ceil();

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FtFadeUp(
                  key: ValueKey(_month),
                  duration: const Duration(milliseconds: 260),
                  distance: 4,
                  child: Text(
                    Dates.monthLong(_month),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          color: FtColors.ink,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => setState(() => _month =
                    DateTime(_month.year, _month.month - 1, 1)),
              ),
              const SizedBox(width: 4),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                // Don't browse into empty future months.
                onTap: isCurrentMonth
                    ? null
                    : () => setState(() => _month =
                        DateTime(_month.year, _month.month + 1, 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _buildCell(
                      context: context,
                      household: household,
                      expenses: expenses,
                      cellIndex: r * 7 + c,
                      leadingBlanks: leadingBlanks,
                      daysInMonth: daysInMonth,
                      byDay: byDay,
                      today: today,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required Household household,
    required List<Expense> expenses,
    required int cellIndex,
    required int leadingBlanks,
    required int daysInMonth,
    required Map<int, int> byDay,
    required DateTime today,
    }) {
    final day = cellIndex - leadingBlanks + 1;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 52);
    }
    final date = DateTime(_month.year, _month.month, day);
    final spent = byDay[day] ?? 0;
    final hasSpend = spent > 0;
    final isToday = date == today;

    final numberWidget = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: isToday
          ? BoxDecoration(color: FtColors.ink, shape: BoxShape.circle)
          : null,
      child: Text(
        '$day',
        style: TextStyle(
          color: isToday
              ? FtColors.bg
              : (hasSpend ? FtColors.ink : FtColors.ink4),
          fontSize: 13,
          fontWeight: hasSpend ? FontWeight.w600 : FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    final cell = SizedBox(
      height: 52,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          numberWidget,
          const SizedBox(height: 1),
          Text(
            hasSpend ? Money.compact(spent) : '',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: FtColors.ink3,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (!hasSpend) return cell;
    return FtTapScale(
      scale: 0.94,
      onTap: () {
        final dayExpenses =
            expenses.where((e) => e.date.day == day).toList();
        _DaySpendSheet.show(
          context: context,
          household: household,
          date: date,
          expenses: dayExpenses,
        );
      },
      child: cell,
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return FtTapScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: FtColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? FtColors.ink2 : FtColors.ink4,
        ),
      ),
    );
  }
}

/// Bottom sheet listing one day's transactions, opened from a calendar cell.
class _DaySpendSheet extends StatelessWidget {
  const _DaySpendSheet({
    required this.household,
    required this.date,
    required this.expenses,
  });

  final Household household;
  final DateTime date;
  final List<Expense> expenses;

  static Future<void> show({
    required BuildContext context,
    required Household household,
    required DateTime date,
    required List<Expense> expenses,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DaySpendSheet(
        household: household,
        date: date,
        expenses: expenses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final total = sorted.fold<int>(0, (a, e) => a + e.amount);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: FtColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Eyebrow(Dates.grouped(date)),
            const SizedBox(height: 4),
            Text(
              Money.format(total),
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontSize: 26, letterSpacing: -0.3),
            ),
            const SizedBox(height: 4),
            Text(
              '${sorted.length} transaksi',
              style: TextStyle(color: FtColors.ink3, fontSize: 11),
            ),
            const SizedBox(height: 14),
            FtCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    ExpenseActivityRow(
                      expense: sorted[i],
                      category: household.categoryOf(sorted[i].categoryId),
                      spender: household.memberOf(sorted[i].spentBy),
                      showTopBorder: i > 0,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
