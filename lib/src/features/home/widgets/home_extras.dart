import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hide_assets_provider.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../goals/goal.dart';
import '../../household/household.dart';
import 'home_formatters.dart';

/// "Anggaran bulan ini" (Lengkap only): the top 4 categories as plain rows,
/// each with one thin bar (accent, red when over). DESIGN.md section 8 item 6.
class BudgetSection extends StatelessWidget {
  const BudgetSection({
    super.key,
    required this.categories,
    required this.totals,
    required this.carries,
  });

  final List<Category> categories;
  final Map<String, int> totals;
  final Map<String, int> carries;

  @override
  Widget build(BuildContext context) {
    final shown = categories.take(4).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FtSectionHeader(
          title: 'Anggaran bulan ini',
          actionLabel: 'Lihat semua',
          onAction: () => context.push('/spend'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Column(
            children: [for (final c in shown) _BudgetRow(category: c, spent: totals[c.id] ?? 0, carry: carries[c.id] ?? 0)],
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.category, required this.spent, required this.carry});
  final Category category;
  final int spent;
  final int carry;

  @override
  Widget build(BuildContext context) {
    final budget = category.monthlyBudget + carry;
    final hasBudget = budget > 0;
    final over = hasBudget && spent > budget;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                hasBudget
                    ? '${compactMoney(spent)} / ${compactMoney(budget)}'
                    : compactMoney(spent),
                style: TextStyle(
                  color: over ? FtColors.danger : FtColors.ink3,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          // No budget set → no bar (a full bar would read as "100% used, fine").
          if (hasBudget) ...[
            const SizedBox(height: 7),
            FtProgressBar(
              value: spent,
              max: budget,
              color: over ? FtColors.danger : FtColors.clay,
              overflowColor: FtColors.danger,
              height: 4,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Kekayaan bersih" (Lengkap only): value + its 2-week change, respecting the
/// hide-assets toggle. Tap opens Aset. DESIGN.md section 8 item 7.
class NetWorthRow extends ConsumerWidget {
  const NetWorthRow({super.key, required this.nw, required this.trend});
  final NetWorth nw;
  final List<double> trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    final delta =
        trend.length >= 2 ? (trend.last - trend.first).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FtSectionHeader(title: 'Kekayaan bersih'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/accounts'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hidden ? maskMoney() : compactMoney(nw.total),
                        style: TextStyle(
                          color: FtColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (!hidden && delta != 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${delta >= 0 ? '+' : '−'}${compactMoney(delta.abs())} dalam 2 minggu',
                          style: TextStyle(
                            color: delta >= 0 ? FtColors.moss : FtColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const HideAssetsEye(),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Tujuan" (Lengkap only): up to 3 goals as plain rows with a thin bar.
/// DESIGN.md section 8 item 8.
class GoalsSection extends StatelessWidget {
  const GoalsSection({super.key, required this.goals});
  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final shown = goals.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FtSectionHeader(
          title: 'Tujuan',
          actionLabel: 'Lihat semua',
          onAction: () => context.push('/goals'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Column(
            children: [for (final g in shown) _GoalRow(goal: g)],
          ),
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.99,
      onTap: () => context.push('/goals/${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${compactMoney(goal.current)} / ${compactMoney(goal.target)}',
                  style: TextStyle(
                    color: FtColors.ink3,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            FtProgressBar(
              value: goal.current,
              max: goal.target,
              color: FtColors.clay,
              height: 4,
            ),
          ],
        ),
      ),
    );
  }
}
