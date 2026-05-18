import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import 'credit_card.dart';

class CardDraft {
  final String ownerId;
  final String label;
  final String last4;
  final int limit;
  final int dueDay;
  final double apr;
  final String accent;
  final double minPaymentPct;
  const CardDraft({
    required this.ownerId,
    required this.label,
    required this.last4,
    required this.limit,
    required this.dueDay,
    required this.apr,
    required this.accent,
    required this.minPaymentPct,
  });
}

class EditCardSheet extends ConsumerStatefulWidget {
  const EditCardSheet({
    super.key,
    this.initial,
    this.defaultOwnerId,
  });
  final CreditCard? initial;
  final String? defaultOwnerId;

  @override
  ConsumerState<EditCardSheet> createState() => _EditCardSheetState();
}

class _EditCardSheetState extends ConsumerState<EditCardSheet> {
  late final _label =
      TextEditingController(text: widget.initial?.label ?? '');
  late final _last4 =
      TextEditingController(text: widget.initial?.last4 ?? '');
  late final _limit = TextEditingController(
      text: widget.initial != null
          ? Money.displayDigits(widget.initial!.limit)
          : '');
  late int _dueDay = widget.initial?.dueDay ?? 25;
  late double _apr = widget.initial?.apr ?? 0.18;
  late double _minPct = widget.initial?.minPaymentPct ?? 0.10;
  late String _accent = widget.initial?.accent ?? '#3B82F6';
  late String? _ownerId =
      widget.initial?.ownerId ?? widget.defaultOwnerId;

  static const _accents = [
    '#3B82F6',
    '#10B981',
    '#EC4899',
    '#F59E0B',
    '#8B5CF6',
    '#0EA5E9',
    '#64748B',
  ];

  @override
  void dispose() {
    _label.dispose();
    _last4.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _save() {
    if (_label.text.trim().isEmpty || _ownerId == null) return;
    final limit = Money.parse(_limit.text) ?? 0;
    if (limit <= 0) return;
    Navigator.pop(
      context,
      CardDraft(
        ownerId: _ownerId!,
        label: _label.text.trim(),
        last4: _last4.text.trim(),
        limit: limit,
        dueDay: _dueDay,
        apr: _apr,
        accent: _accent,
        minPaymentPct: _minPct,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final members = household?.members ?? const [];
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
            Text(widget.initial == null ? 'Kartu baru' : 'Edit kartu',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: 'Nama kartu', hintText: 'BCA Visa'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _last4,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '4 digit terakhir (opsional)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _limit,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Limit kartu',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _ownerId,
              decoration: const InputDecoration(labelText: 'Pemilik kartu'),
              items: members
                  .map((m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(prettyName(m.displayName)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _ownerId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: Text('Jatuh tempo: tanggal $_dueDay',
                        style: const TextStyle(fontSize: 14))),
              ],
            ),
            Slider(
              value: _dueDay.toDouble(),
              min: 1,
              max: 31,
              divisions: 30,
              label: '$_dueDay',
              onChanged: (v) => setState(() => _dueDay = v.round()),
            ),
            Text('APR: ${(_apr * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14)),
            Slider(
              value: _apr,
              min: 0,
              max: 0.50,
              divisions: 50,
              label: '${(_apr * 100).toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _apr = v),
            ),
            Text('Min payment: ${(_minPct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14)),
            Slider(
              value: _minPct,
              min: 0.05,
              max: 0.50,
              divisions: 9,
              label: '${(_minPct * 100).toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _minPct = v),
            ),
            const SizedBox(height: 8),
            const Text('Warna'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _accents)
                  GestureDetector(
                    onTap: () => setState(() => _accent = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(c),
                        shape: BoxShape.circle,
                        border: _accent == c
                            ? Border.all(width: 3, color: Colors.black)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
