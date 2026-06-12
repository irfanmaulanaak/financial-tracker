import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/envelope.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_detail_sheet.dart';
import '../expenses/expense_repository.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import 'budget_move_sheet.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final category = household.categoryOf(categoryId);
    if (category == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: FtAppChrome(
          current: FtTab.spend,
          child: Column(
            children: [
              const FtSubHeader(title: 'Kategori'),
              Expanded(
                child: Center(
                  child: Text('Kategori tidak ditemukan.',
                      style: TextStyle(color: FtColors.ink3)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    final expensesAsync = ref.watch(
      _categoryExpensesProvider((hid: household.id, catId: categoryId)),
    );
    final prevAsync = ref.watch(previousCyclesExpensesProvider(3));

    final color = parseColor(category.color);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.spend,
        child: FtRefreshable(
          onRefresh: () async {
            ref.invalidate(currentHouseholdProvider);
            ref.invalidate(_categoryExpensesProvider((hid: household.id, catId: categoryId)));
            ref.invalidate(previousCyclesExpensesProvider);
            await ftRefreshDelay();
          },
          child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            FtSubHeader(title: category.label),
            _HeaderCard(
              category: category,
              expensesAsync: expensesAsync,
              prevAsync: prevAsync,
              cycle: cycle,
              color: color,
              canMoveBudget: ref.watch(canWriteAllProvider),
            ),
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal: $e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Belum ada pengeluaran di kategori ini.',
                        style: TextStyle(color: FtColors.ink3),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
                      child: Eyebrow('Transaksi Terbaru'),
                    ),
                    for (final e in expenses)
                      FtCard(
                        margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        onTap: () => ExpenseDetailSheet.show(
                          context: context,
                          expense: e,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.note ?? category.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${Dates.short(e.date)}${e.note != null && e.note!.isNotEmpty ? ' · ${e.note}' : ''}',
                                    style: TextStyle(
                                      color: FtColors.ink3,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Money.format(e.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.category,
    required this.expensesAsync,
    required this.prevAsync,
    required this.cycle,
    required this.color,
    required this.canMoveBudget,
  });
  final Category category;
  final AsyncValue<List<Expense>> expensesAsync;
  final AsyncValue<List<List<Expense>>> prevAsync;
  final ({DateTime start, DateTime endExclusive}) cycle;
  final Color color;

  /// Akses `full` → boleh geser anggaran antar kategori.
  final bool canMoveBudget;

  @override
  Widget build(BuildContext context) {
    final spent = expensesAsync.value?.fold<int>(
          0,
          (a, e) => a + e.amount.toInt(),
        ) ??
        0;
    // Compute historical average from previous cycles
    final prev = prevAsync.value ?? const <List<Expense>>[];
    final prevSpent = prev.isEmpty
        ? 0
        : prev[0].where((e) => e.categoryId == category.id).fold<int>(
              0,
              (a, e) => a + e.amount.toInt(),
            );
    final carry = category.rollover
        ? carryOver(
            monthlyBudget: category.monthlyBudget,
            prevCycleSpent: prevSpent,
          )
        : 0;
    final budget = category.monthlyBudget + carry;
    final pct = budget > 0 ? (spent / budget * 100).round() : 0;
    final over = spent > budget;
    final prevTotals = <int>[
      for (final w in prev)
        w.where((e) => e.categoryId == category.id).fold<int>(
              0,
              (a, e) => a + e.amount.toInt(),
            ),
    ];
    final avgPrev = prevTotals.isEmpty
        ? 0
        : prevTotals.fold<int>(0, (a, b) => a + b) ~/ prevTotals.length;
    final delta = avgPrev > 0 ? ((spent - avgPrev) / avgPrev * 100) : 0.0;

    // Real daily bars: last 14 days ending today, summing this category's
    // expenses per day. Missing days → 0.
    final today = Dates.dayKey(DateTime.now());
    final cycleExpenses = expensesAsync.value ?? const <Expense>[];
    final perDay = <DateTime, int>{};
    for (final e in cycleExpenses) {
      final k = Dates.dayKey(e.date);
      perDay[k] = (perDay[k] ?? 0) + e.amount.toInt();
    }
    final dailyBars = List.generate(14, (i) {
      final day = today.subtract(Duration(days: 13 - i));
      return perDay[day] ?? 0;
    });
    final daysPassed = DateTime.now().difference(cycle.start).inDays + 1;
    final dailyAvg = daysPassed > 0 ? spent ~/ daysPassed : 0;

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: color.withValues(alpha: 0.22), width: 0.5),
                ),
                child: Icon(
                  iconFor(category.icon),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow('Pengeluaran siklus ini'),
                    Text(
                      Money.format(spent),
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontSize: 26),
                    ),
                  ],
                ),
              ),
              _StatusChip(over: over),
            ],
          ),
          const SizedBox(height: 14),
          FtProgressBar(
            value: spent,
            max: budget <= 0 ? 1 : budget,
            color: color,
            height: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Money.format(spent)} / ${Money.format(budget)}'
                '${carry > 0 ? ' (gulir +${Money.format(carry)})' : ''}',
                style: TextStyle(
                    color: FtColors.ink2, fontSize: 11),
              ),
              Text(
                '$pct% terpakai',
                style: TextStyle(
                  color: over ? FtColors.danger : FtColors.ink3,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'vs rata-rata 3 siklus',
                  value: avgPrev > 0 ? '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%' : '-',
                  valueColor: delta > 10
                      ? FtColors.danger
                      : delta < -10
                          ? FtColors.moss
                          : FtColors.ink,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Pengeluaran harian',
                  value: Money.format(dailyAvg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < dailyBars.length; i++) ...[
                  Expanded(
                    child: Container(
                      height: max(
                        4,
                        dailyBars[i] /
                            (dailyBars.reduce(max) + 1) *
                            56,
                      ),
                      decoration: BoxDecoration(
                        color: i == dailyBars.length - 1
                            ? color
                            : color.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i != dailyBars.length - 1) const SizedBox(width: 3),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('14 hari terakhir',
                  style: TextStyle(color: FtColors.ink3, fontSize: 10)),
              Text('hari ini',
                  style: TextStyle(color: FtColors.ink3, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: over
                  ? FtColors.danger.withValues(alpha: 0.08)
                  : FtColors.moss.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: over
                    ? FtColors.danger.withValues(alpha: 0.25)
                    : FtColors.moss.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      over
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: over ? FtColors.danger : FtColors.moss,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        over
                            ? 'Melebihi anggaran ${pct - 100}%. Wajar kok meleset — geser saja dari kategori yang masih longgar.'
                            : 'Pola pengeluaran wajar. Sisa ${Money.format(budget - spent)} untuk siklus ini.',
                        style: TextStyle(
                          color: over ? FtColors.danger : FtColors.moss,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (over && canMoveBudget)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          BudgetMoveSheet.show(context, toId: category.id),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Geser anggaran'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.over});
  final bool over;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: over
            ? FtColors.danger.withValues(alpha: 0.12)
            : FtColors.moss.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: over
              ? FtColors.danger.withValues(alpha: 0.25)
              : FtColors.moss.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        over ? '↑ Over' : '✓ Aman',
        style: TextStyle(
          color: over ? FtColors.danger : FtColors.moss,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: FtColors.ink3, fontSize: 10, letterSpacing: 0.3),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? FtColors.ink,
            fontSize: 20,
            fontFamily: 'Newsreader',
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

final _categoryExpensesProvider =
    StreamProvider.family<List<Expense>, ({String hid, String catId})>(
  (ref, p) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) return Stream.value(const []);
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    return ref
        .watch(expenseRepositoryProvider)
        .watchByCategory(
          householdId: p.hid,
          categoryId: p.catId,
          startInclusive: cycle.start,
          endExclusive: cycle.endExclusive,
        );
  },
);
