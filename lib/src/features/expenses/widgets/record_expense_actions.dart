part of '../record_expense_screen.dart';

/// Most frequently used active category this cycle (ties → first hit).
String? _mostUsedCategoryId(
  List<Expense> expenses,
  List<Category> active,
) {
  if (expenses.isEmpty) return null;
  final activeIds = {for (final c in active) c.id};
  final counts = <String, int>{};
  for (final e in expenses) {
    if (!activeIds.contains(e.categoryId)) continue;
    counts.update(e.categoryId, (v) => v + 1, ifAbsent: () => 1);
  }
  String? best;
  var bestN = 0;
  counts.forEach((id, n) {
    if (n > bestN) {
      best = id;
      bestN = n;
    }
  });
  return best;
}

extension _RecordExpenseActions on _RecordExpenseScreenState {
  /// Auto-suggest a category from the note text (custom labels first, then
  /// the Indonesian merchant keyword map). Only while the user hasn't
  /// manually picked a chip.
  void _onNoteChanged() {
    if (_categoryTouched || widget.isEdit) return;
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;
    final active =
        household.categories.where((c) => !c.archived).toList();
    var next = suggestByLabel(
      _note.text,
      [for (final c in active) (id: c.id, label: c.label)],
    );
    if (next == null) {
      final seeded = suggestSeededCategoryId(_note.text);
      if (seeded != null && active.any((c) => c.id == seeded)) next = seeded;
    }
    if (next != null && next != _categoryId) {
      _rebuild(() {
        _categoryId = next;
        _suggestedCategoryId = next;
      });
    }
  }

  /// Remember the chosen payment route for the next record session.
  Future<void> _saveLastPayment() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastPayType, _payType);
    if (_payType == 'cash' && _sourceAccountId != null) {
      await p.setString(_kLastAccount, _sourceAccountId!);
    }
    if (_payType == 'credit' && _cardId != null) {
      await p.setString(_kLastCard, _cardId!);
    }
  }

  Future<void> _pickDate() async {
    FtHaptics.select();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) _rebuild(() => _date = picked);
  }

  /// Isi form dari chip favorit (1-tap).
  void _applyFavorite(FavoriteExpense f) {
    _rebuild(() {
      _amount = f.amount;
      _categoryId = f.categoryId;
      _categoryTouched = true;
      _suggestedCategoryId = null;
      _note.text = f.note;
    });
  }

  /// Simpan kombinasi saat ini sebagai favorit per-perangkat.
  Future<void> _saveFavorite() async {
    if (_amount <= 0 || _categoryId == null) return;
    FtHaptics.success();
    final label =
        _note.text.trim().isEmpty ? 'Tanpa catatan' : _note.text.trim();
    await ref.read(favoriteExpensesProvider.notifier).add(
          FavoriteExpense(
              note: label, amount: _amount, categoryId: _categoryId!),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$label" tersimpan di favorit.')),
      );
    }
  }

  /// Reset form untuk entri berikutnya (mode "Simpan & tambah lagi").
  /// Tanggal & metode bayar dipertahankan — pola catat-rapel mingguan.
  void _resetForNext() {
    _rebuild(() {
      _amount = 0;
      _note.clear();
      _recurring = false;
      _cicilan = false;
      _categoryTouched = false;
      _suggestedCategoryId = null;
      _error = null;
    });
  }

  /// Buka sheet split — validasi pembayaran dulu (sama seperti submit).
  Future<void> _openSplit(Household h) async {
    if (_payType == 'credit' && _cardId == null) {
      FtHaptics.warning();
      _rebuild(() => _error = 'Pilih kartu kredit dulu');
      return;
    }
    final hasAccounts =
        h.cashAccounts.isNotEmpty || h.savingsAccounts.isNotEmpty;
    if (_payType == 'cash' && hasAccounts && _sourceAccountId == null) {
      FtHaptics.warning();
      _rebuild(() => _error = 'Pilih sumber dana dulu');
      return;
    }
    final user = ref.read(firebaseAuthProvider).currentUser!;
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final ok = await SplitExpenseSheet.show(
      context,
      household: h,
      total: _amount,
      initialCategoryId: _categoryId,
      payType: _payType,
      sourceAccountId: _payType == 'cash' ? _sourceAccountId : null,
      cardId: _payType == 'credit' ? _cardId : null,
      spentBy: _spentBy ?? user.uid,
      date: _date,
      note: note,
    );
    if (ok == true && mounted) {
      // ignore: discarded_futures
      _saveLastPayment();
      FtCelebrate.show(context, message: 'Split tersimpan');
      context.pop();
    }
  }

  Future<void> _submit(
    Household h,
    List<CreditCard> cards, {
    bool addAnother = false,
  }) async {
    if (_amount <= 0 || _categoryId == null) {
      FtHaptics.warning();
      _rebuild(() => _error = 'Lengkapi jumlah & kategori');
      return;
    }
    if (_payType == 'credit' && _cardId == null) {
      FtHaptics.warning();
      _rebuild(() => _error = 'Pilih kartu kredit');
      return;
    }
    final hasAccounts =
        h.cashAccounts.isNotEmpty || h.savingsAccounts.isNotEmpty;
    if (_payType == 'cash' && hasAccounts && _sourceAccountId == null) {
      FtHaptics.warning();
      _rebuild(() => _error = 'Pilih sumber dana');
      return;
    }
    FtHaptics.tap();
    _rebuild(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();
      final user = ref.read(firebaseAuthProvider).currentUser!;
      final spentBy = _spentBy ?? user.uid;

      if (widget.isEdit) {
        await repo.update(
          householdId: h.id,
          expenseId: widget.initial!.id,
          newAmount: _amount,
          newCategoryId: _categoryId!,
          newSpentBy: spentBy,
          newDate: _date,
          newSourceAccountId: _payType == 'cash' ? _sourceAccountId : null,
          newCardId: _payType == 'credit' ? _cardId : null,
          newNote: note,
          newRecurring: _recurring,
        );
      } else if (_payType == 'credit' && (_cicilan || !_recurring)) {
        // "Lunas" purchases also run through the plan path as a 1-month
        // cicilan, so every card charge sits in "Cicilan aktif" until its
        // bill is paid and only then rolls into the card history.
        await repo.addCicilanExpense(
          householdId: h.id,
          principal: _amount,
          categoryId: _categoryId!,
          spentBy: spentBy,
          date: _date,
          cardId: _cardId!,
          months: _cicilan ? _cicilanMonths : 1,
          apr: _cicilan ? _cicilanApr : 0.0,
          note: note,
        );
      } else if (_payType == 'credit') {
        // Lunas + rutin: the recurring runner respawns plain rows, so the
        // seed row must stay plain too.
        await repo.addCardExpense(
          householdId: h.id,
          amount: _amount,
          categoryId: _categoryId!,
          spentBy: spentBy,
          date: _date,
          cardId: _cardId!,
          note: note,
          recurring: _recurring,
        );
      } else {
        await repo.add(
          householdId: h.id,
          amount: _amount,
          categoryId: _categoryId!,
          spentBy: spentBy,
          date: _date,
          sourceAccountId: _sourceAccountId,
          note: note,
          recurring: _recurring,
        );
      }
      if (!widget.isEdit) {
        // Fire-and-forget; next session opens with this payment preselected.
        // ignore: discarded_futures
        _saveLastPayment();
      }
      if (mounted) {
        if (addAnother) {
          FtCelebrate.show(context, message: 'Tersimpan. Lanjut.');
          _resetForNext();
        } else {
          FtCelebrate.show(context, message: 'Tersimpan');
          context.pop();
        }
      }
    } on StateError catch (e) {
      FtHaptics.error();
      final msg = switch (e.message) {
        'insufficient' => 'Saldo rekening sumber tidak cukup',
        'account_missing' => 'Rekening sumber tidak ditemukan',
        'cicilan_edit_locked' =>
          'Cicilan tidak bisa ubah jumlah/kartu. Hapus & catat ulang.',
        'expense_missing' => 'Pengeluaran tidak ditemukan',
        _ => 'Gagal: ${e.message}',
      };
      _rebuild(() => _error = msg);
    } catch (e) {
      FtHaptics.error();
      _rebuild(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) _rebuild(() => _busy = false);
    }
  }
}
