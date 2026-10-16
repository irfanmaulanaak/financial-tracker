import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_repository.dart';
import '../household/household_providers.dart';
import 'card_detail_actions.dart';
import 'credit_card.dart';
import 'card_repository.dart';
import 'edit_card_sheet.dart';
import 'pay_card_sheet.dart';
import 'pay_installment_sheet.dart';
import 'widgets/card_detail_header.dart';
import 'widgets/card_detail_expenses_list.dart';
import 'widgets/installment_list.dart';

export 'widgets/card_detail_expenses_list.dart';

final _cardProvider =
    StreamProvider.family<CreditCard?, ({String hid, String cardId})>((ref, p) {
      return ref
          .watch(cardRepositoryProvider)
          .watchOne(hid: p.hid, cardId: p.cardId);
    });

/// Latest 20 expenses charged to a single card, cicilan rows included. Used
/// by the "Pengeluaran kartu" section on [CardDetailScreen]: settled cicilan
/// show up as history rows there, while unfinished plans are filtered out in
/// the widget (they live in the "Cicilan aktif" section instead).
final cardExpensesProvider =
    StreamProvider.family<List<Expense>, ({String hid, String cardId})>(
  (ref, p) => ref.watch(expenseRepositoryProvider).watchByCard(
        householdId: p.hid,
        cardId: p.cardId,
        includeCicilan: true,
      ),
);

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
      try {
        await ref
            .read(cardRepositoryProvider)
            .updateCard(
              hid: household.id,
              cardId: cardId,
              label: result.label,
              last4: result.last4,
              limit: result.limit,
              dueDay: result.dueDay,
              billingDay: result.billingDay,
              apr: result.apr,
              accent: result.accent,
              minPaymentPct: result.minPaymentPct,
            );
      } catch (e) {
        if (context.mounted) {
          showFtErrorSnack(context, e, prefix: 'Gagal menyimpan kartu');
        }
      }
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
        showFtErrorSnack(context, cardDeleteErrorMessage(e.message));
      } catch (e) {
        if (!context.mounted) return;
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus kartu');
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
          final available =
              availableLimit(limit: card.limit, outstanding: card.outstanding);
          return SafeArea(
            child: FtAppChrome(
              current: FtTab.cards,
              child: FtRefreshable(
                onRefresh: () async {
                  ref.invalidate(currentHouseholdProvider);
                  ref.invalidate(_cardProvider((hid: household.id, cardId: cardId)));
                  ref.invalidate(cardInstallmentsProvider((hid: household.id, cardId: cardId)));
                  ref.invalidate(cardExpensesProvider((hid: household.id, cardId: cardId)));
                  await ftRefreshDelay();
                },
                child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, kFtFabClearance),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  FtSubHeader(
                    title: card.label,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Hitung ulang terpakai',
                          onPressed: () => cardRecalcUsed(context, ref, household.id, card),
                          icon: const Icon(Icons.sync, size: 18),
                        ),
                        const SizedBox(width: 8),
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
                  FilledButton.icon(
                    onPressed: card.used == 0
                        ? null
                        : () => PayCardSheet.show(
                              context: context,
                              hid: household.id,
                              card: card,
                            ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Bayar tagihan'),
                  ),
                  const SizedBox(height: 24),
                  const FtSectionHeader(title: 'Cicilan aktif'),
                  ...installmentsAsync.maybeWhen(
                    data: (items) {
                      // Settled plans move down into "Pengeluaran kartu".
                      final active =
                          items.where((i) => !i.isComplete).toList();
                      if (active.isEmpty) {
                        return [
                          FtCard(
                            child: Center(
                              child: Text(
                                'Belum ada cicilan aktif.',
                                style: TextStyle(color: FtColors.ink3),
                              ),
                            ),
                          ),
                        ];
                      }
                      final canEdit = ref.watch(canRecordTxnProvider);
                      return active
                          .map(
                            (i) => CardInstallmentTile(
                              inst: i,
                              onPaidOne: () => PayInstallmentSheet.show(
                                context: context,
                                hid: household.id,
                                cardId: cardId,
                                installment: i,
                              ),
                              onEdit: canEdit
                                  ? () => cardEditInstallment(
                                        context,
                                        ref,
                                        household.id,
                                        card,
                                        i,
                                      )
                                  : null,
                              onDelete: canEdit
                                  ? () => cardDeleteInstallment(
                                        context,
                                        ref,
                                        household.id,
                                        i,
                                      )
                                  : null,
                            ),
                          )
                          .toList();
                    },
                    orElse: () => const [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const FtSectionHeader(title: 'Pengeluaran kartu'),
                  CardExpensesList(hid: household.id, cardId: cardId),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }
}
