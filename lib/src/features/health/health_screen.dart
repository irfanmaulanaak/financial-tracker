import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/expense_aggregations.dart';
import '../../core/health_score.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ring.dart';
import '../../ui/ft_ui.dart';
import '../cards/cards_screen.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import '../investments/investments_repository.dart' show investmentsProvider;
import '../obligations/obligation_repository.dart' show obligationsProvider;
import 'widgets/health_findings.dart';
import 'widgets/health_hero.dart';
import 'widgets/health_recommendations.dart';

/// `/health` — full-screen kesehatan-finansial detector. Vertical traffic
/// light hero, factor breakdown, spending findings, recommendations.
/// Mirrors `HealthScreen` in `claude-design/screens-rest.jsx`.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

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
    // Consumption only — investment-category expenses don't count as spend.
    final invCatIds = household.investmentCategoryIds;
    final totalSpentValue = totalSpent(consumptionOnly(records, invCatIds));

    final avgPrev = prevCycles.isEmpty
        ? 0
        : prevCycles
                .map((w) => w
                    .where((e) => !invCatIds.contains(e.categoryId))
                    .fold<int>(0, (a, b) => a + b.amount))
                .fold<int>(0, (a, b) => a + b) ~/
            prevCycles.length;

    final assets = householdAssetsAndDebt(
      household,
      // True obligation (incl. unbilled cicilan), matching home/net worth.
      cards.map((c) => (limit: c.limit, used: c.outstanding)),
    );
    final obligationsPrincipal =
        (ref.watch(obligationsProvider).value ?? const [])
            .where((o) => o.isDebt)
            .fold<int>(0, (a, o) => a + (o.outstandingPrincipal ?? 0));
    final score = computeHealthScore(
      HealthScoreInputs(
        spendThisCycle: totalSpentValue,
        incomeThisCycle: income,
        monthlyBudget: household.monthlyBudgetTotal,
        savingsBalance: assets.savingsBalance,
        cardDebt: assets.cardDebt + obligationsPrincipal,
        avgMonthlySpend: avgPrev,
        investmentCount:
            investments.where((i) => i.currentValue > 0).length,
      ),
    );

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtRefreshable(
        onRefresh: () async {
          ref.invalidate(currentHouseholdProvider);
          ref.invalidate(cycleExpensesProvider);
          ref.invalidate(previousCyclesExpensesProvider);
          ref.invalidate(cardsProvider(household.id));
          ref.invalidate(investmentsProvider(household.id));
          await ftRefreshDelay();
        },
        child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const FtSubHeader(title: 'Kesehatan Finansial'),
          HealthHero(score: score),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
            child: Eyebrow('Komponen Skor'),
          ),
          FtCard(
            heroTag: 'ft-kesehatan-hero',
            margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < score.factors.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _FactorRow(factor: score.factors[i]),
                ],
              ],
            ),
          ),
          HealthFindings(
            // Investment categories aren't spending behaviour — keep them
            // out of the boros/hemat verdicts.
            categories: household.categories
                .where((c) => !c.isInvestment)
                .toList(),
            current: cycleExpenses,
            previousWindows: prevCycles,
            onTap: (catId) => context.push('/categories/$catId'),
          ),
          HealthRecommendations(
            score: score,
            cardDebt: assets.cardDebt,
            savingsBalance: assets.savingsBalance,
            investmentCount:
                investments.where((i) => i.currentValue > 0).length,
            onRoute: (route) => context.push(route),
          ),
        ],
      ),
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

  String _noteFor(HealthFactor f) {
    if (f.rawScore01 == null) return 'Data belum cukup.';
    final pct = (f.rawScore01! * 100).round();
    return '$pct% dari target ideal';
  }

  @override
  Widget build(BuildContext context) {
    final color = _factorColor(factor.rawScore01);
    return FtFadeUp(
      duration: const Duration(milliseconds: 280),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            FtRing(
              value: (factor.rawScore01 ?? 0).toDouble(),
              max: 1,
              size: 42,
              thickness: 4,
              color: color,
              child: Text(
                factor.contribution != null ? '${factor.contribution}' : '—',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
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
                          factor.label,
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        factor.contribution != null
                            ? '${factor.contribution}'
                            : '—',
                        style: TextStyle(
                          color: FtColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _noteFor(factor),
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${factor.weight}%',
              style: TextStyle(color: FtColors.ink4, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
