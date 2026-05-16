import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../household/household_providers.dart';
import 'expense_repository.dart';

class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  ConsumerState<RecordExpenseScreen> createState() =>
      _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _categoryId;
  String? _methodId;
  String? _spentBy;
  String? _cardId;
  DateTime _date = DateTime.now();
  bool _recurring = false;
  bool _cicilan = false;
  int _cicilanMonths = 6;
  double _cicilanApr = 0.0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(List<CreditCard> cards) async {
    final household = ref.read(currentHouseholdProvider).value;
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (household == null || user == null) return;
    if (!_formKey.currentState!.validate() ||
        _categoryId == null ||
        _methodId == null ||
        _spentBy == null) {
      setState(() => _error = 'Lengkapi semua field');
      return;
    }
    final amount = Money.parse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Nominal tidak valid');
      return;
    }
    final method = household.paymentMethodOf(_methodId!);
    final isCredit = method?.type == 'credit';
    if (isCredit && _cardId == null) {
      setState(() => _error = 'Pilih kartu kredit');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(expenseRepositoryProvider);
      if (isCredit && _cicilan) {
        await repo.addCicilanExpense(
          householdId: household.id,
          principal: amount,
          categoryId: _categoryId!,
          paymentMethodId: _methodId!,
          spentBy: _spentBy!,
          date: _date,
          cardId: _cardId!,
          months: _cicilanMonths,
          apr: _cicilanApr,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      } else if (isCredit) {
        await repo.addCardExpense(
          householdId: household.id,
          amount: amount,
          categoryId: _categoryId!,
          paymentMethodId: _methodId!,
          spentBy: _spentBy!,
          date: _date,
          cardId: _cardId!,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          recurring: _recurring,
        );
      } else {
        await repo.add(
          householdId: household.id,
          amount: amount,
          categoryId: _categoryId!,
          paymentMethodId: _methodId!,
          spentBy: _spentBy!,
          date: _date,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          recurring: _recurring,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
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
    final categories = household.categories.where((c) => !c.archived).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final cards = ref.watch(cardsProvider(household.id)).value ?? const [];
    final method = _methodId != null
        ? household.paymentMethodOf(_methodId!)
        : null;
    final isCredit = method?.type == 'credit';

    // Preview cicilan calc
    CicilanPlan? preview;
    final amt = Money.parse(_amount.text);
    if (_cicilan && amt != null && amt > 0) {
      try {
        preview = computeCicilan(
          principal: amt,
          months: _cicilanMonths,
          apr: _cicilanApr,
        );
      } on ArgumentError {
        preview = null;
      }
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            FtSubHeader(
              title: 'Catat pengeluaran',
              trailing: IconButton.filled(
                tooltip: 'Simpan',
                onPressed: _busy ? null : () => _submit(cards),
                icon: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    FtCard(
                      child: Column(
                        children: [
                          const Eyebrow('Jumlah'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _amount,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Nominal',
                              prefixText: 'Rp ',
                            ),
                            style: Theme.of(context).textTheme.headlineMedium,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final a = Money.parse(v ?? '');
                              return (a == null || a <= 0)
                                  ? 'Wajib diisi'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? 'Pilih kategori' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _methodId,
                      decoration: const InputDecoration(
                        labelText: 'Metode bayar',
                      ),
                      items: household.paymentMethods
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _methodId = v;
                        // Reset card-only fields when switching methods.
                        if (household.paymentMethodOf(v ?? '')?.type !=
                            'credit') {
                          _cardId = null;
                          _cicilan = false;
                        }
                      }),
                      validator: (v) => v == null ? 'Pilih metode' : null,
                    ),
                    if (isCredit) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _cardId,
                        decoration: const InputDecoration(
                          labelText: 'Kartu kredit',
                        ),
                        items: cards
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.label} (${Money.format(c.limit - c.used)} tersedia)',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _cardId = v;
                          final c = cards.where((x) => x.id == v).toList();
                          if (c.isNotEmpty) _cicilanApr = c.first.apr;
                        }),
                        validator: (v) =>
                            isCredit && v == null ? 'Pilih kartu' : null,
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cicilan (POS)'),
                        subtitle: const Text(
                          'Bagi pembelian jadi cicilan bulanan',
                        ),
                        value: _cicilan,
                        onChanged: cards.isEmpty
                            ? null
                            : (v) => setState(() => _cicilan = v),
                      ),
                      if (_cicilan) ...[
                        Row(
                          children: [
                            const Text('Tenor:'),
                            const SizedBox(width: 8),
                            ...[3, 6, 12, 24].map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text('${n}x'),
                                  selected: _cicilanMonths == n,
                                  onSelected: (_) =>
                                      setState(() => _cicilanMonths = n),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bunga: ${(_cicilanApr * 100).toStringAsFixed(1)}% / tahun (flat)',
                        ),
                        Slider(
                          value: _cicilanApr,
                          min: 0,
                          max: 0.50,
                          divisions: 50,
                          label: '${(_cicilanApr * 100).toStringAsFixed(0)}%',
                          onChanged: (v) => setState(() => _cicilanApr = v),
                        ),
                        if (preview != null)
                          FtCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cicilan: ${Money.format(preview.monthly)} / bln × $_cicilanMonths bln',
                                ),
                                Text(
                                  'Total: ${Money.format(preview.total)} (bunga ${Money.format(preview.totalInterest)})',
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _spentBy,
                      decoration: const InputDecoration(
                        labelText: 'Dibayar oleh',
                      ),
                      items: household.members
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.userId,
                              child: Text(m.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _spentBy = v),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal'),
                        child: Text(Dates.short(_date)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_cicilan)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pengeluaran berulang'),
                        value: _recurring,
                        onChanged: (v) => setState(() => _recurring = v),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: FtColors.danger),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : () => _submit(cards),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
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
