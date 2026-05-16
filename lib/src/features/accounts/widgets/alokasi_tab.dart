import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import '../../investments/investment.dart';

class AlokasiTab extends StatelessWidget {
  const AlokasiTab({required this.household, required this.investments});
  final Household household;
  final List<Investment> investments;

  @override
  Widget build(BuildContext context) {
    final cash = household.cashAccounts.fold<int>(0, (a, b) => a + b.value);
    final savings =
        household.savingsAccounts.fold<int>(0, (a, b) => a + b.value);
    final byType = <InvestmentType, int>{};
    for (final i in investments) {
      byType[i.type] = (byType[i.type] ?? 0) + i.currentValue;
    }

    final liquid = cash + savings;
    final growth = (byType[InvestmentType.saham] ?? 0) +
        (byType[InvestmentType.reksadana] ?? 0);
    final stable = (byType[InvestmentType.deposito] ?? 0) +
        (byType[InvestmentType.lainnya] ?? 0);
    final alt = (byType[InvestmentType.emas] ?? 0) +
        (byType[InvestmentType.crypto] ?? 0);
    final total = liquid + growth + stable + alt;

    final buckets = [
      _Bucket('Liquid', liquid, FtColors.sky, 0.30),
      _Bucket('Growth', growth, FtColors.sage, 0.45),
      _Bucket('Stable', stable, FtColors.ochre, 0.20),
      _Bucket('Alternatif', alt, FtColors.plum, 0.05),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
      children: [
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Belum ada data aset untuk dialokasikan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  for (final b in buckets)
                    if (b.value > 0)
                      PieChartSectionData(
                        value: b.value.toDouble(),
                        color: b.color,
                        radius: 28,
                        title: '${(b.value / total * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FtCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Alokasi saat ini vs rekomendasi'),
                const SizedBox(height: 14),
                for (final b in buckets) ...[
                  AllocRow(
                    label: b.label,
                    color: b.color,
                    actualPct: total > 0 ? b.value / total : 0,
                    targetPct: b.target,
                    value: b.value,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (buckets.any((b) => (b.actualPct - b.target).abs() > 0.05))
            FtCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Saran rebalance'),
                  const SizedBox(height: 10),
                  for (final b in buckets)
                    if ((b.actualPct - b.target).abs() > 0.05)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${b.actualPct > b.target ? 'Kurangi' : 'Tambah'} ${b.label} sebesar ${Money.format((b.target * total - b.value).abs().round())}',
                          style: TextStyle(
                            color: b.actualPct > b.target
                                ? FtColors.danger
                                : FtColors.sage,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Bucket {
  final String label;
  final int value;
  final Color color;
  final double target;
  double get actualPct => 0;
  _Bucket(this.label, this.value, this.color, this.target);
}

class AllocRow extends StatelessWidget {
  const AllocRow({
    required this.label,
    required this.color,
    required this.actualPct,
    required this.targetPct,
    required this.value,
  });
  final String label;
  final Color color;
  final double actualPct;
  final double targetPct;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: FtColors.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              Money.format(value),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: FtColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: actualPct.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: targetPct.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: FtColors.ink2,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktual ${(actualPct * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: FtColors.ink3, fontSize: 10),
            ),
            Text(
              'Target ${(targetPct * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: FtColors.ink3, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
