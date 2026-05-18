import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../record_common/installment_picker.dart';
import 'credit_card.dart';

class CicilanPlanDraft {
  final int principal;
  final int months;
  final double apr;
  final String label;

  /// Optional new transaction date. When set, the repo retroactively shifts
  /// the cicilan's `startedAt` (and the linked expense's `date`) so the
  /// BCA-style billing math anchors on the corrected day.
  final DateTime? newDate;
  const CicilanPlanDraft({
    required this.principal,
    required this.months,
    required this.apr,
    required this.label,
    this.newDate,
  });
}

/// Bottom sheet for editing an existing cicilan plan: principal, months,
/// APR, and label. Returns a [CicilanPlanDraft] on save (or null on cancel).
///
/// Saving recomputes the plan from these inputs; the repo recalibrates
/// `card.used` and resets `monthsPaid` to 0 — so this is intended for
/// correcting a mistake, not paying down a partially-paid plan.
class EditCicilanSheet extends StatefulWidget {
  const EditCicilanSheet({
    super.key,
    required this.initial,
    required this.cardApr,
  });

  final Installment initial;

  /// APR fallback when the user picks the 12× plan but hasn't typed an
  /// override — mirrors the 12× chip in the record-expense flow.
  final double cardApr;

  @override
  State<EditCicilanSheet> createState() => _EditCicilanSheetState();
}

class _EditCicilanSheetState extends State<EditCicilanSheet> {
  late final _label = TextEditingController(text: widget.initial.label);
  // Seed principal with the stored `total`. The Installment doc doesn't
  // persist the original principal/apr, so this is the best baseline; user
  // re-enters the actual principal + picks tenor as needed.
  late final _principal =
      TextEditingController(text: Money.displayDigits(widget.initial.total));
  late int _months = widget.initial.monthsTotal;
  late double _apr = widget.cardApr;
  late DateTime _date = widget.initial.startedAt;

  @override
  void dispose() {
    _label.dispose();
    _principal.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final principal = Money.parse(_principal.text) ?? 0;
    if (principal <= 0 || _label.text.trim().isEmpty) return;
    final dateChanged = !_sameDay(_date, widget.initial.startedAt);
    Navigator.pop(
      context,
      CicilanPlanDraft(
        principal: principal,
        months: _months,
        apr: _months >= 12 ? _apr : 0.0,
        label: _label.text.trim(),
        newDate: dateChanged ? _date : null,
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final principalInt = Money.parse(_principal.text) ?? 0;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit cicilan',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Mengubah plan akan reset progres dan menghitung ulang sisa tagihan kartu.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Contoh: HP iPhone',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _principal,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Pokok pembelian',
                prefixText: 'Rp ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal transaksi',
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(DateFormat('d MMM yyyy', 'id_ID').format(_date)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tenor', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            InstallmentPlans(
              cicilan: true,
              months: _months,
              apr: _apr,
              onSelect: (m, a) => setState(() {
                _months = m;
                _apr = a;
              }),
            ),
            if (principalInt > 0) ...[
              const SizedBox(height: 12),
              InstallmentPreview(
                amount: principalInt,
                months: _months,
                apr: _apr,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
