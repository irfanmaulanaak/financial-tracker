import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health_score.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_motion.dart';
import '../../../ui/ft_ui.dart';
import '../../cards/credit_card.dart';
import '../../expenses/expense.dart';
import '../../expenses/expense_providers.dart';
import '../../goals/goal.dart';
import '../../household/household.dart';
import 'cards_preview.dart';
import 'category_grid.dart';
import 'goals_preview.dart';
import 'home_formatters.dart';
import 'home_header.dart';
import 'mini_donut.dart';
import 'recent_list.dart';
import 'sparkline.dart';

/// Compact "Padat" home variant from `claude-design/screens-home.jsx` `HomeB`.
/// Denser hero with sparkline + small donut + 3-col breakdown; side-by-side
/// spend/health cards; otherwise reuses the same section primitives as HomeA.
class HomeBBody extends ConsumerWidget {
  const HomeBBody({
    super.key,
    required this.household,
    required this.displayName,
    required this.nw,
    required this.totalSpent,
    required this.income,
    required this.health,
    required this.cards,
    required this.goals,
    required this.categories,
    required this.totalsByCat,
    required this.onMembers,
    required this.onMenuSelect,
    required this.onAssets,
    required this.onExpenses,
    required this.onCards,
    required this.onGoals,
    required this.onInsights,
  });

  final Household household;
  final String displayName;
  final NetWorth nw;
  final int totalSpent;
  final int income;
  final HealthScore health;
  final List<CreditCard> cards;
  final List<Goal> goals;
  final List<Category> categories;
  final Map<String, int> totalsByCat;
  final VoidCallback onMembers;
  final ValueChanged<String> onMenuSelect;
  final VoidCallback onAssets;
  final VoidCallback onExpenses;
  final VoidCallback onCards;
  final VoidCallback onGoals;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentExpensesProvider(3));
    Widget section(Widget child, {int index = 0}) => FtFadeUp(
          duration: const Duration(milliseconds: 340),
          delay: Duration(milliseconds: index * 60),
          distance: 10,
          child: child,
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        section(
          HomeHeader(
            household: household,
            displayName: displayName,
            onMembers: onMembers,
            onSelected: onMenuSelect,
          ),
          index: 0,
        ),
        section(
          _DenseHero(
            nw: nw,
            categories: categories,
            totalsByCat: totalsByCat,
            onTap: onAssets,
          ),
          index: 1,
        ),
        section(
          _SpendAndHealth(
            totalSpent: totalSpent,
            income: income,
            health: health,
            onExpenses: onExpenses,
            onHealth: onInsights,
          ),
          index: 2,
        ),
        section(
          CategoryGrid(
            categories: categories.take(4).toList(),
            totals: totalsByCat,
            onTap: onExpenses,
          ),
          index: 3,
        ),
        section(
          CardsPreview(cards: cards, onTap: onCards),
          index: 4,
        ),
        section(
          GoalsPreview(goals: goals.take(2).toList(), onTap: onGoals),
          index: 5,
        ),
        section(
          RecentList(
            recentAsync: recentAsync,
            household: household,
            onTap: onExpenses,
          ),
          index: 6,
        ),
      ],
    );
  }
}

class _DenseHero extends StatelessWidget {
  const _DenseHero({
    required this.nw,
    required this.categories,
    required this.totalsByCat,
    required this.onTap,
  });
  final NetWorth nw;
  final List<Category> categories;
  final Map<String, int> totalsByCat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final donutSegments = <DonutSegment>[
      if (nw.cash > 0)
        DonutSegment(value: nw.cash.toDouble(), color: FtColors.sky),
      if (nw.savings > 0)
        DonutSegment(value: nw.savings.toDouble(), color: FtColors.moss),
      if (nw.investments > 0)
        DonutSegment(value: nw.investments.toDouble(), color: FtColors.clay),
    ];
    // Generate a soft upward sparkline based on current total (purely visual —
    // no historical net-worth snapshots stored yet).
    final spark = <double>[
      for (var i = 0; i < 16; i++)
        i.toDouble() + (i.isEven ? 0.4 : -0.2) + (i / 3),
    ];
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
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
                    const Eyebrow('Total Aset'),
                    const SizedBox(height: 6),
                    Text(
                      compactMoney(nw.total),
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontSize: 30, height: 1),
                    ),
                    const SizedBox(height: 10),
                    Sparkline(data: spark, color: FtColors.moss, height: 32),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              MiniDonut(segments: donutSegments, size: 92, thickness: 11),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: FtColors.line,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                _Stat(
                  label: 'Tunai',
                  value: compactMoney(nw.cash),
                  color: FtColors.sky,
                ),
                _Stat(
                  label: 'Tabungan',
                  value: compactMoney(nw.savings),
                  color: FtColors.moss,
                ),
                _Stat(
                  label: 'Investasi',
                  value: compactMoney(nw.investments),
                  color: FtColors.clay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: FtColors.ink3,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendAndHealth extends StatelessWidget {
  const _SpendAndHealth({
    required this.totalSpent,
    required this.income,
    required this.health,
    required this.onExpenses,
    required this.onHealth,
  });
  final int totalSpent;
  final int income;
  final HealthScore health;
  final VoidCallback onExpenses;
  final VoidCallback onHealth;

  String _stateLabel(int score) =>
      score >= 80 ? 'Sehat' : score >= 50 ? 'Perhatian' : 'Berisiko';
  Color _stateColor(int score) => score >= 80
      ? FtColors.healthOk
      : score >= 50
          ? FtColors.healthWarn
          : FtColors.healthBad;

  @override
  Widget build(BuildContext context) {
    final hasIncome = income > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1.3fr : 1fr ratio — same as design grid.
            Expanded(
              flex: 13,
              child: FtCard(
                onTap: onExpenses,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Pengeluaran'),
                    const SizedBox(height: 4),
                    Text(
                      compactMoney(totalSpent),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 22, height: 1.1),
                    ),
                    if (hasIncome) ...[
                      const SizedBox(height: 2),
                      Text(
                        'dari ${compactMoney(income)} pendapatan',
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    FtProgressBar(
                      value: totalSpent,
                      max: hasIncome ? income : 1,
                      color: totalSpent > income && hasIncome
                          ? FtColors.danger
                          : FtColors.clay,
                      height: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 10,
              child: FtCard(
                onTap: onHealth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Kesehatan'),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${health.score}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 26,
                                height: 1,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _stateColor(health.score),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stateLabel(health.score),
                      style: TextStyle(color: FtColors.ink3, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      health.verdict,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FtColors.ink2,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
