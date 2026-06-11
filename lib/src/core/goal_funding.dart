/// Tujuan ber-sumber-dana aset ("linked goal").
///
/// Goal tidak punya rekening sendiri — uangnya hidup di aset nyata
/// (rekening tabungan / posisi investasi). Goal yang di-link ke aset tidak
/// pakai setoran manual; nilainya dihitung dari nilai aset itu. Bila satu
/// aset dipakai beberapa goal, nilainya dibagi **proporsional terhadap
/// target** masing-masing goal, dengan cap di target (sisa nilai aset di
/// atas total target tidak dialokasikan).
///
///   share(goal) = min(target, assetValue × target / totalTargetAsetItu)
library;

typedef LinkedGoalInput = ({String id, int target, String? fundingKey});

/// Kunci aset gabungan, mis. `savings:abc123` / `investment:xyz789`.
String goalFundingKey(String type, String id) => '$type:$id';

/// Nilai efektif tiap linked goal. Goal manual (fundingKey null) tidak
/// muncul di hasil. Aset yang sudah tidak ada → semua goal-nya bernilai 0
/// (UI menandai "aset tidak ditemukan").
Map<String, int> allocateLinkedGoals({
  required List<LinkedGoalInput> goals,
  required Map<String, int> assetValues,
}) {
  final byAsset = <String, List<LinkedGoalInput>>{};
  for (final g in goals) {
    final k = g.fundingKey;
    if (k == null) continue;
    byAsset.putIfAbsent(k, () => []).add(g);
  }

  final out = <String, int>{};
  byAsset.forEach((key, group) {
    final assetValue = assetValues[key] ?? 0;
    final totalTarget = group.fold<int>(0, (a, g) => a + g.target);
    for (final g in group) {
      if (totalTarget <= 0 || g.target <= 0 || assetValue <= 0) {
        out[g.id] = 0;
        continue;
      }
      // Bagi via double agar tidak overflow untuk nominal rupiah besar.
      var share = (assetValue * (g.target / totalTarget)).floor();
      if (share > g.target) share = g.target;
      out[g.id] = share;
    }
  });
  return out;
}
