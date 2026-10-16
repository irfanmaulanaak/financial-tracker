import '../../core/expense_aggregations.dart';
import '../expenses/expense.dart';

/// Kategori dengan penurunan terbesar vs baseline (null bila tak ada).
({String id, int saved})? biggestSaver(
  Map<String, int> byCat,
  Map<String, int> byCatBase,
) {
  String? id;
  var saved = 0;
  for (final e in byCatBase.entries) {
    final s = e.value - (byCat[e.key] ?? 0);
    if (s > saved) {
      saved = s;
      id = e.key;
    }
  }
  return id == null ? null : (id: id, saved: saved);
}

/// Note of the expense matching a derived [ExpenseRecord] (null if none).
String? noteOfExpense(List<Expense> source, ExpenseRecord r) {
  for (final e in source) {
    if (e.amount == r.amount &&
        e.categoryId == r.categoryId &&
        e.date == r.date &&
        e.spentBy == r.spentBy) {
      return e.note;
    }
  }
  return null;
}
