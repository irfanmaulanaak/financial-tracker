import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_detail_sheet.dart';
import '../expenses/expense_repository.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import 'credit_card.dart';
import 'card_repository.dart';
import 'edit_card_sheet.dart';
import 'edit_cicilan_sheet.dart';
import 'widgets/card_detail_header.dart';
import 'widgets/installment_list.dart';

final _cardProvider =
    StreamProvider.family<CreditCard?, ({String hid, String cardId})>((ref, p) {
      return ref
          .watch(cardRepositoryProvider)
          .watchOne(hid: p.hid, cardId: p.cardId);
    });

/// Latest 20 non-cicilan expenses charged to a single card. Used by the
/// "Pengeluaran kartu" section on [CardDetailScreen]. Cicilan rows are
/// filtered out client-side and shown via the cicilan section instead.
final cardExpensesProvider =
    StreamProvider.family<List<Expense>, ({String hid, String cardId})>(
  (ref, p) => ref.watch(expenseRepositoryProvider).watchByCard(
        householdId: p.hid,
        cardId: p.cardId,
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
        showFtErrorSnack(context, _deleteErrorMessage(e.message));
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
                    data: (items) {
                      if (items.isEmpty) {
                        return [
                          FtCard(
                            child: Center(
                              child: Text(
                                'Belum ada cicilan.',
                                style: TextStyle(color: FtColors.ink3),
                              ),
                            ),
                          ),
                        ];
                      }
                      final canEdit = ref.watch(canRecordTxnProvider);
                      return items
                          .map(
                            (i) => CardInstallmentTile(
                              inst: i,
                              onPaidOne: () async {
                                try {
                                  await ref
                                      .read(cardRepositoryProvider)
                                      .incrementInstallment(
                                        hid: household.id,
                                        cardId: cardId,
                                        installmentId: i.id,
                                      );
                                } catch (e) {
                                  if (context.mounted) {
                                    showFtErrorSnack(
                                      context,
                                      e,
                                      prefix: 'Gagal mencatat cicilan',
                                    );
                                  }
                                }
                              },
                              onEdit: canEdit
                                  ? () => _editInstallment(
                                        context,
                                        ref,
                                        household.id,
                                        card,
                                        i,
                                      )
                                  : null,
                              onDelete: canEdit
                                  ? () => _deleteInstallment(
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
                  _CardExpensesList(hid: household.id, cardId: cardId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editInstallment(
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
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal memperbarui cicilan');
      }
    }
  }

  Future<void> _deleteInstallment(
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
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          showFtErrorSnack(context, e, prefix: 'Gagal membayar kartu');
        }
      }
    }
  }
}

class _CardExpensesList extends ConsumerWidget {
  const _CardExpensesList({required this.hid, required this.cardId});
  final String hid;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final async = ref.watch(cardExpensesProvider((hid: hid, cardId: cardId)));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => FtCard(
        child: Text(
          'Gagal memuat pengeluaran: $e',
          style: TextStyle(color: FtColors.danger),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return FtCard(
            child: Center(
              child: Text(
                'Belum ada pengeluaran kartu.',
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final e in items)
              _CardExpenseRow(
                expense: e,
                category: household?.categoryOf(e.categoryId),
                onTap: () => ExpenseDetailSheet.show(
                  context: context,
                  expense: e,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CardExpenseRow extends StatelessWidget {
  const _CardExpenseRow({
    required this.expense,
    required this.category,
    required this.onTap,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = category;
    final color =
        cat != null ? _parseColor(cat.color) : FtColors.ink3;
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(
              _iconFor(cat?.icon ?? 'category'),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat?.label ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    Dates.short(expense.date),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      expense.note!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Money.format(expense.amount),
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData _iconFor(String name) => switch (name) {
      'restaurant' => Icons.restaurant,
      'receipt_long' => Icons.receipt_long,
      'shopping_bag' => Icons.shopping_bag,
      'directions_car' => Icons.directions_car,
      'movie' => Icons.movie,
      'favorite' => Icons.favorite,
      'school' => Icons.school,
      'pets' => Icons.pets,
      'sports_esports' => Icons.sports_esports,
      _ => Icons.category,
    };

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
