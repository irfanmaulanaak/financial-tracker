import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_donut.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import 'budget_edit_sheet.dart';
import 'spend_activity_list.dart';

/// "Pengeluaran Bulanan" — donut + category breakdown drilldown.
/// Mirrors `claude-design/screens-deep.jsx` `SpendScreen`. Tapping a category
/// row navigates to that category's detail page.
class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  /// `null` = current cycle, otherwise index into the previous-cycles list.
  int? _prevIndex;
  String? _focusedCategoryId;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cycleAsync = ref.watch(cycleExpensesProvider);
    final prevAsync = ref.watch(previousCyclesExpensesProvider(3));
    final cycleExpenses = cycleAsync.value ?? const <Expense>[];
    final prevCycles = prevAsync.value ?? const <List<Expense>>[];

    final List<Expense> active = _prevIndex == null
        ? cycleExpenses
        : (prevCycles.length > _prevIndex! ? prevCycles[_prevIndex!] : const []);

    final records = [
      for (final e in active)
        ExpenseRecord(
          amount: e.amount,
          categoryId: e.categoryId,
          spentBy: e.spentBy,
          date: e.date,
        ),
    ];
    // Total + donut count consumption only; investment-category expenses
    // are surfaced separately (note under the total + activity list).
    final spendRecords =
        consumptionOnly(records, household.investmentCategoryIds);
    final total = totalSpent(spendRecords);
    final invested = totalSpent(records) - total;
    final byCat = spentByCategory(spendRecords);
    final categories = household.categories
        .where((c) => !c.archived)
        .toList()
      ..sort((a, b) {
        final sa = byCat[a.id] ?? 0;
        final sb = byCat[b.id] ?? 0;
        if (sa != sb) return sb.compareTo(sa);
        return a.sortOrder.compareTo(b.sortOrder);
      });

    final focused = _focusedCategoryId == null
        ? null
        : categories.firstWhere(
            (c) => c.id == _focusedCategoryId,
            orElse: () => categories.first,
          );
    final focusedAmount =
        focused == null ? null : (byCat[focused.id] ?? 0);

    // Date-range labels for the period chips, walking back from the current
    // cycle start the same way `previousCyclesExpensesProvider` builds its
    // windows (index 0 = most recent previous cycle).
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    final cycleRanges = <String>[];
    var cursor = cycle.start;
    for (var i = 0; i < prevCycles.length; i++) {
      final prevStart =
          resolvePayday(cursor.year, cursor.month - 1, household.payday);
      cycleRanges.add(Dates.cycleRange(prevStart, cursor));
      cursor = prevStart;
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.spend,
        child: FtRefreshable(
          onRefresh: () async {
            ref.invalidate(currentHouseholdProvider);
            ref.invalidate(cycleExpensesProvider);
            ref.invalidate(previousCyclesExpensesProvider);
            await ftRefreshDelay();
          },
          child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const FtSubHeader(title: 'Pengeluaran Bulanan'),
            _Hero(
              total: total,
              displayAmount: focusedAmount ?? total,
              invested: invested,
              caption: focused != null
                  ? focused.label
                  : 'Total ${categories.length} kategori aktif',
              segments: [
                for (final c in categories.where((c) => (byCat[c.id] ?? 0) > 0))
                  FtDonutSegment(
                    value: (byCat[c.id] ?? 0).toDouble(),
                    color: parseColor(c.color),
                  ),
              ],
              prevIndex: _prevIndex,
              cycleRanges: cycleRanges,
              onPick: (i) {
                setState(() {
                  _prevIndex = i;
                  _focusedCategoryId = null;
                });
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
              child: Eyebrow('Rincian Kategori'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (categories.where((c) => (byCat[c.id] ?? 0) > 0).isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        'Belum ada pengeluaran pada periode ini.',
                        style: TextStyle(color: FtColors.ink3, fontSize: 12),
                      ),
                    )
                  else
                    for (var i = 0;
                        i < categories.length;
                        i++) ...[
                      if ((byCat[categories[i].id] ?? 0) <= 0)
                        const SizedBox.shrink()
                      else ...[
                        if (i > 0) const Divider(height: 1),
                        _CategoryRow(
                          category: categories[i],
                          spent: byCat[categories[i].id] ?? 0,
                          total: total,
                          focused:
                              _focusedCategoryId == categories[i].id,
                          canEditBudget:
                              ref.watch(canRecordTxnProvider),
                          onTap: () =>
                              context.push('/categories/${categories[i].id}'),
                          onEditBudget: () => BudgetEditSheet.show(
                            context: context,
                            category: categories[i],
                          ),
                          onHover: (entered) => setState(() {
                            _focusedCategoryId =
                                entered ? categories[i].id : null;
                          }),
                        ),
                      ],
                    ],
                ],
              ),
            ),
            SpendActivityList(expenses: active, household: household),
          ],
        ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.total,
    required this.displayAmount,
    required this.invested,
    required this.caption,
    required this.segments,
    required this.prevIndex,
    required this.cycleRanges,
    required this.onPick,
  });
  final int total;
  final int displayAmount;

  /// Investment-category spend this period — shown as a note, not counted
  /// in [total].
  final int invested;
  final String caption;
  final List<FtDonutSegment> segments;
  final int? prevIndex;

  /// Compact "25 Apr–24 Mei" labels, index 0 = most recent previous cycle.
  final List<String> cycleRanges;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(_periodLabel(prevIndex)),
                    const SizedBox(height: 4),
                    FtFadeUp(
                      duration: const Duration(milliseconds: 360),
                      distance: 6,
                      child: Text(
                        compactMoney(displayAmount),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontSize: 30, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style:
                          TextStyle(color: FtColors.ink3, fontSize: 11),
                    ),
                    if (invested > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${compactMoney(invested)} ke investasi '
                        '(tidak dihitung)',
                        style: TextStyle(
                          color: FtColors.moss,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FtDonut(segments: segments, size: 116, thickness: 14),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: FtColors.line, height: 1),
          const SizedBox(height: 12),
          _PeriodPicker(
            prevIndex: prevIndex,
            cycleRanges: cycleRanges,
            onPick: onPick,
          ),
        ],
      ),
    );
  }

  String _periodLabel(int? idx) {
    if (idx == null) return 'Siklus berjalan · Total';
    final range = idx < cycleRanges.length ? ' (${cycleRanges[idx]})' : '';
    return '${idx + 1} siklus lalu$range · Total';
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.prevIndex,
    required this.cycleRanges,
    required this.onPick,
  });
  final int? prevIndex;
  final List<String> cycleRanges;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    // Render oldest → newest: prev2, prev1, prev0, current.
    final options = <(int?, String)>[
      for (var i = cycleRanges.length - 1; i >= 0; i--) (i, cycleRanges[i]),
      (null, 'Sekarang'),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _PeriodChip(
              label: options[i].$2,
              active: options[i].$1 == prevIndex,
              onTap: () => onPick(options[i].$1),
            ),
          ),
          if (i != options.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
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
      scale: 0.97,
      onTap: active ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        // Date-range labels ("25 Apr–24 Mei") can outgrow a quarter-width
        // chip on phones; scale down instead of ellipsizing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: active ? FtColors.bg : FtColors.ink2,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.total,
    required this.focused,
    required this.canEditBudget,
    required this.onTap,
    required this.onEditBudget,
    required this.onHover,
  });
  final Category category;
  final int spent;
  final int total;
  final bool focused;
  final bool canEditBudget;
  final VoidCallback onTap;
  final VoidCallback onEditBudget;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : (spent / total) * 100;
    final budget = category.monthlyBudget;
    final overBudget = budget > 0 && spent > budget;
    final color = parseColor(category.color);
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: FtTapScale(
        scale: 0.99,
        haptic: false,
        onTap: onTap,
        child: Container(
          color: focused ? FtColors.surfaceAlt : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FtColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          compactMoney(spent),
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 10,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          overBudget
                              ? '+${(((spent / budget) - 1) * 100).round()}% vs anggaran'
                              : budget > 0
                                  ? 'dari ${Money.format(budget)}'
                                  : 'tanpa budget',
                          style: TextStyle(
                            color:
                                overBudget ? FtColors.danger : FtColors.ink3,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canEditBudget)
                _BudgetMenu(onEdit: onEditBudget)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: FtColors.ink4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetMenu extends StatelessWidget {
  const _BudgetMenu({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Aksi',
      icon: Icon(Icons.more_vert_rounded, size: 18, color: FtColors.ink3),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'budget') onEdit();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'budget',
          child: Text('Atur anggaran'),
        ),
      ],
    );
  }
}
