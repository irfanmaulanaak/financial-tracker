import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_analysis.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/health_score.dart';
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
        .map((e) => ExpenseRecord(
              amount: e.amount,
              categoryId: e.categoryId,
              spentBy: e.spentBy,
              date: e.date,
            ))
        .toList();
    final byCat = spentByCategory(records);
    final totalSpentValue = totalSpent(records);

    final avgPrev = prevCycles.isEmpty
        ? 0
        : prevCycles
                .map((window) => window.fold<int>(0, (a, b) => a + b.amount.toInt()))
                .fold<int>(0, (a, b) => a + b) ~/
            prevCycles.length;

    final assets = householdAssetsAndDebt(
        household,
        cards.map((c) => (limit: c.limit, used: c.used)));
    final score = computeHealthScore(HealthScoreInputs(
      spendThisCycle: totalSpentValue,
      incomeThisCycle: income,
      monthlyBudget: household.monthlyBudgetTotal,
      savingsBalance: assets.savingsBalance,
      cardDebt: assets.cardDebt,
      avgMonthlySpend: avgPrev,
      investmentCount: investments.where((i) => i.currentValue > 0).length,
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Insight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HealthCard(score: score),
          const SizedBox(height: 16),
          Text('Distribusi pengeluaran',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SpendDonut(totals: byCat, categories: household.categories),
          const SizedBox(height: 8),
          _Legend(totals: byCat, categories: household.categories),
          const SizedBox(height: 24),
          Text('Analisis per kategori',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._buildAnalyses(household.categories, cycleExpenses, prevCycles),
        ],
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
      byCatCurrent.update(e.categoryId, (v) => v + e.amount,
          ifAbsent: () => e.amount);
    }
    final history = <String, List<int>>{};
    for (final window in previousWindows) {
      final totals = <String, int>{};
      for (final e in window) {
        totals.update(e.categoryId, (v) => v + e.amount,
            ifAbsent: () => e.amount);
      }
      // Use a fresh union of categories appearing in any window OR current.
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

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.score});
  final HealthScore score;

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 65) return const Color(0xFF22C55E);
    if (s >= 50) return const Color(0xFFF59E0B);
    if (s >= 30) return const Color(0xFFEF4444);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score.score);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${score.score}',
                  style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1)),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('/100',
                        style: TextStyle(color: color, fontSize: 14)),
                    Text(score.verdict,
                        style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final f in score.factors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(f.label, style: const TextStyle(fontSize: 12))),
                  if (f.contribution == null)
                    Text('—',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                  else
                    Text('${f.contribution} / ${f.weight}',
                        style: const TextStyle(fontSize: 12)),
                ],
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
                style: const TextStyle(fontSize: 12)),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(label),
        subtitle: Text(analysis.historicalAverage > 0
            ? 'Sekarang ${Money.format(analysis.currentSpend)} • rata-rata ${Money.format(analysis.historicalAverage)}'
            : Money.format(analysis.currentSpend)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(analysis.verdict,
              style: TextStyle(color: color, fontSize: 12)),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
