/// Static, opinionated portfolio allocation recommendation. Mirrors the
/// shape of `claude-design/data.jsx`'s `allocation` object — current vs
/// target weights + a list of rebalancing moves derived from the gap.
///
/// We don't fetch live market data. Targets reflect a single moderate-risk
/// profile that suits the 2-5 internal users this app is for. Output is
/// purely descriptive: percentages and labelled moves the user can act on.
library;

import 'package:flutter/material.dart';

import '../features/investments/investment.dart';
import '../theme.dart';

/// One slice of an allocation pie. Color is resolved from the theme so the
/// UI can pass it straight into `FtDonut`.
class AllocationSegment {
  final String label;
  final Color color;
  final double pct; // 0..100

  const AllocationSegment({
    required this.label,
    required this.color,
    required this.pct,
  });
}

/// A suggested rebalance move: shrink [from], grow [to], by [amount] IDR.
class AllocationMove {
  final String from;
  final String to;
  final int amount;
  final String reason;

  const AllocationMove({
    required this.from,
    required this.to,
    required this.amount,
    required this.reason,
  });
}

class AllocationRecommendation {
  final List<AllocationSegment> current;
  final List<AllocationSegment> target;
  final List<AllocationMove> moves;
  final String summary;

  /// Total tracked value across all buckets, in IDR.
  final int totalValue;

  /// True when all current buckets are inside the [tolerance] band of their
  /// targets — no meaningful rebalancing needed.
  final bool inBalance;

  const AllocationRecommendation({
    required this.current,
    required this.target,
    required this.moves,
    required this.summary,
    required this.totalValue,
    required this.inBalance,
  });
}

/// 4-bucket asset class taxonomy used by both the allocation tab and the
/// rebalancing moves list. Keeping it small lets us survive without
/// per-instrument data; investments collapse into one of these.
enum AssetBucket { liquid, growth, stable, alternative }

String _label(AssetBucket b) => switch (b) {
      AssetBucket.liquid => 'Likuid',
      AssetBucket.growth => 'Saham & Reksadana',
      AssetBucket.stable => 'Obligasi & Deposito',
      AssetBucket.alternative => 'Emas & Alternatif',
    };

Color _color(AssetBucket b) => switch (b) {
      AssetBucket.liquid => FtColors.sky,
      AssetBucket.growth => FtColors.sage,
      AssetBucket.stable => FtColors.ochre,
      AssetBucket.alternative => FtColors.plum,
    };

// Moderate-risk profile. Adds to 100. These are deliberate — see PLAN.md.
const Map<AssetBucket, double> _targetPct = {
  AssetBucket.liquid: 25,
  AssetBucket.growth: 45,
  AssetBucket.stable: 20,
  AssetBucket.alternative: 10,
};

AssetBucket _bucketFor(InvestmentType t) => switch (t) {
      InvestmentType.saham => AssetBucket.growth,
      InvestmentType.reksadana => AssetBucket.growth,
      InvestmentType.deposito => AssetBucket.stable,
      InvestmentType.lainnya => AssetBucket.stable,
      InvestmentType.emas => AssetBucket.alternative,
      InvestmentType.crypto => AssetBucket.alternative,
    };

/// Computes a [AllocationRecommendation] from current household balances.
///
/// - [cashTotal] / [savingsTotal] → `liquid`
/// - investments collapse via [_bucketFor]
///
/// Empty portfolio (total ≤ 0) returns target-only segments and an empty
/// moves list.
AllocationRecommendation computeAllocation({
  required int cashTotal,
  required int savingsTotal,
  required Iterable<Investment> investments,
  double tolerance = 0.05,
}) {
  final values = <AssetBucket, int>{
    AssetBucket.liquid: cashTotal + savingsTotal,
    AssetBucket.growth: 0,
    AssetBucket.stable: 0,
    AssetBucket.alternative: 0,
  };
  for (final inv in investments) {
    if (inv.currentValue <= 0) continue;
    values.update(_bucketFor(inv.type), (v) => v + inv.currentValue);
  }
  final total = values.values.fold<int>(0, (a, b) => a + b);

  final target = [
    for (final b in AssetBucket.values)
      AllocationSegment(
        label: _label(b),
        color: _color(b),
        pct: _targetPct[b]!,
      ),
  ];

  if (total == 0) {
    return AllocationRecommendation(
      current: const [],
      target: target,
      moves: const [],
      summary: 'Belum ada aset yang dilacak.',
      totalValue: 0,
      inBalance: false,
    );
  }

  final current = <AllocationSegment>[];
  final gaps = <AssetBucket, double>{};
  for (final b in AssetBucket.values) {
    final pct = (values[b]! / total) * 100;
    current.add(AllocationSegment(label: _label(b), color: _color(b), pct: pct));
    gaps[b] = pct - _targetPct[b]!;
  }

  final inBalance = gaps.values.every((g) => g.abs() <= tolerance * 100);

  // Moves: pair each over-allocated bucket with an under-allocated one,
  // largest gap first, until imbalances drop below tolerance.
  final moves = _buildMoves(values: values, total: total, gaps: gaps);

  final summary = inBalance
      ? 'Alokasi sudah dekat dengan profil moderat. Pertahankan.'
      : 'Profil moderat. Geser sebagian ${_largestOver(gaps)} ke ${_largestUnder(gaps)} untuk mendekati target.';

  return AllocationRecommendation(
    current: current,
    target: target,
    moves: moves,
    summary: summary,
    totalValue: total,
    inBalance: inBalance,
  );
}

List<AllocationMove> _buildMoves({
  required Map<AssetBucket, int> values,
  required int total,
  required Map<AssetBucket, double> gaps,
}) {
  final mutable = Map<AssetBucket, double>.from(gaps);
  final moves = <AllocationMove>[];

  while (true) {
    final over = mutable.entries
        .where((e) => e.value > 5)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final under = mutable.entries
        .where((e) => e.value < -5)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (over.isEmpty || under.isEmpty) break;

    final from = over.first;
    final to = under.first;
    final shiftPct =
        [from.value, -to.value].reduce((a, b) => a < b ? a : b);
    final amount = ((shiftPct / 100) * total).round();
    if (amount <= 0) break;

    moves.add(AllocationMove(
      from: _label(from.key),
      to: _label(to.key),
      amount: amount,
      reason: _reasonFor(from.key, to.key),
    ));

    mutable[from.key] = from.value - shiftPct;
    mutable[to.key] = to.value + shiftPct;
    if (moves.length >= 4) break;
  }
  return moves;
}

String _reasonFor(AssetBucket from, AssetBucket to) {
  if (to == AssetBucket.growth) return 'Naikkan eksposur pertumbuhan jangka panjang.';
  if (to == AssetBucket.stable) return 'Kunci yield stabil sebagai bantalan downside.';
  if (to == AssetBucket.alternative) return 'Tambah lindung nilai inflasi & non-korelasi.';
  if (to == AssetBucket.liquid) return 'Perkuat dana darurat & likuiditas harian.';
  return 'Selaraskan dengan target moderat.';
}

String _largestOver(Map<AssetBucket, double> gaps) {
  final e = gaps.entries.reduce((a, b) => a.value > b.value ? a : b);
  return _label(e.key);
}

String _largestUnder(Map<AssetBucket, double> gaps) {
  final e = gaps.entries.reduce((a, b) => a.value < b.value ? a : b);
  return _label(e.key);
}
