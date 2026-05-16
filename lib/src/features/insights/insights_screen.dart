import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_analysis.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/health_score.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../cards/cards_screen.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household_providers.dart';
import '../investments/investments_screen.dart';
import 'insights_providers.dart';
import 'spend_donut.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cycleExpensesAsync = ref.watch(cycleExpensesProvider);
    final prevAsync = ref.watch(previousCyclesExpensesProvider(3));
    final income = ref.watch(currentCycleIncomeTotalProvider);
    final cardsAsync = ref.watch(cardsProvider(household.id));
    final investmentsAsync = ref.watch(investmentsProvider(household.id));

    final cycleExpenses = cycleExpensesAsync.value ?? const <Expense>[];
    final prevCycles = prevAsync.value ?? const <List<Expense>>[];
    final cards = cardsAsync.value ?? const [];
    final investments = investmentsAsync.value ?? const [];

    final records = cycleExpenses
        .map(
          (e) => ExpenseRecord(
            amount: e.amount,
            categoryId: e.categoryId,
            spentBy: e.spentBy,
            date: e.date,
          ),
        )
        .toList();
    final byCat = spentByCategory(records);
    final totalSpentValue = totalSpent(records);

    final avgPrev = prevCycles.isEmpty
        ? 0
        : prevCycles
                  .map(
                    (window) =>
                        window.fold<int>(0, (a, b) => a + b.amount.toInt()),
                  )
                  .fold<int>(0, (a, b) => a + b) ~/
              prevCycles.length;

    final assets = householdAssetsAndDebt(
      household,
      cards.map((c) => (limit: c.limit, used: c.used)),
    );
    final score = computeHealthScore(
      HealthScoreInputs(
        spendThisCycle: totalSpentValue,
        incomeThisCycle: income,
        monthlyBudget: household.monthlyBudgetTotal,
        savingsBalance: assets.savingsBalance,
        cardDebt: assets.cardDebt,
        avgMonthlySpend: avgPrev,
        investmentCount: investments.where((i) => i.currentValue > 0).length,
      ),
    );

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.home,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const FtSubHeader(title: 'Kesehatan Finansial'),
            _HealthHero(score: score),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Eyebrow('Distribusi Pengeluaran'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: cycleExpensesAsync.isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        SpendDonut(
                            totals: byCat, categories: household.categories),
                        const SizedBox(height: 12),
                        _Legend(
                            totals: byCat, categories: household.categories),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Eyebrow('Komponen Skor'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < score.factors.length; i++) ...[
                    if (i > 0) const Divider(),
                    _FactorRow(factor: score.factors[i]),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Eyebrow('Analisis Per Kategori'),
            ),
            ..._buildAnalyses(household.categories, cycleExpenses, prevCycles),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnalyses(
    List<dynamic> cats,
    List<Expense> current,
    List<List<Expense>> previousWindows,
  ) {
    if (cats.isEmpty) return const [];
    final byCatCurrent = <String, int>{};
    for (final e in current) {
      byCatCurrent.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }
    final history = <String, List<int>>{};
    for (final window in previousWindows) {
      final totals = <String, int>{};
      for (final e in window) {
        totals.update(
          e.categoryId,
          (v) => v + e.amount,
          ifAbsent: () => e.amount,
        );
      }
      for (final c in cats) {
        history.putIfAbsent(c.id, () => []).add(totals[c.id] ?? 0);
      }
    }
    final out = <Widget>[];
    for (final c in cats) {
      final cur = byCatCurrent[c.id] ?? 0;
      final analysis = analyseCategory(
        categoryId: c.id,
        currentSpend: cur,
        previousSpends: history[c.id] ?? const [],
      );
      if (analysis.verdict == 'Tidak ada pengeluaran' &&
          analysis.historicalAverage == 0) {
        continue;
      }
      out.add(_AnalysisTile(label: c.label, analysis: analysis));
    }
    return out;
  }
}

class _HealthHero extends StatelessWidget {
  const _HealthHero({required this.score});
  final HealthScore score;

  Color _stateColor(String state) => switch (state) {
    'good' => FtColors.healthOk,
    'caution' => FtColors.healthWarn,
    'risk' => FtColors.healthBad,
    _ => FtColors.healthOk,
  };

  String _stateLabel(String state) => switch (state) {
    'good' => 'Sehat',
    'caution' => 'Perhatian',
    'risk' => 'Berisiko',
    _ => 'Sehat',
  };

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(score.score >= 80 ? 'good' : score.score >= 50 ? 'caution' : 'risk');
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Traffic light visual
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FtColors.line),
                ),
                child: Column(
                  children: [
                    _Light(color: FtColors.healthOk, on: score.score >= 80),
                    const SizedBox(height: 8),
                    _Light(color: FtColors.healthWarn, on: score.score >= 50 && score.score < 80),
                    const SizedBox(height: 8),
                    _Light(color: FtColors.healthBad, on: score.score < 50),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Status Bulan Ini'),
                    Text(
                      _stateLabel(score.score >= 80 ? 'good' : score.score >= 50 ? 'caution' : 'risk'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${score.score}',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 44, height: 1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ 100',
                          style: TextStyle(color: FtColors.ink3, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Text(
              score.verdict,
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  const _Light({required this.color, required this.on});
  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: on ? color : color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: on
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});
  final HealthFactor factor;

  Color _factorColor(double? raw) {
    if (raw == null) return FtColors.ink4;
    if (raw >= 0.7) return FtColors.healthOk;
    if (raw >= 0.4) return FtColors.healthWarn;
    return FtColors.healthBad;
  }

  @override
  Widget build(BuildContext context) {
    final color = _factorColor(factor.rawScore01);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (factor.rawScore01 ?? 0).toDouble(),
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: FtColors.line,
                ),
                Text(
                  factor.contribution != null ? '${factor.contribution}' : '—',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (factor.rawScore01 != null)
                  Text(
                    '${(factor.rawScore01! * 100).round()}% dari target',
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${factor.weight}%',
            style: TextStyle(
              color: FtColors.ink4,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.totals, required this.categories});
  final Map<String, int> totals;
  final List<dynamic> categories;

  @override
  Widget build(BuildContext context) {
    final grand = totals.values.fold<int>(0, (a, b) => a + b);
    if (grand == 0) return const SizedBox.shrink();
    final byId = {for (final c in categories) c.id: c};
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: entries.take(8).map((e) {
        final cat = byId[e.key];
        final share = e.value / grand;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: cat != null ? _parseColor(cat.color) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat?.label ?? '-'}: ${(share * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  const _AnalysisTile({required this.label, required this.analysis});
  final String label;
  final CategoryAnalysis analysis;

  Color _verdictColor(String v) => switch (v) {
    'Sangat boros' => const Color(0xFFDC2626),
    'Boros' => const Color(0xFFEF4444),
    'Stabil' => const Color(0xFF64748B),
    'Lebih hemat' => const Color(0xFF10B981),
    _ => const Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(analysis.verdict);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          analysis.historicalAverage > 0
              ? 'Sekarang ${Money.format(analysis.currentSpend)} • rata-rata ${Money.format(analysis.historicalAverage)}'
              : Money.format(analysis.currentSpend),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            analysis.verdict,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
