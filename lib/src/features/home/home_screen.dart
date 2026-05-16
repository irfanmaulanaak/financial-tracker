import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/health_score.dart';
import '../../core/in_app_indicators.dart';
import '../../core/net_worth.dart';
import '../../core/payday.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../goals/goal.dart';
import '../goals/goals_screen.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final cycleAsync = ref.watch(cycleExpensesProvider);
    final recentAsync = ref.watch(recentExpensesProvider(5));
    final user = ref.watch(authStateProvider).value;
    final household = householdAsync.value;
    final cardsAsync = household != null
        ? ref.watch(cardsProvider(household.id))
        : null;
    final goalsAsync = household != null
        ? ref.watch(goalsProvider(household.id))
        : null;
    final investmentsAsync = household != null
        ? ref.watch(investmentsProvider(household.id))
        : null;
    final prevAsync = household != null
        ? ref.watch(previousCyclesExpensesProvider(3))
        : null;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: householdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (household) {
          if (household == null) {
            return const Center(child: Text('Tidak ada rumah tangga.'));
          }

          final now = DateTime.now();
          final cycle = currentCycle(now, payday: household.payday);
          final expenses = cycleAsync.value ?? const <Expense>[];
          final records = [
            for (final e in expenses)
              ExpenseRecord(
                amount: e.amount,
                categoryId: e.categoryId,
                spentBy: e.spentBy,
                date: e.date,
              ),
          ];
          final totalSpentValue = totalSpent(records);
          final income = ref.watch(currentCycleIncomeTotalProvider);
          final byCat = spentByCategory(records);
          final daily = dailyBudget(
            monthlyBudget: income,
            cycleDays: cycleLengthDays(cycle),
          );
          final categories =
              household.categories.where((c) => !c.archived).toList()
                ..sort((a, b) {
                  final sa = byCat[a.id] ?? 0;
                  final sb = byCat[b.id] ?? 0;
                  if (sa != sb) return sb.compareTo(sa);
                  return a.sortOrder.compareTo(b.sortOrder);
                });

          final cards = cardsAsync?.value ?? const <CreditCard>[];
          final goals = goalsAsync?.value ?? const <Goal>[];
          final investments = investmentsAsync?.value ?? const <Investment>[];
          final prevCycles = prevAsync?.value ?? const <List<Expense>>[];
          final avgPrev = prevCycles.isEmpty
              ? 0
              : prevCycles
                        .map((w) => w.fold<int>(0, (a, b) => a + b.amount))
                        .fold<int>(0, (a, b) => a + b) ~/
                    prevCycles.length;
          final nw = computeNetWorth(
            cash: [
              for (final a in household.cashAccounts)
                AccountBalance(id: a.id, label: a.label, value: a.value),
            ],
            savings: [
              for (final a in household.savingsAccounts)
                AccountBalance(id: a.id, label: a.label, value: a.value),
            ],
            cards: [
              for (final c in cards)
                CardBalance(
                  id: c.id,
                  label: c.label,
                  limit: c.limit,
                  used: c.used,
                ),
            ],
          );
          final assets = householdAssetsAndDebt(
            household,
            cards.map((c) => (limit: c.limit, used: c.used)),
          );
          final health = computeHealthScore(
            HealthScoreInputs(
              spendThisCycle: totalSpentValue,
              incomeThisCycle: income,
              monthlyBudget: household.monthlyBudgetTotal,
              savingsBalance: assets.savingsBalance,
              cardDebt: assets.cardDebt,
              avgMonthlySpend: avgPrev,
              investmentCount: investments
                  .where((i) => i.currentValue > 0)
                  .length,
            ),
          );
          final status = budgetStatus(
            totalSpent: totalSpentValue,
            monthlyBudget: income,
          );
          final dueBanners = [
            for (final c in cards)
              if (daysUntilDue(dueDay: c.dueDay, now: now) case final d?)
                if (c.used > 0)
                  _DueBanner(cardLabel: c.label, daysUntil: d, used: c.used),
          ];

          return FtAppChrome(
            current: FtTab.home,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                _HomeHeader(
                  household: household,
                  displayName: user?.displayName?.trim().isNotEmpty == true
                      ? user!.displayName!
                      : user?.email?.split('@').first ?? 'Keluarga',
                  onMembers: () => context.push('/members'),
                  onSelected: (v) => _handleMenu(context, ref, v),
                ),
                _AssetHero(nw: nw, onTap: () => context.push('/accounts')),
                _AssetBreakdown(nw: nw, onTap: () => context.push('/accounts')),
                if (status != BudgetStatus.ok) _BudgetBanner(status: status),
                for (final banner in dueBanners) banner,
                _MonthStrip(
                  totalSpent: totalSpentValue,
                  income: income,
                  daily: daily,
                  cycleStart: cycle.start,
                  cycleEndExclusive: cycle.endExclusive,
                  onAdd: () => context.push('/expenses/new'),
                ),
                _CardsPreview(
                  cards: cards,
                  onTap: () => context.push('/cards'),
                ),
                _HealthSnapshot(
                  score: health,
                  onTap: () => context.push('/insights'),
                ),
                _CategoryGrid(
                  categories: categories.take(4).toList(),
                  totals: byCat,
                  onTap: () => context.push('/expenses'),
                ),
                _GoalsPreview(
                  goals: goals,
                  onTap: () => context.push('/goals'),
                ),
                _RecentList(
                  recentAsync: recentAsync,
                  household: household,
                  onTap: () => context.push('/expenses'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleMenu(BuildContext context, WidgetRef ref, String v) {
    switch (v) {
      case 'insights':
        context.push('/insights');
      case 'goals':
        context.push('/goals');
      case 'investments':
        context.push('/investments');
      case 'members':
        context.push('/members');
      case 'categories':
        context.push('/categories');
      case 'accounts':
        context.push('/accounts');
      case 'cards':
        context.push('/cards');
      case 'incomes':
        context.push('/incomes');
      case 'export':
        context.push('/export');
      case 'signout':
        ref.read(authRepositoryProvider).signOut();
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.household,
    required this.displayName,
    required this.onMembers,
    required this.onSelected,
  });

  final Household household;
  final String displayName;
  final VoidCallback onMembers;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 52, 16, 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: FtColors.surfaceAlt,
            foregroundColor: FtColors.ink,
            child: Text(
              _initials(displayName),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  household.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 17,
                    color: FtColors.ink,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onMembers,
            child: SizedBox(
              width: 74,
              height: 30,
              child: Stack(
                children: [
                  for (var i = 0; i < household.members.take(3).length; i++)
                    Positioned(
                      left: i * 20,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: _parseColor(
                          household.members[i].color,
                        ),
                        foregroundColor: Colors.white,
                        child: Text(
                          _initials(household.members[i].displayName),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: onSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'insights', child: Text('Insight')),
              PopupMenuItem(value: 'goals', child: Text('Tujuan')),
              PopupMenuItem(value: 'investments', child: Text('Investasi')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'accounts', child: Text('Akun')),
              PopupMenuItem(value: 'cards', child: Text('Kartu kredit')),
              PopupMenuItem(value: 'incomes', child: Text('Pemasukan')),
              PopupMenuItem(value: 'categories', child: Text('Kategori')),
              PopupMenuItem(value: 'members', child: Text('Anggota')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'export', child: Text('Ekspor data')),
              PopupMenuItem(value: 'signout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetHero extends StatelessWidget {
  const _AssetHero({required this.nw, required this.onTap});

  final NetWorth nw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Total Aset'),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: _moneyNoSymbol(nw.total),
                children: const [
                  TextSpan(
                    text: ' IDR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: FtColors.ink3,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 46, height: 1),
            ),
            const SizedBox(height: 14),
            Text(
              'Tunai + tabungan dikurangi utang kartu',
              style: const TextStyle(color: FtColors.ink3, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetBreakdown extends StatelessWidget {
  const _AssetBreakdown({required this.nw, required this.onTap});

  final NetWorth nw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          _BreakdownRow('Tunai', 'rekening siap pakai', nw.cash, FtColors.sky),
          const Divider(),
          _BreakdownRow(
            'Tabungan',
            'dana tersimpan',
            nw.savings,
            FtColors.moss,
          ),
          const Divider(),
          _BreakdownRow(
            'Utang kartu',
            'mengurangi aset',
            -nw.debt,
            FtColors.plum,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.label, this.hint, this.value, this.color);

  final String label;
  final String hint;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            _compactMoney(value),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({
    required this.totalSpent,
    required this.income,
    required this.daily,
    required this.cycleStart,
    required this.cycleEndExclusive,
    required this.onAdd,
  });

  final int totalSpent;
  final int income;
  final int daily;
  final DateTime cycleStart;
  final DateTime cycleEndExclusive;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final hasIncome = income > 0;
    final pctLabel = hasIncome ? (totalSpent / income * 100).round() : 0;
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(
                      'Pengeluaran · ${Dates.short(cycleStart)} - ${Dates.short(cycleEndExclusive.subtract(const Duration(days: 1)))}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _compactMoney(totalSpent),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasIncome
                          ? 'dari ${_compactMoney(income)} pendapatan'
                          : 'Belum ada pemasukan tercatat',
                      style: const TextStyle(
                        color: FtColors.ink3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: FtColors.ink,
                  foregroundColor: FtColors.bg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FtProgressBar(
            value: totalSpent,
            max: hasIncome ? income : 1,
            color: totalSpent > income && hasIncome
                ? FtColors.danger
                : FtColors.clay,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasIncome
                      ? '$pctLabel% pendapatan terpakai'
                      : 'Catat pemasukan untuk lihat rasio',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ),
              if (hasIncome)
                Text(
                  'Harian ${_compactMoney(daily)}',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardsPreview extends StatelessWidget {
  const _CardsPreview({required this.cards, required this.onTap});

  final List<CreditCard> cards;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final used = cards.fold<int>(0, (a, b) => a + b.used);
    final limit = cards.fold<int>(0, (a, b) => a + b.limit);
    final minPay = cards.fold<int>(
      0,
      (a, b) =>
          a + minimumPayment(balance: b.used, minPaymentPct: b.minPaymentPct),
    );
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Kartu Kredit · Utang'),
          const SizedBox(height: 8),
          Text(
            _compactMoney(used),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'akumulasi tagihan',
            style: const TextStyle(color: FtColors.ink3, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FtProgressBar(
            value: used,
            max: limit <= 0 ? 1 : limit,
            color: FtColors.plum,
          ),
          const SizedBox(height: 14),
          FtStatGrid(
            items: [
              FtStatItem(label: 'Limit total', value: _compactMoney(limit)),
              FtStatItem(label: 'Min. bayar', value: _compactMoney(minPay)),
              FtStatItem(label: 'Kartu aktif', value: '${cards.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthSnapshot extends StatelessWidget {
  const _HealthSnapshot({required this.score, required this.onTap});

  final HealthScore score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(score.score);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score.score / 100,
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: FtColors.line,
                ),
                Text(
                  '${score.score}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Kesehatan Finansial'),
                const SizedBox(height: 4),
                Text(
                  score.verdict,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  _bestHealthSummary(score),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FtColors.ink2, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FtColors.ink4),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.totals,
    required this.onTap,
  });

  final List<Category> categories;
  final Map<String, int> totals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        FtSectionHeader(
          title: 'Pengeluaran Bulan Ini',
          actionLabel: 'Lihat semua',
          onAction: onTap,
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              for (final c in categories)
                _CategoryCell(category: c, spent: totals[c.id] ?? 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({required this.category, required this.spent});

  final Category category;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);
    final budget = category.monthlyBudget;
    final pct = budget > 0 ? (spent / budget * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtColors.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(category.icon), size: 15, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FtColors.ink2,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            _compactMoney(spent),
            style: const TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FtProgressBar(
            value: spent,
            max: budget <= 0 ? 1 : budget,
            color: color,
            height: 3,
          ),
          const SizedBox(height: 5),
          Text(
            budget > 0 ? '$pct% terpakai' : 'tanpa budget',
            style: TextStyle(
              color: budget > 0 && spent > budget
                  ? FtColors.danger
                  : FtColors.ink3,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsPreview extends StatelessWidget {
  const _GoalsPreview({required this.goals, required this.onTap});

  final List<Goal> goals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                const Expanded(child: Eyebrow('Tujuan Finansial')),
                Text(
                  '${goals.length} aktif',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          for (final g in goals.take(3)) _GoalPreviewRow(goal: g),
        ],
      ),
    );
  }
}

class _GoalPreviewRow extends StatelessWidget {
  const _GoalPreviewRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(goal.color);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(_goalIconFor(goal.icon), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FtColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(goal.progress * 100).round()}%',
                      style: const TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                FtProgressBar(
                  value: goal.current,
                  max: goal.target,
                  color: color,
                  height: 3,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_compactMoney(goal.current)} / ${_compactMoney(goal.target)}',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.recentAsync,
    required this.household,
    required this.onTap,
  });

  final AsyncValue<List<Expense>> recentAsync;
  final Household household;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                const Expanded(child: Eyebrow('Aktivitas Terbaru')),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          ...recentAsync.maybeWhen(
            data: (recent) => recent.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
                      child: Text(
                        'Belum ada pengeluaran.',
                        style: TextStyle(color: FtColors.ink3, fontSize: 12),
                      ),
                    ),
                  ]
                : [
                    for (final e in recent)
                      _RecentExpenseRow(
                        expense: e,
                        category: household.categoryOf(e.categoryId),
                        spender: household.memberOf(e.spentBy),
                      ),
                  ],
            orElse: () => const [
              Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseRow extends StatelessWidget {
  const _RecentExpenseRow({
    required this.expense,
    required this.category,
    required this.spender,
  });

  final Expense expense;
  final Category? category;
  final Member? spender;

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? _parseColor(category!.color)
        : FtColors.ink3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(
              _iconFor(category?.icon ?? 'category'),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.label ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FtColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    Dates.short(expense.date),
                    if (spender != null) spender!.displayName,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            _compactMoney(expense.amount),
            style: const TextStyle(
              color: FtColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetBanner extends StatelessWidget {
  const _BudgetBanner({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final exceeded = status == BudgetStatus.exceeded;
    final color = exceeded ? FtColors.danger : FtColors.ochre;
    final msg = exceeded
        ? 'Pengeluaran sudah melampaui pendapatan siklus ini.'
        : 'Sudah 80% dari pendapatan siklus ini.';
    return _AlertBand(
      icon: Icons.warning_amber_rounded,
      color: color,
      text: msg,
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({
    required this.cardLabel,
    required this.daysUntil,
    required this.used,
  });

  final String cardLabel;
  final int daysUntil;
  final int used;

  @override
  Widget build(BuildContext context) {
    final urgent = daysUntil <= 0;
    final text = urgent
        ? '$cardLabel jatuh tempo hari ini · ${_compactMoney(used)}'
        : '$cardLabel jatuh tempo $daysUntil hari lagi · ${_compactMoney(used)}';
    return _AlertBand(
      icon: Icons.credit_card_rounded,
      color: urgent ? FtColors.danger : FtColors.sage,
      text: text,
    );
  }
}

class _AlertBand extends StatelessWidget {
  const _AlertBand({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.26), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compactMoney(num value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs >= 1000000000) {
    return '${sign}Rp${_trim(abs / 1000000000)} M';
  }
  if (abs >= 1000000) {
    return '${sign}Rp${_trim(abs / 1000000)} jt';
  }
  if (abs >= 1000) return '${sign}Rp${(abs / 1000).round()} rb';
  return '$sign${Money.format(abs)}';
}

String _moneyNoSymbol(num value) => Money.format(value).replaceFirst('Rp', '');

String _trim(num n) {
  final s = n.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final text = parts.take(2).map((p) => p[0]).join();
  return text.isEmpty ? 'FT' : text.toUpperCase();
}

String _bestHealthSummary(HealthScore score) {
  final available = score.factors.where((f) => f.contribution != null).toList()
    ..sort((a, b) => (a.contribution ?? 0).compareTo(b.contribution ?? 0));
  if (available.isEmpty) return 'Data belum cukup untuk membaca pola.';
  return '${available.first.label} paling perlu perhatian.';
}

Color _healthColor(int s) {
  if (s >= 65) return FtColors.sage;
  if (s >= 50) return FtColors.ochre;
  return FtColors.danger;
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData _iconFor(String name) => switch (name) {
  'restaurant' => Icons.restaurant,
  'receipt_long' => Icons.receipt_long,
  'shopping_bag' => Icons.shopping_bag,
  'directions_car' => Icons.directions_car,
  'movie' => Icons.movie,
  'favorite' => Icons.favorite,
  'school' => Icons.school,
  'sports_esports' => Icons.sports_esports,
  _ => Icons.category,
};

IconData _goalIconFor(String name) => switch (name) {
  'savings' => Icons.savings,
  'flight' => Icons.flight_takeoff,
  'home' => Icons.home,
  'school' => Icons.school,
  'directions_car' => Icons.directions_car,
  'celebration' => Icons.celebration,
  _ => Icons.flag,
};
