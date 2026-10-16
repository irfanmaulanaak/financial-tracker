import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/providers.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household_providers.dart';
import '../debt.dart';
import '../debt_repository.dart';

/// Aksi untuk satu catatan: bayar sebagian, tandai lunas, hapus.
class DebtActionsSheet extends ConsumerStatefulWidget {
  const DebtActionsSheet({super.key, required this.debt});
  final Debt debt;

  static Future<void> show(BuildContext context, Debt debt) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebtActionsSheet(debt: debt),
    );
  }

  @override
  ConsumerState<DebtActionsSheet> createState() => _DebtActionsSheetState();
}

class _DebtActionsSheetState extends ConsumerState<DebtActionsSheet> {
  final _payment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() op, String errPrefix) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;
    setState(() => _busy = true);
    try {
      await op();
      if (mounted) {
        FtHaptics.success();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showFtErrorSnack(context, e, prefix: errPrefix);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.debt;
    final hid = ref.watch(currentHouseholdProvider).value?.id;
    final repo = ref.read(debtRepositoryProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(d.counterparty,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Sisa ${Money.format(d.remaining)} dari ${Money.format(d.amount)}',
              style: TextStyle(color: FtColors.ink3, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _payment,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah pembayaran',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy || hid == null
                  ? null
                  : () {
                      final v = Money.parse(_payment.text) ?? 0;
                      if (v <= 0) return;
                      _run(
                        () => repo.addPayment(
                            householdId: hid, debtId: d.id, payment: v),
                        'Gagal mencatat pembayaran',
                      );
                    },
              child: const Text('Catat pembayaran'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy || hid == null
                  ? null
                  : () => _run(
                        () => repo.addPayment(
                            householdId: hid,
                            debtId: d.id,
                            payment: d.remaining),
                        'Gagal menandai lunas',
                      ),
              child: const Text('Tandai lunas'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy || hid == null
                  ? null
                  : () => _run(
                        () => repo.delete(householdId: hid, debtId: d.id),
                        'Gagal menghapus catatan',
                      ),
              style: TextButton.styleFrom(foregroundColor: FtColors.danger),
              child: const Text('Hapus catatan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet tambah catatan baru.
class AddDebtSheet extends ConsumerStatefulWidget {
  const AddDebtSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDebtSheet(),
    );
  }

  @override
  ConsumerState<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<AddDebtSheet> {
  DebtType _type = DebtType.utang;
  final _who = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime? _due;
  bool _busy = false;

  @override
  void dispose() {
    _who.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final household = ref.read(currentHouseholdProvider).value;
    final uid = ref.read(authStateProvider).value?.uid;
    if (household == null || uid == null) return;
    final amount = Money.parse(_amount.text) ?? 0;
    final who = _who.text.trim();
    if (amount <= 0 || who.isEmpty) {
      showFtInfoSnack(context, 'Isi nama dan jumlah dulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(debtRepositoryProvider).add(
            householdId: household.id,
            type: _type,
            counterparty: who,
            amount: amount,
            createdBy: uid,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            dueDate: _due,
          );
      if (mounted) {
        FtHaptics.success();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showFtErrorSnack(context, e, prefix: 'Gagal menyimpan');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Catat utang/piutang',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Row(
              children: [
                _TypeChip(
                  label: 'Utang kami',
                  selected: _type == DebtType.utang,
                  onTap: () => setState(() => _type = DebtType.utang),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Piutang ke kami',
                  selected: _type == DebtType.piutang,
                  onTap: () => setState(() => _type = DebtType.piutang),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _who,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _type == DebtType.utang
                    ? 'Berutang kepada'
                    : 'Yang berutang',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _due == null
                        ? 'Tanpa jatuh tempo'
                        : 'Jatuh tempo ${Dates.short(_due!)}',
                    style: TextStyle(color: FtColors.ink2, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _due ?? now.add(const Duration(days: 30)),
                      firstDate: now.subtract(const Duration(days: 365)),
                      lastDate: now.add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setState(() => _due = picked);
                  },
                  child: Text(_due == null ? 'Pilih tanggal' : 'Ubah'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FtTapScale(
        onTap: () {
          FtHaptics.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? FtColors.clay.withValues(alpha: 0.14)
                : FtColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? FtColors.clay : FtColors.line,
              width: selected ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? FtColors.clay : FtColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
