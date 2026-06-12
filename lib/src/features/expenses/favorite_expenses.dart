/// Transaksi favorit — template 1-tap di form catat pengeluaran
/// ("Kopi Tuku 25rb"). Per-perangkat (SharedPreferences), maks 6,
/// terbaru di depan. Riset: friksi input = penentu retensi app manual.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteExpense {
  const FavoriteExpense({
    required this.note,
    required this.amount,
    required this.categoryId,
  });

  final String note;
  final int amount;
  final String categoryId;

  Map<String, dynamic> toJson() =>
      {'note': note, 'amount': amount, 'categoryId': categoryId};

  static FavoriteExpense fromJson(Map<String, dynamic> m) => FavoriteExpense(
        note: m['note'] as String? ?? '',
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        categoryId: m['categoryId'] as String? ?? '',
      );

  bool sameAs(FavoriteExpense o) =>
      note == o.note && amount == o.amount && categoryId == o.categoryId;
}

const _kFavorites = 'expense_favorites';
const maxFavorites = 6;

final favoriteExpensesProvider =
    NotifierProvider<FavoriteExpensesNotifier, List<FavoriteExpense>>(
  FavoriteExpensesNotifier.new,
);

class FavoriteExpensesNotifier extends Notifier<List<FavoriteExpense>> {
  @override
  List<FavoriteExpense> build() {
    // ignore: discarded_futures
    _load();
    return const [];
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kFavorites);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => FavoriteExpense.fromJson(e as Map<String, dynamic>))
        .toList();
    state = list;
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kFavorites, jsonEncode([for (final f in state) f.toJson()]));
  }

  Future<void> add(FavoriteExpense fav) async {
    state = [
      fav,
      ...state.where((f) => !f.sameAs(fav)),
    ].take(maxFavorites).toList();
    await _persist();
  }

  Future<void> remove(FavoriteExpense fav) async {
    state = [...state.where((f) => !f.sameAs(fav))];
    await _persist();
  }
}
