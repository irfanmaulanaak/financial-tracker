import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

class MonthStrip extends StatelessWidget {
  const MonthStrip({
    super.key,
    required this.totalSpent,
    required this.income,
    required this.daily,
    required this.todaySpend,
    required this.cycleStart,
    required this.cycleEndExclusive,
    this.compact = false,
  });

  final int totalSpent;
  final int income;
  final int daily;
  final int todaySpend;
  final DateTime cycleStart;
  final DateTime cycleEndExclusive;

  /// When true, renders a denser variant suitable for use inside a 2-column
  /// row alongside [HealthSnapshot(compact: true)].
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasIncome = income > 0;
    final pctLabel = hasIncome ? (totalSpent / income * 100).round() : 0;
    final eyebrowText = compact
        ? 'Pengeluaran'
        : 'Pengeluaran · ${Dates.short(cycleStart)} - ${Dates.short(cycleEndExclusive.subtract(const Duration(days: 1)))}';

    final amountStyle = compact
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              height: 1,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w500,
            )
        : Theme.of(context).textTheme.headlineLarge;

    return FtCard(
      margin: compact ? null : const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: compact
          ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
          : const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(eyebrowText),
          const SizedBox(height: 6),
          Text(compactMoney(totalSpent), style: amountStyle),
          const SizedBox(height: 2),
          Builder(
            builder: (ctx) => FtTapScale(
              scale: 0.98,
              haptic: false,
              onTap: () => ctx.push('/incomes'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      hasIncome
                          ? 'dari ${compactMoney(income)}'
                          : 'Catat pemasukan pertama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        decorationColor: FtColors.line,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 12,
                    color: FtColors.ink3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          FtProgressBar(
            value: totalSpent,
            max: hasIncome ? income : 1,
            color: totalSpent > income && hasIncome
                ? FtColors.danger
                : FtColors.clay,
            height: compact ? 3 : 4,
          ),
          const SizedBox(height: 6),
          if (compact)
            Text(
              hasIncome ? '$pctLabel% terpakai' : 'Catat pemasukan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: FtColors.ink3, fontSize: 10.5),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasIncome
                        ? '$pctLabel% pendapatan terpakai'
                        : 'Catat pemasukan untuk lihat rasio',
                  ),
                ),
                Text('Hari ini · ${compactMoney(todaySpend)}'),
              ],
            ),
        ],
      ),
    );
  }
}
