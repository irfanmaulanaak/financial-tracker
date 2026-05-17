import 'package:flutter/material.dart';

import '../../../core/category_analysis.dart';
import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';

/// "Temuan Pengeluaran" — top-N category deltas vs the previous-cycles
/// average, sorted by abs(delta). Tap a row to drill into category detail.
class HealthFindings extends StatelessWidget {
  const HealthFindings({
    super.key,
    required this.categories,
    required this.current,
    required this.previousWindows,
    required this.onTap,
  });
  final List<Category> categories;
  final List<Expense> current;
  final List<List<Expense>> previousWindows;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final byCatCurrent = <String, int>{};
    for (final e in current) {
      byCatCurrent.update(e.categoryId, (v) => v + e.amount,
          ifAbsent: () => e.amount);
    }
    final history = <String, List<int>>{};
    for (final w in previousWindows) {
      final totals = <String, int>{};
      for (final e in w) {
        totals.update(e.categoryId, (v) => v + e.amount,
            ifAbsent: () => e.amount);
      }
      for (final c in categories) {
        history.putIfAbsent(c.id, () => []).add(totals[c.id] ?? 0);
      }
    }
    final findings = <_Finding>[];
    for (final c in categories) {
      final cur = byCatCurrent[c.id] ?? 0;
      final a = analyseCategory(
        categoryId: c.id,
        currentSpend: cur,
        previousSpends: history[c.id] ?? const [],
      );
      if (a.historicalAverage == 0 && cur == 0) continue;
      if (a.deltaPct.abs() < 0.10) continue;
      findings.add(_Finding(category: c, analysis: a));
    }
    findings.sort((a, b) =>
        b.analysis.deltaPct.abs().compareTo(a.analysis.deltaPct.abs()));
    if (findings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Eyebrow('Temuan Pengeluaran'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < findings.take(5).length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _FindingRow(
                  finding: findings[i],
                  onTap: () => onTap(findings[i].category.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Finding {
  const _Finding({required this.category, required this.analysis});
  final Category category;
  final CategoryAnalysis analysis;
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding, required this.onTap});
  final _Finding finding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delta = finding.analysis.deltaPct;
    final positive = delta > 0;
    final color = positive
        ? (delta > 0.20 ? FtColors.danger : FtColors.ochre)
        : FtColors.healthOk;
    final catColor = parseColor(finding.category.color);
    return FtTapScale(
      scale: 0.98,
      haptic: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: color.withValues(alpha: 0.28), width: 0.5),
              ),
              child: Icon(
                positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: color,
              ),
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
                          finding.category.label,
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
                        '${positive ? '+' : ''}${(delta * 100).round()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sekarang ${Money.format(finding.analysis.currentSpend)} · rata-rata ${Money.format(finding.analysis.historicalAverage)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 14, color: catColor),
          ],
        ),
      ),
    );
  }
}
