import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/budget_move.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../core/streak.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income.dart';
import 'insights_providers.dart';
import 'recap_helpers.dart';
import 'recap_window_incomes.dart';
import 'widgets/recap_tiles.dart';
import 'widgets/recap_ziswaf_card.dart';

export 'recap_helpers.dart';
export 'recap_window_incomes.dart';
export 'widgets/recap_tiles.dart';
export 'widgets/recap_ziswaf_card.dart';

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
    final incomes = ref.watch(windowIncomesProvider(window)).value ??
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
    final streak = ref.watch(recordingStreakProvider);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
          child: FtRefreshable(
            onRefresh: () async {
              ref.invalidate(cycleExpensesProvider);
              ref.invalidate(previousCyclesExpensesProvider);
              ref.invalidate(windowIncomesProvider);
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
                      RecapCycleChip(
                        label: 'Siklus ini',
                        active: _which == 0,
                        onTap: () => setState(() => _which = 0),
                      ),
                      const SizedBox(width: 8),
                      RecapCycleChip(
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
                if (_which == 0 && streak >= minVisibleStreak)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: FtColors.ink4),
                        const SizedBox(width: 6),
                        Text(
                          streakLabel(streak),
                          style:
                              TextStyle(color: FtColors.ink3, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (_which == 0)
                  FtCard(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    onTap: () => context.push('/money-date'),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_rounded,
                            size: 18, color: FtColors.clay),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Money Date',
                                style: TextStyle(
                                  color: FtColors.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Review bareng ±7 menit. 4 langkah, 1 keputusan',
                                style: TextStyle(
                                    color: FtColors.ink3, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: FtColors.ink4),
                      ],
                    ),
                  ),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  child: Row(
                    children: [
                      RecapStat(
                          label: 'Masuk', value: earned, color: FtColors.sage),
                      const SizedBox(width: 12),
                      RecapStat(label: 'Keluar', value: spent),
                      const SizedBox(width: 12),
                      RecapStat(
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
                  // Framing positif: rayakan dulu yang berhasil dihemat,
                  // baru tampilkan daftar lengkap (riset churn: rasa
                  // bersalah saat melihat overspend = pemicu berhenti).
                  if (biggestSaver(byCat, byCatBase) case final saver?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: FtColors.moss.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: FtColors.moss.withValues(alpha: 0.24),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.celebration_rounded,
                                size: 16, color: FtColors.moss),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Paling hemat: ${household.categoryOf(saver.id)?.label ?? '-'}, turun ${Money.compact(saver.saved)} vs pembanding.',
                                style: TextStyle(
                                  color: FtColors.moss,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 4, 22, 8),
                    child: Eyebrow('Per kategori vs siklus sebelumnya'),
                  ),
                  for (final entry in topCats.take(6))
                    RecapCategoryDeltaTile(
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
                    RecapBiggestTile(
                      record: e,
                      household: household,
                      note: noteOfExpense(expenses, e),
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
                // ZISWAF: total siklus + total tahun berjalan (bantu hitung
                // zakat & rekap niat sedekah). Hanya tampil bila ada
                // kategori bertanda ZISWAF.
                if (household.ziswafCategoryIds.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Eyebrow('ZISWAF'),
                  ),
                  RecapZiswafCard(
                    household: household,
                    cycleTotal: expenses
                        .where((e) =>
                            household.ziswafCategoryIds.contains(e.categoryId))
                        .fold(0, (a, e) => a + e.amount),
                  ),
                ],
                if (movesInCycle(household.budgetMoves,
                        start: window.start, endExclusive: window.endExclusive)
                    case final moves when moves.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Eyebrow('Pergeseran anggaran'),
                  ),
                  FtCard(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in moves)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${prettyName(household.memberOf(m.by)?.displayName ?? 'Anggota')} '
                              'menggeser ${Money.compact(m.amount)}: '
                              '${household.categoryOf(m.fromId)?.label ?? '-'} → '
                              '${household.categoryOf(m.toId)?.label ?? '-'} '
                              '· ${Dates.dayMonth(m.at)}',
                              style: TextStyle(
                                color: FtColors.ink2,
                                fontSize: 12,
                                height: 1.4,
                              ),
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
}
