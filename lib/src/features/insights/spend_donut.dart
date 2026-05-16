import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../household/household.dart';

class SpendDonut extends StatelessWidget {
  const SpendDonut({
    super.key,
    required this.totals,
    required this.categories,
  });

  final Map<String, int> totals;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final grand = totals.values.fold<int>(0, (a, b) => a + b);
    if (grand == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('Belum ada pengeluaran siklus ini',
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    final byId = {for (final c in categories) c.id: c};
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sections = <PieChartSectionData>[];
    for (final e in entries) {
      final cat = byId[e.key];
      sections.add(PieChartSectionData(
        color: cat != null ? _parseColor(cat.color) : Colors.grey,
        value: e.value.toDouble(),
        title: '',
        radius: 38,
        showTitle: false,
      ));
    }
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              Text(Money.format(grand),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
