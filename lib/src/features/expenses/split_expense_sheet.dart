import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/split_expense.dart';
import '../../theme.dart';
import '../../ui/ft_action_sheet.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import 'expense_repository.dart';

/// Sheet split: bagi [total] ke 2-4 kategori. Tiap bagian disimpan sebagai
/// pengeluaran terpisah (tanggal, sumber, pencatat & catatan sama).
class SplitExpenseSheet extends ConsumerStatefulWidget {
  const SplitExpenseSheet({
    super.key,
    required this.household,
    required this.total,
    required this.initialCategoryId,
    required this.payType,
    required this.sourceAccountId,
    required this.cardId,
    required this.spentBy,
    required this.date,
    required this.note,
  });

  final Household household;
  final int total;
  final String? initialCategoryId;
  final String payType; // 'cash' | 'credit'
  final String? sourceAccountId;
  final String? cardId;
  final String spentBy;
  final DateTime date;
  final String? note;

  /// Mengembalikan true bila semua bagian tersimpan.
  static Future<bool?> show(
    BuildContext context, {
    required Household household,
    required int total,
    required String? initialCategoryId,
    required String payType,
    required String? sourceAccountId,
    required String? cardId,
    required String spentBy,
    required DateTime date,
    required String? note,
  }) {
    return showFtActionSheet<bool>(
      context: context,
      builder: (_) => SplitExpenseSheet(
        household: household,
        total: total,
        initialCategoryId: initialCategoryId,
        payType: payType,
        sourceAccountId: sourceAccountId,
        cardId: cardId,
        spentBy: spentBy,
        date: date,
        note: note,
      ),
    );
  }

  @override
  ConsumerState<SplitExpenseSheet> createState() => _SplitExpenseSheetState();
}

class _SplitExpenseSheetState extends ConsumerState<SplitExpenseSheet> {
  static const _maxParts = 4;

  final _rows = <_PartRow>[];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Baris 1 terisi kategori awal + seluruh jumlah; baris 2 kosong.
    _rows.add(_PartRow(categoryId: widget.initialCategoryId,
        amount: widget.total));
    _rows.add(_PartRow());
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  List<SplitPart> get _parts => [
        for (final r in _rows) (categoryId: r.categoryId, amount: r.amount),
      ];

  Future<void> _save() async {
    final code = validateSplit(widget.total, _parts);
    if (code != null) {
      FtHaptics.warning();
      setState(() {
        _error = switch (code) {
          'min_two' => 'Minimal 2 bagian',
          'zero_amount' => 'Semua bagian harus terisi jumlah',
          'no_category' => 'Pilih kategori untuk setiap bagian',
          'over' => 'Total bagian melebihi jumlah transaksi',
          _ => 'Masih ada sisa yang belum dialokasikan',
        };
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(expenseRepositoryProvider);
    var saved = 0;
    try {
      for (final p in _parts) {
        if (widget.payType == 'credit') {
          await repo.addCardExpense(
            householdId: widget.household.id,
            amount: p.amount,
            categoryId: p.categoryId!,
            spentBy: widget.spentBy,
            date: widget.date,
            cardId: widget.cardId!,
            note: widget.note,
            recurring: false,
          );
        } else {
          await repo.add(
            householdId: widget.household.id,
            amount: p.amount,
            categoryId: p.categoryId!,
            spentBy: widget.spentBy,
            date: widget.date,
            sourceAccountId: widget.sourceAccountId,
            note: widget.note,
            recurring: false,
          );
        }
        saved++;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      FtHaptics.error();
      if (mounted) {
        setState(() {
          _busy = false;
          _error = saved > 0
              ? 'Gagal di bagian ${saved + 1}. $saved bagian sudah tersimpan, cek daftar transaksi. ($e)'
              : 'Gagal menyimpan: $e';
        });
      }
    }
  }

  Future<void> _pickCategory(_PartRow row) async {
    final cats = widget.household.categories
        .where((c) => !c.archived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final picked = await showFtActionSheet<Category>(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 4, 6, 12),
              child: Eyebrow('Pilih kategori'),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in cats)
                    FtTapScale(
                      onTap: () => Navigator.of(sheetCtx).pop(c),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: FtColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: FtColors.line, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(iconFor(c.icon),
                                size: 17, color: parseColor(c.color)),
                            const SizedBox(width: 10),
                            Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: FtColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => row.categoryId = picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final remainder = splitRemainder(widget.total, _parts);
    final ready = validateSplit(widget.total, _parts) == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, 8 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Eyebrow('Split ${Money.format(widget.total)}'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
            child: Text(
              'Bagi satu struk ke beberapa kategori. Anggaran tiap kategori tetap akurat.',
              style: TextStyle(color: FtColors.ink3, fontSize: 11.5),
            ),
          ),
          for (final r in _rows) _row(r),
          if (_rows.length < _maxParts)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _rows.add(_PartRow())),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tambah bagian',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  remainder == 0
                      ? 'Semua teralokasi'
                      : remainder > 0
                          ? 'Sisa ${Money.format(remainder)}'
                          : 'Kelebihan ${Money.format(-remainder)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: remainder == 0
                        ? FtColors.moss
                        : remainder > 0
                            ? FtColors.ink2
                            : FtColors.danger,
                  ),
                ),
              ),
              FilledButton(
                onPressed: (_busy || !ready) ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Catat ${_rows.length} pengeluaran'),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: FtColors.danger, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(_PartRow r) {
    final cat =
        r.categoryId == null ? null : widget.household.categoryOf(r.categoryId!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: FtTapScale(
              onTap: () => _pickCategory(r),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FtColors.line, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat != null ? iconFor(cat.icon) : Icons.category_outlined,
                      size: 15,
                      color: cat != null
                          ? parseColor(cat.color)
                          : FtColors.ink3,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat?.label ?? 'Pilih kategori',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: cat != null ? FtColors.ink : FtColors.ink3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextField(
              controller: r.controller,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                prefixText: 'Rp',
                prefixStyle:
                    TextStyle(fontSize: 12, color: FtColors.ink3),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FtColors.line, width: 0.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_rows.length > 2) ...[
            const SizedBox(width: 4),
            FtTapScale(
              onTap: () => setState(() {
                _rows.remove(r);
                r.controller.dispose();
              }),
              child: Icon(Icons.close, size: 16, color: FtColors.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartRow {
  _PartRow({this.categoryId, int amount = 0})
      : controller = TextEditingController(
            text: amount > 0 ? Money.groupDigits(amount) : '');

  String? categoryId;
  final TextEditingController controller;

  int get amount => Money.parse(controller.text) ?? 0;
}
