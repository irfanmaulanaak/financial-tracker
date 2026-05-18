import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters.dart';
import '../account.dart';

class AccountDraft {
  final AccountKind kind;
  final AccountSubKind subKind;
  final String label;
  final String? hint;
  final int value;
  final bool deltaMode;
  const AccountDraft({
    required this.kind,
    required this.label,
    required this.hint,
    required this.value,
    this.subKind = AccountSubKind.bank,
    this.deltaMode = false,
  });
}

/// Variant of `ThousandsSeparatorFormatter` that keeps a leading minus sign
/// so the delta input can express "kurang" amounts.
class _SignedThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final negative = raw.startsWith('-');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      final text = negative ? '-' : '';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    final grouped = Money.format(int.parse(digits))
        .replaceFirst(RegExp(r'^Rp\s*'), '');
    final text = negative ? '-$grouped' : grouped;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class AccountEditSheet extends StatefulWidget {
  const AccountEditSheet({super.key, this.initial, this.initialKind});
  final Account? initial;
  final AccountKind? initialKind;

  @override
  State<AccountEditSheet> createState() => _AccountEditSheetState();
}

class _AccountEditSheetState extends State<AccountEditSheet> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _hint = TextEditingController(text: widget.initial?.hint ?? '');
  late final _value = TextEditingController(
    text: widget.initial != null
        ? Money.displayDigits(widget.initial!.value)
        : '',
  );
  late final _delta = TextEditingController();
  AccountKind _kind = AccountKind.cash;
  AccountSubKind _subKind = AccountSubKind.bank;
  bool _deltaMode = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initial?.kind ?? widget.initialKind ?? AccountKind.cash;
    _subKind = widget.initial?.subKind ?? AccountSubKind.bank;
  }

  @override
  void dispose() {
    _label.dispose();
    _hint.dispose();
    _value.dispose();
    _delta.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty && widget.initial == null) return;
    final hint = _hint.text.trim().isEmpty ? null : _hint.text.trim();

    if (_deltaMode) {
      final raw = _delta.text.trim();
      if (raw.isEmpty) return;
      final negative = raw.startsWith('-');
      final magnitude = Money.parse(raw) ?? 0;
      final delta = negative ? -magnitude : magnitude;
      if (delta == 0) return;
      Navigator.pop(
        context,
        AccountDraft(
          kind: _kind,
          subKind: _subKind,
          label: label,
          hint: hint,
          value: delta,
          deltaMode: true,
        ),
      );
    } else {
      final value = Money.parse(_value.text) ?? 0;
      Navigator.pop(
        context,
        AccountDraft(
          kind: _kind,
          subKind: _subKind,
          label: label,
          hint: hint,
          value: value,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              isEdit ? 'Edit akun' : 'Akun baru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<AccountKind>(
              segments: const [
                ButtonSegment(
                  value: AccountKind.cash,
                  label: Text('Tunai/Debit'),
                ),
                ButtonSegment(
                  value: AccountKind.savings,
                  label: Text('Tabungan'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            if (_kind == AccountKind.cash) ...[
              SegmentedButton<AccountSubKind>(
                segments: const [
                  ButtonSegment(
                    value: AccountSubKind.bank,
                    label: Text('Bank'),
                  ),
                  ButtonSegment(
                    value: AccountSubKind.ewallet,
                    label: Text('E-wallet'),
                  ),
                ],
                selected: {_subKind},
                onSelectionChanged: (s) => setState(() => _subKind = s.first),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama akun'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hint,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'mis. BCA 1234',
              ),
            ),
            const SizedBox(height: 16),
            if (isEdit)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Set saldo')),
                  ButtonSegment(value: true, label: Text('Tambah / kurang')),
                ],
                selected: {_deltaMode},
                onSelectionChanged: (s) => setState(() => _deltaMode = s.first),
              ),
            const SizedBox(height: 12),
            if (_deltaMode)
              TextField(
                controller: _delta,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\-\d.]')),
                  _SignedThousandsFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Delta',
                  prefixText: 'Rp ',
                  helperText: 'gunakan tanda minus untuk kurang',
                ),
              )
            else
              TextField(
                controller: _value,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Saldo',
                  prefixText: 'Rp ',
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    ),
  );
  }
}
