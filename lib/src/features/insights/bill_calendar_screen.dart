import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cash_projection.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../core/recurring.dart';
import '../../core/recurring_runner.dart';
import '../../core/reminder_times.dart';
import '../../core/upcoming.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../cards/cards_screen.dart';
import '../cards/credit_card.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household_providers.dart';
import '../obligations/obligation_repository.dart';

/// Kalender tagihan: semua jatuh tempo kartu + tagihan rutin sampai akhir
/// siklus, dikelompokkan per tanggal, plus proyeksi sisa kas akhir siklus.
class BillCalendarScreen extends ConsumerWidget {
  const BillCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cycle = currentCycle(now, payday: household.payday);
    final daysLeft = cycle.endExclusive.difference(today).inDays;
    final daysElapsed = today.difference(cycle.start).inDays + 1;

    final cards =
        ref.watch(cardsProvider(household.id)).value ?? const <CreditCard>[];
    final recurring =
        ref.watch(recurringExpensesYearProvider).value ?? const <Expense>[];
    final latest = latestPerKey<Expense>(
      recurring,
      keyOf: expenseTemplateKey,
      dateOf: (e) => e.date,
      isRecurring: (e) => e.recurring,
    );
    final items = upcomingItems(
      cards: [
        for (final c in cards) (label: c.label, dueDay: c.dueDay, used: c.used),
      ],
      bills: [
        for (final e in recurring)
          if (latest[expenseTemplateKey(e)] == e.date)
            (
              title: (e.note?.isNotEmpty ?? false)
                  ? e.note!
                  : (household.categoryOf(e.categoryId)?.label ?? 'Tagihan'),
              nextDate: nextMonthlyOccurrence(e.date),
              amount: e.amount,
            ),
        for (final o in ref.watch(obligationsProvider).value ?? const [])
          if (!o.isComplete)
            (
              title: o.label,
              nextDate: nextCardDueDate(o.dueDay, now),
              amount: o.monthly,
            ),
      ],
      now: now,
      withinDays: daysLeft,
    );

    // Proyeksi: kas sekarang − tagihan terjadwal − estimasi belanja harian.
    final liquid = [
      ...household.cashAccounts,
      ...household.savingsAccounts.where((a) => a.liquid),
    ].fold<int>(0, (a, acc) => a + acc.value);
    final expenses =
        ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
    final variableSpent = expenses
        .where((e) => !e.recurring && e.cardId == null)
        .fold<int>(0, (a, e) => a + e.amount);
    final projection = projectEndOfCycle(
      liquidNow: liquid,
      upcomingBillsTotal: items.fold(0, (a, i) => a + i.amount),
      variableSpentSoFar: variableSpent,
      daysElapsed: daysElapsed,
      daysLeft: daysLeft,
    );

    // Kelompokkan per tanggal.
    final groups = <DateTime, List<UpcomingItem>>{};
    for (final i in items) {
      groups.putIfAbsent(i.date, () => []).add(i);
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: FtPageContainer(
          child: Column(
            children: [
              FtSubHeader(
                title: 'Kalender Tagihan',
                trailing: Text(
                  'Sisa $daysLeft hari',
                  style: TextStyle(color: FtColors.ink3, fontSize: 12),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _ProjectionCard(
                      projection: projection,
                      cycleEnd: cycle.endExclusive,
                    ),
                    const SizedBox(height: 18),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            'Tidak ada tagihan terjadwal sampai akhir siklus.',
                            style:
                                TextStyle(color: FtColors.ink3, fontSize: 13),
                          ),
                        ),
                      ),
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Eyebrow(_dayLabel(entry.key, today)),
                      ),
                      for (final i in entry.value)
                        _BillRow(item: i),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime d, DateTime today) {
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Hari ini, ${Dates.dayMonth(d)}';
    if (diff == 1) return 'Besok, ${Dates.dayMonth(d)}';
    return Dates.grouped(d);
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.projection, required this.cycleEnd});

  final CashProjection projection;
  final DateTime cycleEnd;

  @override
  Widget build(BuildContext context) {
    final p = projection;
    final ok = p.projected >= 0;
    final tint = ok ? FtColors.moss : FtColors.danger;
    return FtCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Perkiraan sisa kas akhir siklus'),
          const SizedBox(height: 8),
          Text(
            Money.format(p.projected),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 28,
                  color: tint,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            ok
                ? 'Sampai ${Dates.dayMonth(cycleEnd)} kas diperkirakan masih cukup.'
                : 'Dengan pola belanja sekarang, kas bisa minus sebelum gajian. Cek tagihan di bawah.',
            style: TextStyle(color: FtColors.ink3, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(label: 'Kas + tabungan sekarang', amount: p.liquidNow),
          _BreakdownRow(
              label: 'Tagihan terjadwal', amount: -p.upcomingBills),
          _BreakdownRow(
              label: 'Estimasi belanja harian', amount: -p.estVariable),
          const SizedBox(height: 6),
          Text(
            'Perkiraan kasar dari rata-rata belanja siklus ini.',
            style: TextStyle(
              color: FtColors.ink4,
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: FtColors.ink2, fontSize: 12),
            ),
          ),
          Text(
            amount < 0
                ? '− ${Money.format(-amount)}'
                : Money.format(amount),
            style: TextStyle(
              color: amount < 0 ? FtColors.ink2 : FtColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.item});

  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final isCard = item.kind == UpcomingKind.cardDue;
    final color = FtColors.ochre;
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: color.withValues(alpha: 0.24), width: 0.5),
            ),
            child: Icon(
              isCard ? Icons.credit_card_rounded : Icons.receipt_long_rounded,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCard ? 'Jatuh tempo kartu' : 'Tagihan rutin (perkiraan)',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(item.amount),
            style: TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
