import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income.dart';
import '../incomes/income_repository.dart';
import 'insights_providers.dart';

/// Rekap siklus — end-of-cycle style summary (Monarch's most-loved feature,
/// adapted to payday cycles): totals, category movers vs previous cycle,
/// biggest expenses, and per-member share.
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key});

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  /// 0 = current (running) cycle, 1 = previous (completed) cycle.
  int _which = 0;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 5),
      );
    }
    final now = DateTime.now();
    final cycle = currentCycle(now, payday: household.payday);
    final prevStart =
        resolvePayday(cycle.start.year, cycle.start.month - 1, household.payday);
    final prev2Start =
        resolvePayday(prevStart.year, prevStart.month - 1, household.payday);

    final window = _which == 0
        ? (start: cycle.start, endExclusive: cycle.endExclusive)
        : (start: prevStart, endExclusive: cycle.start);
    final baselineWindow = _which == 0
        ? (start: prevStart, endExclusive: cycle.start)
        : (start: prev2Start, endExclusive: prevStart);

    final prevCycles =
        ref.watch(previousCyclesExpensesProvider(2)).value ??
            const <List<Expense>>[];
    final expenses = _which == 0
        ? (ref.watch(cycleExpensesProvider).value ?? const <Expense>[])
        : (prevCycles.isNotEmpty ? prevCycles[0] : const <Expense>[]);
    final baseline = _which == 0
        ? (prevCycles.isNotEmpty ? prevCycles[0] : const <Expense>[])
        : (prevCycles.length > 1 ? prevCycles[1] : const <Expense>[]);
    final incomes = ref.watch(_windowIncomesProvider(window)).value ??
        const <Income>[];

    final invIds = household.investmentCategoryIds;
    List<ExpenseRecord> records(List<Expense> src) => [
          for (final e in src)
            ExpenseRecord(
              amount: e.amount,
              categoryId: e.categoryId,
              spentBy: e.spentBy,
              date: e.date,
            ),
        ];
    final cur = consumptionOnly(records(expenses), invIds);
    final base = consumptionOnly(records(baseline), invIds);

    final spent = totalSpent(cur);
    final earned = incomes.fold<int>(0, (a, b) => a + b.amount);
    final net = earned - spent;
    final byCat = spentByCategory(cur);
    final byCatBase = spentByCategory(base);
    final byMember = spentByMember(cur);
    final biggest = [...cur]..sort((a, b) => b.amount.compareTo(a.amount));

    final topCats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
          child: FtRefreshable(
            onRefresh: () async {
              ref.invalidate(cycleExpensesProvider);
              ref.invalidate(previousCyclesExpensesProvider);
              ref.invalidate(_windowIncomesProvider);
              await ftRefreshDelay();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                const FtSubHeader(title: 'Rekap siklus'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: Row(
                    children: [
                      _CycleChip(
                        label: 'Siklus ini',
                        active: _which == 0,
                        onTap: () => setState(() => _which = 0),
                      ),
                      const SizedBox(width: 8),
                      _CycleChip(
                        label: 'Siklus lalu',
                        active: _which == 1,
                        onTap: () => setState(() => _which = 1),
                      ),
                      const Spacer(),
                      Text(
                        Dates.cycleRange(window.start, window.endExclusive),
                        style: TextStyle(color: FtColors.ink3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  child: Row(
                    children: [
                      _Stat(label: 'Masuk', value: earned, color: FtColors.sage),
                      _Stat(label: 'Keluar', value: spent),
                      _Stat(
                        label: net >= 0 ? 'Sisa' : 'Defisit',
                        value: net.abs(),
                        color: net >= 0 ? FtColors.sage : FtColors.danger,
                      ),
                    ],
                  ),
                ),
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            size: 44, color: FtColors.ink4),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada pengeluaran di siklus ini.',
                          style: TextStyle(color: FtColors.ink3, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 4, 22, 8),
                    child: Eyebrow('Per kategori vs siklus sebelumnya'),
                  ),
                  for (final entry in topCats.take(6))
                    _CategoryDeltaTile(
                      category: household.categoryOf(entry.key),
                      spend: entry.value,
                      baseline: byCatBase[entry.key] ?? 0,
                      baselineLabel: Dates.cycleRange(
                          baselineWindow.start, baselineWindow.endExclusive),
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Eyebrow('Pengeluaran terbesar'),
                  ),
                  for (final e in biggest.take(3))
                    _BiggestTile(
                      record: e,
                      household: household,
                      note: _noteOf(expenses, e),
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Eyebrow('Per anggota'),
                  ),
                  FtCard(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Column(
                      children: [
                        for (final m in byMember.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    prettyName(household
                                            .memberOf(m.key)
                                            ?.displayName ??
                                        'Anggota'),
                                    style: TextStyle(
                                        color: FtColors.ink, fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${spent > 0 ? (m.value * 100 / spent).round() : 0}%',
                                  style: TextStyle(
                                      color: FtColors.ink3, fontSize: 11),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  Money.format(m.value),
                                  style: TextStyle(
                                    color: FtColors.ink,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _noteOf(List<Expense> source, ExpenseRecord r) {
    for (final e in source) {
      if (e.amount == r.amount &&
          e.categoryId == r.categoryId &&
          e.date == r.date &&
          e.spentBy == r.spentBy) {
        return e.note;
      }
    }
    return null;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Money.format(value),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 17,
                    color: color ?? FtColors.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleChip extends StatelessWidget {
  const _CycleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : FtColors.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CategoryDeltaTile extends StatelessWidget {
  const _CategoryDeltaTile({
    required this.category,
    required this.spend,
    required this.baseline,
    required this.baselineLabel,
  });
  final Category? category;
  final int spend;
  final int baseline;
  final String baselineLabel;

  @override
  Widget build(BuildContext context) {
    final (deltaText, deltaColor) = switch ((baseline, spend - baseline)) {
      (0, _) => ('baru siklus ini', FtColors.ink3),
      (_, final d) when d > 0 => (
          '+${(d * 100 / baseline).round()}% vs $baselineLabel',
          FtColors.ochre,
        ),
      (_, final d) when d < 0 => (
          '−${(d.abs() * 100 / baseline).round()}% vs $baselineLabel',
          FtColors.sage,
        ),
      _ => ('sama dengan siklus lalu', FtColors.ink3),
    };
    final color = category != null
        ? Color(int.parse('FF${category!.color.replaceFirst('#', '')}',
            radix: 16))
        : FtColors.ink3;

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.label ?? '-',
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deltaText,
                  style: TextStyle(color: deltaColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(spend),
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

class _BiggestTile extends StatelessWidget {
  const _BiggestTile({
    required this.record,
    required this.household,
    required this.note,
  });
  final ExpenseRecord record;
  final Household household;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cat = household.categoryOf(record.categoryId);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (note?.isNotEmpty ?? false) ? note! : (cat?.label ?? '-'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat?.label ?? '-'} · ${Dates.short(record.date)}',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(record.amount),
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

/// Incomes inside an arbitrary window (recap can look at past cycles, which
/// `cycleIncomesProvider` doesn't cover).
final _windowIncomesProvider = StreamProvider.family<List<Income>,
    ({DateTime start, DateTime endExclusive})>((ref, w) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  return ref
      .watch(incomeRepositoryProvider)
      .watchRecent(hid: household.id, limit: 500)
      .map((items) => items
          .where((i) =>
              !i.date.isBefore(w.start) && i.date.isBefore(w.endExclusive))
          .toList());
});
