import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/category_suggester.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_celebrate.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../../ui/ft_submit_dot.dart';
import '../../ui/ft_ui.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../record_common/account_picker.dart';
import '../record_common/card_picker.dart';
import '../record_common/category_chip_row.dart';
import '../record_common/installment_picker.dart';
import '../record_common/meta_row.dart';
import '../record_common/money_field.dart';
import '../record_common/pay_type_toggle.dart';
import 'expense.dart';
import 'expense_favorites_row.dart';
import 'expense_providers.dart';
import 'expense_repository.dart';
import 'favorite_expenses.dart';
import 'split_expense_sheet.dart';

const _kLastPayType = 'record_last_pay_type';
const _kLastAccount = 'record_last_account';
const _kLastCard = 'record_last_card';

class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key, this.initial});

  /// When set, the screen runs in edit mode: prefills all fields and writes
  /// via `ExpenseRepository.update` instead of `add*`.
  final Expense? initial;

  bool get isEdit => initial != null;
  bool get isCicilan => initial?.installmentPlanId != null;

  @override
  ConsumerState<RecordExpenseScreen> createState() =>
      _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  int _amount = 0;
  String? _categoryId;
  String _payType = 'cash'; // 'cash' | 'credit'
  String? _sourceAccountId;
  String? _cardId;
  String? _spentBy;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  bool _recurring = false;
  bool _cicilan = false;
  int _cicilanMonths = 6;
  double _cicilanApr = 0.0;
  bool _busy = false;
  String? _error;

  /// True once the user explicitly tapped a category chip (or edit mode):
  /// suggestion & most-used defaults stop overriding their choice.
  bool _categoryTouched = false;

  /// Category id auto-applied from the note's keywords — drives the
  /// "disarankan" hint next to the Kategori eyebrow.
  String? _suggestedCategoryId;

  /// Payment defaults wait until the last-used prefs have loaded, so a
  /// remembered account/card wins over "first in list".
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _amount = init.amount;
      _categoryId = init.categoryId;
      _payType = init.cardId != null ? 'credit' : 'cash';
      _sourceAccountId = init.sourceAccountId;
      _cardId = init.cardId;
      _spentBy = init.spentBy;
      _date = init.date;
      _note.text = init.note ?? '';
      _recurring = init.recurring;
      _cicilan = init.installmentPlanId != null;
      _categoryTouched = true;
      _prefsLoaded = true;
    } else {
      _note.addListener(_onNoteChanged);
      // ignore: discarded_futures
      SharedPreferences.getInstance().then((p) {
        if (!mounted) return;
        setState(() {
          _prefsLoaded = true;
          final pt = p.getString(_kLastPayType);
          if (pt == 'cash' || pt == 'credit') _payType = pt!;
          _sourceAccountId ??= p.getString(_kLastAccount);
          _cardId ??= p.getString(_kLastCard);
        });
      });
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

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
      setState(() {
        _categoryId = next;
        _suggestedCategoryId = next;
      });
    }
  }

  /// Most frequently used active category this cycle (ties → first hit).
  static String? _mostUsedCategoryId(
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
    if (picked != null) setState(() => _date = picked);
  }

  /// Isi form dari chip favorit (1-tap).
  void _applyFavorite(FavoriteExpense f) {
    setState(() {
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
    setState(() {
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
      setState(() => _error = 'Pilih kartu kredit dulu');
      return;
    }
    final hasAccounts =
        h.cashAccounts.isNotEmpty || h.savingsAccounts.isNotEmpty;
    if (_payType == 'cash' && hasAccounts && _sourceAccountId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih sumber dana dulu');
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
      setState(() => _error = 'Lengkapi jumlah & kategori');
      return;
    }
    if (_payType == 'credit' && _cardId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih kartu kredit');
      return;
    }
    final hasAccounts =
        h.cashAccounts.isNotEmpty || h.savingsAccounts.isNotEmpty;
    if (_payType == 'cash' && hasAccounts && _sourceAccountId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih sumber dana');
      return;
    }
    FtHaptics.tap();
    setState(() {
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
      setState(() => _error = msg);
    } catch (e) {
      FtHaptics.error();
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _spentBy ??= user.uid;
    final categories =
        household.categories.where((c) => !c.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // Smart default: most-used category this cycle (falls back to the first
    // chip). Keeps re-evaluating until the user taps a chip or a keyword
    // suggestion kicks in, so it still applies once the stream loads.
    if (!_categoryTouched && _suggestedCategoryId == null &&
        categories.isNotEmpty) {
      final cycleExpenses =
          ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
      _categoryId =
          _mostUsedCategoryId(cycleExpenses, categories) ?? categories.first.id;
    } else if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    final cards = ref.watch(cardsProvider(household.id)).value ?? const [];
    // Drop a remembered card that no longer exists, then default.
    if (!widget.isEdit &&
        cards.isNotEmpty &&
        _cardId != null &&
        cards.every((c) => c.id != _cardId)) {
      _cardId = null;
    }
    if (_prefsLoaded &&
        _payType == 'credit' &&
        _cardId == null &&
        cards.isNotEmpty) {
      _cardId = cards.first.id;
      _cicilanApr = cards.first.apr;
    }
    // Remembered card applied from prefs skips the default branch above —
    // sync its APR for the cicilan preview.
    if (_payType == 'credit' && _cardId != null && !_cicilan &&
        _cicilanApr == 0.0) {
      for (final c in cards) {
        if (c.id == _cardId) {
          _cicilanApr = c.apr;
          break;
        }
      }
    }
    final cicilanLock = widget.isCicilan;
    final sourceAccounts = recordAccountChoices(
      cashAccounts: household.cashAccounts,
      savingsAccounts: household.savingsAccounts,
    );
    // Drop a remembered account that no longer exists, then default.
    if (!widget.isEdit &&
        _sourceAccountId != null &&
        sourceAccounts.every((a) => a.id != _sourceAccountId)) {
      _sourceAccountId = null;
    }
    if (_prefsLoaded &&
        _payType == 'cash' &&
        _sourceAccountId == null &&
        sourceAccounts.isNotEmpty) {
      _sourceAccountId = sourceAccounts.first.id;
    }
    final canSubmit = _amount > 0 &&
        _categoryId != null &&
        ref.watch(canRecordTxnProvider) &&
        (_payType == 'credit' ||
            sourceAccounts.isEmpty ||
            _sourceAccountId != null);

    return Scaffold(
      backgroundColor: FtColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
        child: Column(
          children: [
            FtSubHeader(
              title: widget.isEdit ? 'Edit pengeluaran' : 'Catat pengeluaran',
              trailing: FtSubmitDot(
                busy: _busy,
                enabled: canSubmit,
                onTap: () => _submit(household, cards),
              ),
            ),
            Expanded(
              child: FtFadeUp(
                duration: const Duration(milliseconds: 320),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    if (cicilanLock) ...[
                      _CicilanLockedBanner(),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.isEdit)
                      ExpenseFavoritesRow(
                        categories: categories,
                        onPick: _applyFavorite,
                      ),
                    AbsorbPointer(
                      absorbing: cicilanLock,
                      child: Opacity(
                        opacity: cicilanLock ? 0.5 : 1,
                        child: MoneyField(
                          amount: _amount,
                          calculator: true,
                          onChanged: (v) => setState(() => _amount = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Eyebrow('Kategori'),
                        if (_suggestedCategoryId != null &&
                            _suggestedCategoryId == _categoryId) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome,
                              size: 11, color: FtColors.clay),
                          const SizedBox(width: 3),
                          Text(
                            'disarankan dari catatan',
                            style: TextStyle(
                              fontSize: 10,
                              color: FtColors.ink3,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    CategoryChipRow(
                      categories: categories,
                      selected: _categoryId,
                      onSelect: (id) {
                        FtHaptics.select();
                        setState(() {
                          _categoryId = id;
                          _categoryTouched = true;
                          _suggestedCategoryId = null;
                        });
                      },
                    ),
                    // Split: belanja campur (struk supermarket dll) dibagi ke
                    // beberapa kategori sekaligus.
                    if (!widget.isEdit && !_cicilan && _amount > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              _busy ? null : () => _openSplit(household),
                          icon: const Icon(Icons.call_split_rounded,
                              size: 15),
                          label: const Text(
                            'Split ke beberapa kategori',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    const Eyebrow('Pembayaran'),
                    const SizedBox(height: 10),
                    AbsorbPointer(
                      absorbing: cicilanLock,
                      child: Opacity(
                        opacity: cicilanLock ? 0.5 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PayTypeToggle(
                              value: _payType,
                              onChange: (v) {
                                FtHaptics.select();
                                setState(() => _payType = v);
                              },
                            ),
                            const SizedBox(height: 14),
                            if (_payType == 'cash')
                              RecordAccountDropdownField(
                                accounts: sourceAccounts,
                                selectedId: _sourceAccountId,
                                accent: FtColors.ink,
                                sheetTitle: 'Pilih rekening',
                                onSelect: (id) {
                                  FtHaptics.select();
                                  setState(() => _sourceAccountId = id);
                                },
                                emptyNote:
                                    'Belum ada rekening. Pengeluaran tetap tercatat tapi saldo tidak terpotong. Tambah dari Aset → Tunai.',
                              )
                            else
                              CardPicker(
                                cards: cards,
                                selected: _cardId,
                                onSelect: (id) {
                                  FtHaptics.select();
                                  setState(() {
                                    _cardId = id;
                                    final c = cards
                                        .firstWhere((x) => x.id == id);
                                    _cicilanApr = c.apr;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Cicilan picker only shown when creating a new credit
                    // expense — in edit mode the plan is immutable.
                    if (!widget.isEdit &&
                        _payType == 'credit' &&
                        cards.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Eyebrow('Cicilan'),
                      const SizedBox(height: 10),
                      InstallmentPlans(
                        cicilan: _cicilan,
                        months: _cicilanMonths,
                        apr: _cicilanApr,
                        onSelect: (months, apr) {
                          FtHaptics.select();
                          setState(() {
                            _cicilan = months > 1;
                            _cicilanMonths = months > 1 ? months : 6;
                            _cicilanApr = apr;
                          });
                        },
                      ),
                      if (_cicilan && _amount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: InstallmentPreview(
                            amount: _amount,
                            months: _cicilanMonths,
                            apr: _cicilanApr,
                          ),
                        ),
                    ],
                    const SizedBox(height: 22),
                    FtInput(
                      label: 'Catatan (opsional)',
                      controller: _note,
                      hintText: 'Misal: Kopi Tuku',
                    ),
                    const SizedBox(height: 14),
                    RecordMetaRow(
                      date: _date,
                      recurring: _recurring,
                      onPickDate: _pickDate,
                      onToggleRecurring: _cicilan
                          ? null
                          : (v) {
                              FtHaptics.select();
                              setState(() => _recurring = v);
                            },
                    ),
                    if (!widget.isEdit) ...[
                      const SizedBox(height: 10),
                      _QuickDateChips(
                        selected: _date,
                        onPick: (d) {
                          FtHaptics.select();
                          setState(() => _date = d);
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kategori, tanggal, dan detail bisa diubah kapan saja.',
                        style: TextStyle(
                          color: FtColors.ink4,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                      ),
                    ],
                    if (!widget.isEdit) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (canSubmit && !_busy)
                                  ? () => _submit(household, cards,
                                      addAnother: true)
                                  : null,
                              icon: const Icon(Icons.playlist_add_rounded,
                                  size: 18),
                              label: const Text('Simpan & tambah lagi'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: (_amount > 0 && _categoryId != null)
                                ? _saveFavorite
                                : null,
                            tooltip: 'Jadikan favorit',
                            icon: Icon(
                              Icons.star_border_rounded,
                              color: FtColors.clay,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Chip tanggal cepat — Hari ini / Kemarin / 2 hari lalu. Desain
/// "catch-up": kebanyakan orang mencatat rapel, bukan harian.
class _QuickDateChips extends StatelessWidget {
  const _QuickDateChips({required this.selected, required this.onPick});

  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final options = [
      (label: 'Hari ini', date: now),
      (label: 'Kemarin', date: now.subtract(const Duration(days: 1))),
      (label: '2 hari lalu', date: now.subtract(const Duration(days: 2))),
    ];
    final selKey = DateTime(selected.year, selected.month, selected.day);
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onPick(o.date),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: DateTime(o.date.year, o.date.month, o.date.day) ==
                          selKey
                      ? FtColors.ink
                      : FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: FtColors.line, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: DateTime(
                                o.date.year, o.date.month, o.date.day) ==
                            selKey
                        ? FtColors.bg
                        : FtColors.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (o != options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _CicilanLockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: FtColors.plum.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FtColors.plum.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 16, color: FtColors.plum),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cicilan: hanya kategori, catatan, tanggal & pencatat yang bisa diubah. Hapus & catat ulang untuk ubah jumlah/kartu.',
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

