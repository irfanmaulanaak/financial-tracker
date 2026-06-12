import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/budget_move.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/money_date.dart';
import '../../core/payday.dart';
import '../../core/recurring.dart';
import '../../core/recurring_runner.dart';
import '../../core/upcoming.dart';
import '../../theme.dart';
import '../../ui/ft_celebrate.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../cards/cards_screen.dart';
import '../cards/credit_card.dart';
import '../categories/budget_move_sheet.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income.dart';
import '../incomes/income_providers.dart';
import 'insights_providers.dart';

/// "Money Date" — review siklus terpandu ±7 menit, 4 langkah, maks 1
/// keputusan (riset: pasangan yang rutin review bersama melaporkan ~40%
/// lebih sedikit konflik uang; mulai dari yang berhasil, bukan yang gagal).
class MoneyDateScreen extends ConsumerStatefulWidget {
  const MoneyDateScreen({super.key});

  @override
  ConsumerState<MoneyDateScreen> createState() => _MoneyDateScreenState();
}

class _MoneyDateScreenState extends ConsumerState<MoneyDateScreen> {
  final _page = PageController();
  int _step = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    FtHaptics.select();
    if (_step >= 3) {
      FtCelebrate.show(context, message: 'Money date selesai!');
      context.pop();
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final cycle = currentCycle(now, payday: household.payday);
    final expenses =
        ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
    final prevCycles = ref.watch(previousCyclesExpensesProvider(1)).value ??
        const <List<Expense>>[];
    final baseline =
        prevCycles.isNotEmpty ? prevCycles[0] : const <Expense>[];
    final incomes =
        ref.watch(cycleIncomesProvider).value ?? const <Income>[];

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
    final deltas = categoryDeltas(spentByCategory(cur), spentByCategory(base));
    final savers = topSavers(deltas);
    final risers = topRisers(deltas);
    final spent = totalSpent(cur);
    final earned = incomes.fold<int>(0, (a, b) => a + b.amount);

    // Tagihan 7 hari ke depan (kartu + tagihan rutin).
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
    final upcoming = upcomingItems(
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
      ],
      now: now,
    );

    final moves = movesInCycle(
      household.budgetMoves,
      start: cycle.start,
      endExclusive: cycle.endExclusive,
    );
    final overCategory = _mostOverCategory(household, deltas);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: FtPageContainer(
          child: Column(
            children: [
              FtSubHeader(
                title: 'Money Date',
                trailing: Text(
                  'Langkah ${_step + 1}/4',
                  style: TextStyle(color: FtColors.ink3, fontSize: 12),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _StepScaffold(
                      eyebrow: 'Langkah 1 — Rayakan dulu',
                      title: savers.isEmpty
                          ? 'Siklus berjalan.'
                          : 'Ada yang berhasil dihemat!',
                      child: _CelebrateStep(
                        household: household,
                        savers: savers,
                        earned: earned,
                        spent: spent,
                      ),
                    ),
                    _StepScaffold(
                      eyebrow: 'Langkah 2 — Sorotan',
                      title: risers.isEmpty
                          ? 'Tidak ada lonjakan berarti.'
                          : 'Dua kategori naik paling banyak.',
                      child: _RisersStep(household: household, risers: risers),
                    ),
                    _StepScaffold(
                      eyebrow: 'Langkah 3 — Lihat ke depan',
                      title: upcoming.isEmpty
                          ? '7 hari ke depan aman.'
                          : 'Tagihan 7 hari ke depan.',
                      child: _UpcomingStep(items: upcoming),
                    ),
                    _StepScaffold(
                      eyebrow: 'Langkah 4 — Satu keputusan',
                      title: 'Cukup satu keputusan kecil.',
                      child: _DecisionStep(
                        household: household,
                        moves: moves,
                        overCategoryId: overCategory,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: i == _step ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? FtColors.clay
                              : FtColors.lineStrong,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _next,
                      child: Text(_step >= 3 ? 'Selesai' : 'Lanjut'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kategori paling kelebihan budget (target default tombol geser).
  String? _mostOverCategory(Household h, List<CategoryDelta> deltas) {
    String? worst;
    var worstGap = 0;
    for (final d in deltas) {
      final cat = h.categoryOf(d.id);
      if (cat == null || cat.archived || cat.monthlyBudget <= 0) continue;
      final gap = d.spend - cat.monthlyBudget;
      if (gap > worstGap) {
        worstGap = gap;
        worst = d.id;
      }
    }
    return worst;
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FtFadeUp(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CelebrateStep extends StatelessWidget {
  const _CelebrateStep({
    required this.household,
    required this.savers,
    required this.earned,
    required this.spent,
  });

  final Household household;
  final List<CategoryDelta> savers;
  final int earned;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final net = earned - spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in savers)
          _LineCard(
            color: FtColors.moss,
            icon: Icons.south_rounded,
            title: household.categoryOf(s.id)?.label ?? '-',
            detail:
                'Hemat ${Money.compact(-s.delta)} dibanding siklus lalu — pertahankan!',
            amount: s.spend,
          ),
        if (savers.isEmpty)
          Text(
            'Belum ada pembanding siklus lalu. Lanjut saja — yang penting rutinnya.',
            style: TextStyle(color: FtColors.ink3, fontSize: 13, height: 1.5),
          ),
        const SizedBox(height: 8),
        _LineCard(
          color: net >= 0 ? FtColors.sage : FtColors.ochre,
          icon: net >= 0
              ? Icons.account_balance_wallet_rounded
              : Icons.info_outline_rounded,
          title: net >= 0 ? 'Masih sisa' : 'Sementara defisit',
          detail: net >= 0
              ? 'Pemasukan ${Money.compact(earned)} − pengeluaran ${Money.compact(spent)}'
              : 'Wajar di tanggal tua — cek langkah berikutnya.',
          amount: net.abs(),
        ),
      ],
    );
  }
}

class _RisersStep extends StatelessWidget {
  const _RisersStep({required this.household, required this.risers});

  final Household household;
  final List<CategoryDelta> risers;

  @override
  Widget build(BuildContext context) {
    if (risers.isEmpty) {
      return Text(
        'Pengeluaran stabil dibanding siklus lalu.',
        style: TextStyle(color: FtColors.ink3, fontSize: 13),
      );
    }
    return Column(
      children: [
        for (final r in risers)
          _LineCard(
            color: FtColors.ochre,
            icon: Icons.north_rounded,
            title: household.categoryOf(r.id)?.label ?? '-',
            detail: r.baseline > 0
                ? '+${(r.delta * 100 / r.baseline).round()}% vs siklus lalu'
                : 'Baru muncul siklus ini',
            amount: r.spend,
          ),
        const SizedBox(height: 4),
        Text(
          'Bukan untuk menyalahkan — cukup tahu kenapa, lalu lanjut.',
          style: TextStyle(
              color: FtColors.ink4, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _UpcomingStep extends StatelessWidget {
  const _UpcomingStep({required this.items});

  final List<UpcomingItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Tidak ada jatuh tempo kartu atau tagihan rutin sampai minggu depan.',
        style: TextStyle(color: FtColors.ink3, fontSize: 13, height: 1.5),
      );
    }
    return Column(
      children: [
        for (final i in items)
          _LineCard(
            color: i.kind == UpcomingKind.cardDue
                ? FtColors.plum
                : FtColors.sky,
            icon: i.kind == UpcomingKind.cardDue
                ? Icons.credit_card_rounded
                : Icons.receipt_long_rounded,
            title: i.title,
            detail: i.kind == UpcomingKind.cardDue
                ? 'Jatuh tempo ${Dates.dayMonth(i.date)}'
                : 'Biasanya tanggal ${i.date.day} (±)',
            amount: i.amount,
          ),
      ],
    );
  }
}

class _DecisionStep extends ConsumerWidget {
  const _DecisionStep({
    required this.household,
    required this.moves,
    required this.overCategoryId,
  });

  final Household household;
  final List<BudgetMove> moves;
  final String? overCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canFull = ref.watch(canWriteAllProvider);
    final overCat =
        overCategoryId != null ? household.categoryOf(overCategoryId!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moves.isNotEmpty) ...[
          const Eyebrow('Pergeseran anggaran siklus ini'),
          const SizedBox(height: 8),
          for (final m in moves)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${prettyName(household.memberOf(m.by)?.displayName ?? 'Anggota')} '
                'menggeser ${Money.compact(m.amount)} dari '
                '${household.categoryOf(m.fromId)?.label ?? '-'} ke '
                '${household.categoryOf(m.toId)?.label ?? '-'} '
                '(${Dates.dayMonth(m.at)})',
                style: TextStyle(
                    color: FtColors.ink2, fontSize: 12, height: 1.4),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (overCat != null && canFull) ...[
          Text(
            '"${overCat.label}" paling melebihi anggaran. Mau geser sedikit dari kategori yang longgar?',
            style: TextStyle(color: FtColors.ink, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                BudgetMoveSheet.show(context, toId: overCat.id),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Geser anggaran'),
          ),
        ] else
          Text(
            'Anggaran aman. Boleh tutup money date — atau sepakati satu hal kecil untuk siklus depan.',
            style: TextStyle(color: FtColors.ink2, fontSize: 13, height: 1.5),
          ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String detail;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: color.withValues(alpha: 0.24), width: 0.5),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(amount),
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
