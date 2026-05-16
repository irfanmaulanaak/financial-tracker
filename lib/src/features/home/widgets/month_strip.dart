import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_motion.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

class MonthStrip extends StatelessWidget {
  const MonthStrip({
    super.key,
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
                      compactMoney(totalSpent),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasIncome
                          ? 'dari ${compactMoney(income)} pendapatan'
                          : 'Belum ada pemasukan tercatat',
                      style: const TextStyle(
                        color: FtColors.ink3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FtTapScale(
                scale: 0.92,
                onTap: onAdd,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: FtColors.ink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: FtColors.bg,
                  ),
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
                  'Harian ${compactMoney(daily)}',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
