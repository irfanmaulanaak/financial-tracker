import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../theme.dart';
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
import 'expense_repository.dart';

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
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
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

  Future<void> _submit(Household h, List<CreditCard> cards) async {
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
      } else if (_payType == 'credit' && _cicilan) {
        await repo.addCicilanExpense(
          householdId: h.id,
          principal: _amount,
          categoryId: _categoryId!,
          spentBy: spentBy,
          date: _date,
          cardId: _cardId!,
          months: _cicilanMonths,
          apr: _cicilanApr,
          note: note,
        );
      } else if (_payType == 'credit') {
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
      if (mounted) {
        FtHaptics.success();
        context.pop();
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
    // Default-select the first category so the form starts in a valid state.
    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    final cards = ref.watch(cardsProvider(household.id)).value ?? const [];
    if (_payType == 'credit' && _cardId == null && cards.isNotEmpty) {
      _cardId = cards.first.id;
      _cicilanApr = cards.first.apr;
    }
    final cicilanLock = widget.isCicilan;
    final sourceAccounts = recordAccountChoices(
      cashAccounts: household.cashAccounts,
      savingsAccounts: household.savingsAccounts,
    );
    if (_payType == 'cash' &&
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
                    AbsorbPointer(
                      absorbing: cicilanLock,
                      child: Opacity(
                        opacity: cicilanLock ? 0.5 : 1,
                        child: MoneyField(
                          amount: _amount,
                          onChanged: (v) => setState(() => _amount = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Eyebrow('Kategori'),
                    const SizedBox(height: 10),
                    CategoryChipRow(
                      categories: categories,
                      selected: _categoryId,
                      onSelect: (id) {
                        FtHaptics.select();
                        setState(() => _categoryId = id);
                      },
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
                              RecordAccountPicker(
                                accounts: sourceAccounts,
                                selectedId: _sourceAccountId,
                                accent: FtColors.ink,
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
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

