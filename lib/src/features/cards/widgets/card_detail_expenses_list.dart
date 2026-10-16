import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../expenses/expense_detail_sheet.dart';
import '../../household/household.dart';
import '../../household/household_providers.dart';
import '../card_detail_screen.dart';
import '../credit_card.dart';
import 'installment_list.dart';

class CardExpensesList extends ConsumerWidget {
  const CardExpensesList({super.key, required this.hid, required this.cardId});
  final String hid;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final async = ref.watch(cardExpensesProvider((hid: hid, cardId: cardId)));
    final plans = {
      for (final i in ref
              .watch(cardInstallmentsProvider((hid: hid, cardId: cardId)))
              .value ??
          const <Installment>[])
        i.id: i,
    };
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
        // Plain charges plus settled cicilan; unfinished plans stay in the
        // "Cicilan aktif" section above.
        final rows = [
          for (final e in items)
            if (e.installmentPlanId == null ||
                (plans[e.installmentPlanId]?.isComplete ?? false))
              e,
        ];
        if (rows.isEmpty) {
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
            for (final e in rows)
              _CardExpenseRow(
                expense: e,
                plan: plans[e.installmentPlanId],
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
    this.plan,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;

  /// Settled installment plan behind this row, when the expense was a
  /// cicilan. Drives the "lunas" hint in the subtitle.
  final Installment? plan;

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
                    if (plan != null)
                      plan!.monthsTotal > 1
                          ? 'Cicilan ${plan!.monthsTotal}× lunas'
                          : 'Lunas',
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
      'trending_up' => Icons.trending_up,
      _ => Icons.category,
    };

/// Maps a `StateError.message` code thrown by [CardRepository.deleteCard]
/// to a user-facing Indonesian message.
String cardDeleteErrorMessage(String? code) {
  switch (code) {
    case 'card_has_balance':
      return 'Tidak bisa hapus: kartu masih punya saldo terpakai. '
          'Bayar dulu lewat tombol "Bayar tagihan".';
    case 'card_has_active_installments':
      return 'Tidak bisa hapus: ada cicilan yang belum selesai.';
    case 'card_missing':
      return 'Kartu sudah tidak ada.';
    default:
      return 'Gagal menghapus kartu.';
  }
}
