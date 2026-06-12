/// Split satu transaksi (mis. struk supermarket) ke beberapa kategori.
/// Setiap bagian disimpan sebagai pengeluaran biasa — tanpa perubahan model,
/// anggaran per kategori otomatis benar.
library;

typedef SplitPart = ({String? categoryId, int amount});

int splitAssigned(Iterable<SplitPart> parts) =>
    parts.fold(0, (a, p) => a + p.amount);

/// Sisa yang belum dialokasikan (negatif = kelebihan).
int splitRemainder(int total, Iterable<SplitPart> parts) =>
    total - splitAssigned(parts);

/// Null bila valid; selain itu kode error:
/// `min_two` | `zero_amount` | `no_category` | `over` | `under`.
String? validateSplit(int total, List<SplitPart> parts) {
  if (parts.length < 2) return 'min_two';
  if (parts.any((p) => p.amount <= 0)) return 'zero_amount';
  if (parts.any((p) => p.categoryId == null)) return 'no_category';
  final r = splitRemainder(total, parts);
  if (r < 0) return 'over';
  if (r > 0) return 'under';
  return null;
}
