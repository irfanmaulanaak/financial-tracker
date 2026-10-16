import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense_repository.dart';
import 'card_repository.dart';
import 'credit_card.dart';
import 'edit_cicilan_sheet.dart';

/// Recalculates the card's two debt figures and reports the delta via a
/// snackbar. Extracted from [CardDetailScreen] to keep that file lean.
Future<void> cardRecalcUsed(
  BuildContext context,
  WidgetRef ref,
  String hid,
  CreditCard card,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hitung ulang terpakai?'),
      content: Text(
        'Dua angka dihitung ulang dari data mentah:\n\n'
        '• "Terpakai": gaya tagihan bank. Cicilan yang sudah melewati '
        'tanggal tutup tagihan (tgl ${card.billingDay}) tapi belum '
        'dibayar, plus transaksi reguler yang belum dibayar.\n'
        '• Total sisa utang: seluruh sisa cicilan (tertagih maupun '
        'belum) plus transaksi reguler. Angka ini yang dipakai kekayaan '
        'bersih, jadi grafik tidak lompat di tanggal cetak.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hitung ulang'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final newUsed = await ref
        .read(cardRepositoryProvider)
        .recalcUsed(hid: hid, cardId: card.id);
    if (context.mounted) {
      final delta = newUsed - card.used;
      final msg = delta == 0
          ? 'Sudah sinkron. Terpakai tetap ${Money.format(newUsed)}.'
          : 'Terpakai diperbarui: ${Money.format(card.used)} → ${Money.format(newUsed)} '
              '(${delta > 0 ? '+' : ''}${Money.format(delta)})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      showFtErrorSnack(context, e, prefix: 'Gagal menghitung ulang');
    }
  }
}

Future<void> cardEditInstallment(
  BuildContext context,
  WidgetRef ref,
  String hid,
  CreditCard card,
  Installment inst,
) async {
  final draft = await showModalBottomSheet<CicilanPlanDraft>(
    context: context,
    isScrollControlled: true,
    builder: (_) => EditCicilanSheet(initial: inst, cardApr: card.apr),
  );
  if (draft == null) return;
  try {
    await ref.read(expenseRepositoryProvider).updateCicilanPlan(
          householdId: hid,
          expenseId: inst.expenseId,
          newPrincipal: draft.principal,
          newMonths: draft.months,
          newApr: draft.apr,
          newLabel: draft.label,
          newDate: draft.newDate,
        );
  } catch (e) {
    if (context.mounted) {
      showFtErrorSnack(context, e, prefix: 'Gagal memperbarui cicilan');
    }
  }
}

Future<void> cardDeleteInstallment(
  BuildContext context,
  WidgetRef ref,
  String hid,
  Installment inst,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus cicilan?'),
      content: Text(
        'Cicilan "${inst.label}" akan dihapus.\n'
        'Sisa tagihan ${Money.format(inst.remainingAmount)} akan dikurangi dari kartu.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: FtColors.danger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(expenseRepositoryProvider).delete(
          householdId: hid,
          expenseId: inst.expenseId,
        );
  } catch (e) {
    if (context.mounted) {
      showFtErrorSnack(context, e, prefix: 'Gagal menghapus cicilan');
    }
  }
}
