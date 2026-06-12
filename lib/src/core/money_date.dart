/// Agregasi pure untuk ritual "Money Date" (review siklus terpandu) —
/// mulai dari yang hemat (framing positif), baru sorotan kenaikan.
library;

typedef CategoryDelta = ({String id, int spend, int baseline, int delta});

/// Gabungkan spend siklus ini vs baseline per kategori.
/// Kategori yang muncul di salah satu sisi saja tetap ikut (sisi lain = 0).
List<CategoryDelta> categoryDeltas(
  Map<String, int> byCat,
  Map<String, int> byCatBase,
) {
  final ids = {...byCat.keys, ...byCatBase.keys};
  return [
    for (final id in ids)
      (
        id: id,
        spend: byCat[id] ?? 0,
        baseline: byCatBase[id] ?? 0,
        delta: (byCat[id] ?? 0) - (byCatBase[id] ?? 0),
      ),
  ];
}

/// Kategori paling hemat: turun paling banyak vs baseline (delta < 0,
/// baseline > 0 supaya "hemat" bermakna). Terbesar penghematannya dulu.
List<CategoryDelta> topSavers(List<CategoryDelta> deltas, {int n = 2}) {
  final savers = [
    for (final d in deltas)
      if (d.delta < 0 && d.baseline > 0) d,
  ]..sort((a, b) => a.delta.compareTo(b.delta));
  return savers.take(n).toList();
}

/// Kategori naik paling banyak vs baseline (delta > 0). Terbesar dulu.
List<CategoryDelta> topRisers(List<CategoryDelta> deltas, {int n = 2}) {
  final risers = [
    for (final d in deltas)
      if (d.delta > 0) d,
  ]..sort((a, b) => b.delta.compareTo(a.delta));
  return risers.take(n).toList();
}
