/// Insight kontekstual 1 kalimat untuk home — dipilih dari aturan
/// berprioritas, maks 1 per hari (caching di widget). Pure & deterministik.
library;

import 'formatters.dart';

typedef InsightCategory = ({String id, String label, int budget, int spent});

/// Kalimat insight hari ini, atau null bila tidak ada yang layak.
///
/// Prioritas: hampir-limit > laju cepat > hemat vs siklus lalu >
/// kemarin nol belanja > laju terkendali.
String? dailyInsight({
  required List<InsightCategory> categories,
  required Map<String, int> prevSpentById,
  required int totalSpent,
  required int totalBudget,
  required int daysElapsed,
  required int cycleLength,
  required bool noSpendYesterday,
}) {
  final daysLeft = cycleLength - daysElapsed;

  // 1) Kategori hampir menyentuh limit (85-99%).
  for (final c in categories) {
    if (c.budget <= 0) continue;
    final pct = c.spent * 100 ~/ c.budget;
    if (pct >= 85 && pct < 100) {
      final sisa = c.budget - c.spent;
      return 'Anggaran ${c.label} terpakai $pct%. Sisa '
          '${Money.compact(sisa)} untuk $daysLeft hari ke depan.';
    }
  }

  // 2) Laju belanja jauh lebih cepat dari jalannya siklus.
  if (totalBudget > 0 && cycleLength > 0) {
    final spentPct = totalSpent * 100 ~/ totalBudget;
    final elapsedPct = daysElapsed * 100 ~/ cycleLength;
    if (spentPct < 100 && spentPct - elapsedPct >= 15) {
      return 'Sudah $spentPct% anggaran terpakai di $elapsedPct% siklus.';
    }
  }

  // 3) Hemat berarti vs siklus lalu (≥20% dan ≥50rb). Baseline diprorata
  // ke posisi hari yang sama supaya adil di tengah siklus.
  if (cycleLength > 0) {
    for (final c in categories) {
      final prev = prevSpentById[c.id] ?? 0;
      if (prev <= 0) continue;
      final prevAtPace = prev * daysElapsed ~/ cycleLength;
      final saved = prevAtPace - c.spent;
      if (saved >= 50000 && saved * 100 >= prevAtPace * 20) {
        return 'Hemat ${Money.compact(saved)} di ${c.label} dibanding '
            'siklus lalu.';
      }
    }
  }

  // 4) Kemarin tanpa pengeluaran.
  if (noSpendYesterday && totalSpent > 0) {
    return 'Kemarin nol pengeluaran.';
  }

  // 5) Laju terkendali.
  if (totalBudget > 0 && cycleLength > 0 && totalSpent > 0) {
    final spentPct = totalSpent * 100 ~/ totalBudget;
    final elapsedPct = daysElapsed * 100 ~/ cycleLength;
    if (spentPct + 10 <= elapsedPct) {
      return 'Pengeluaran terkendali: $spentPct% anggaran di '
          '$elapsedPct% siklus.';
    }
  }

  return null;
}
