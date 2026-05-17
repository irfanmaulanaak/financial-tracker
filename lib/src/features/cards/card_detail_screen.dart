import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'credit_card.dart';
import 'card_repository.dart';
import 'edit_card_sheet.dart';
import 'widgets/card_detail_header.dart';
import 'widgets/installment_list.dart';

final _cardProvider =
    StreamProvider.family<CreditCard?, ({String hid, String cardId})>((ref, p) {
      return ref
          .watch(cardRepositoryProvider)
          .watchOne(hid: p.hid, cardId: p.cardId);
    });

// Per-card installments stream lives in `widgets/installment_list.dart` so
// every consumer (cards screen, card detail, home preview) shares a single
// Firestore subscription per (hid, cardId).

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cardAsync = ref.watch(
      _cardProvider((hid: household.id, cardId: cardId)),
    );
    final installmentsAsync = ref.watch(
      cardInstallmentsProvider((hid: household.id, cardId: cardId)),
    );

    Future<void> editCard(CreditCard c) async {
      final result = await showModalBottomSheet<CardDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EditCardSheet(initial: c),
      );
      if (result == null) return;
      await ref
          .read(cardRepositoryProvider)
          .updateCard(
            hid: household.id,
            cardId: cardId,
            label: result.label,
            last4: result.last4,
            limit: result.limit,
            dueDay: result.dueDay,
            apr: result.apr,
            accent: result.accent,
            minPaymentPct: result.minPaymentPct,
          );
    }

    Future<void> deleteCard(CreditCard c) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus kartu?'),
          content: Text(
            'Kartu "${c.label}" akan dihapus permanen.\n'
            'Riwayat pengeluaran tetap tersimpan.',
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
        await ref
            .read(cardRepositoryProvider)
            .deleteCard(hid: household.id, cardId: cardId);
        if (context.mounted) context.pop();
      } on StateError catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_deleteErrorMessage(e.message))),
        );
      }
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (card) {
          if (card == null) {
            return const SafeArea(
              child: Column(
                children: [
                  FtSubHeader(title: 'Kartu'),
                  Expanded(
                    child: Center(child: Text('Kartu tidak ditemukan.')),
                  ),
                ],
              ),
            );
          }
          final minPay = minimumPayment(
            balance: card.used,
            minPaymentPct: card.minPaymentPct,
          );
          final available = (card.limit - card.used).clamp(0, card.limit);
          return SafeArea(
            child: FtAppChrome(
              current: FtTab.cards,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  FtSubHeader(
                    title: card.label,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Edit',
                          onPressed: () => editCard(card),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Hapus',
                          onPressed: () => deleteCard(card),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: FtColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CardDetailHeader(card: card, available: available),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: card.used == 0
                              ? null
                              : () => _confirm(
                                  context,
                                  'Bayar minimum (${Money.format(minPay)})?',
                                  () async {
                                    await ref
                                        .read(cardRepositoryProvider)
                                        .payMinimum(
                                          hid: household.id,
                                          cardId: cardId,
                                        );
                                  },
                                ),
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          label: Text('Min ${Money.format(minPay)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: card.used == 0
                              ? null
                              : () => _confirm(
                                  context,
                                  'Bayar lunas (${Money.format(card.used)})?',
                                  () async {
                                    await ref
                                        .read(cardRepositoryProvider)
                                        .payFull(
                                          hid: household.id,
                                          cardId: cardId,
                                        );
                                  },
                                ),
                          icon: const Icon(Icons.check),
                          label: Text('Lunasi ${Money.format(card.used)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const FtSectionHeader(title: 'Cicilan aktif'),
                  ...installmentsAsync.maybeWhen(
                    data: (items) => items.isEmpty
                        ? [
                            FtCard(
                              child: Center(
                                child: Text(
                                  'Belum ada cicilan.',
                                  style: TextStyle(color: FtColors.ink3),
                                ),
                              ),
                            ),
                          ]
                        : items
                              .map(
                                (i) => CardInstallmentTile(
                                  inst: i,
                                  onPaidOne: () => ref
                                      .read(cardRepositoryProvider)
                                      .incrementInstallment(
                                        hid: household.id,
                                        cardId: cardId,
                                        installmentId: i.id,
                                      ),
                                ),
                              )
                              .toList(),
                    orElse: () => const [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await action();
    }
  }
}

String _deleteErrorMessage(String? code) {
  switch (code) {
    case 'card_has_balance':
      return 'Tidak bisa hapus: kartu masih punya saldo terpakai. '
          'Lunasi dulu lewat tombol "Lunasi".';
    case 'card_has_active_installments':
      return 'Tidak bisa hapus: ada cicilan yang belum selesai.';
    case 'card_missing':
      return 'Kartu sudah tidak ada.';
    default:
      return 'Gagal menghapus kartu.';
  }
}
