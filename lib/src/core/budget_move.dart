/// Geser anggaran antar kategori di tengah siklus ("roll with the punches",
/// YNAB) + jejak siapa/kapan (log "Recent Moves" ala Monarch).
///
/// Pure — validasi & penerapan diuji unit. Persistensi di
/// HouseholdRepository.moveBudget (transaksi Firestore).
library;

import '../features/household/household.dart';

/// Hasil validasi: [categories] baru bila sukses, [error] kode bila gagal.
/// Error codes: 'same_category', 'invalid_amount', 'category_missing',
/// 'insufficient_budget'.
({List<Category>? categories, String? error}) applyBudgetMove({
  required List<Category> categories,
  required String fromId,
  required String toId,
  required int amount,
}) {
  if (fromId == toId) return (categories: null, error: 'same_category');
  if (amount <= 0) return (categories: null, error: 'invalid_amount');

  Category? from;
  Category? to;
  for (final c in categories) {
    if (c.id == fromId) from = c;
    if (c.id == toId) to = c;
  }
  if (from == null || to == null || from.archived || to.archived) {
    return (categories: null, error: 'category_missing');
  }
  if (from.monthlyBudget < amount) {
    return (categories: null, error: 'insufficient_budget');
  }

  return (
    categories: [
      for (final c in categories)
        if (c.id == fromId)
          c.copyWith(monthlyBudget: c.monthlyBudget - amount)
        else if (c.id == toId)
          c.copyWith(monthlyBudget: c.monthlyBudget + amount)
        else
          c,
    ],
    error: null,
  );
}

/// Tambah entri log di depan, batasi [cap] terbaru (doc household tetap kecil).
List<BudgetMove> appendBudgetMove(
  List<BudgetMove> existing,
  BudgetMove move, {
  int cap = 30,
}) =>
    [move, ...existing].take(cap).toList();

/// Log geser anggaran milik satu siklus (untuk recap/money date).
List<BudgetMove> movesInCycle(
  List<BudgetMove> moves, {
  required DateTime start,
  required DateTime endExclusive,
}) =>
    [
      for (final m in moves)
        if (!m.at.isBefore(start) && m.at.isBefore(endExclusive)) m,
    ];
