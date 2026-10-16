import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../cards/cards_screen.dart' show cardsProvider;
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../members/member_chip.dart';
import 'expense.dart';
import 'expense_repository.dart';
import 'widgets/expense_detail_parts.dart';
import 'widgets/expense_review_section.dart';
import 'widgets/expense_social_section.dart';

/// Modal bottom sheet showing a single expense in full: amount, date,
/// category, source (account or card), member, note, recurring flag.
/// Provides a long-press-equivalent Delete CTA so the row tap-target
/// can be the natural detail action while keeping destruction guarded.
class ExpenseDetailSheet extends ConsumerWidget {
  const ExpenseDetailSheet({
    super.key,
    required this.expense,
  });

  final Expense expense;

  static Future<void> show({
    required BuildContext context,
    required Expense expense,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseDetailSheet(expense: expense),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const SizedBox(height: 200);
    }
    final category = household.categoryOf(expense.categoryId);
    final spender = household.memberOf(expense.spentBy);
    final source = household.accountOf(expense.sourceAccountId ?? '');
    final cards = ref.watch(cardsProvider(household.id)).value ?? const [];
    final card = expense.cardId == null
        ? null
        : cards.where((c) => c.id == expense.cardId).firstOrNull;
    final canDelete = ref.watch(canRecordTxnProvider);

    final categoryColor =
        category != null ? parseColor(category.color) : FtColors.ink3;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            // Keep the comment input reachable above the keyboard.
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            const ExpenseDetailGrabber(),
            const SizedBox(height: 14),
            ExpenseDetailHero(
              expense: expense,
              category: category,
              categoryColor: categoryColor,
            ),
            const SizedBox(height: 18),
            const Eyebrow('Detail'),
            const SizedBox(height: 8),
            FtCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  ExpenseDetailRow(
                    icon: Icons.event,
                    label: 'Tanggal',
                    value: Dates.short(expense.date),
                  ),
                  const ExpenseDetailDivider(),
                  ExpenseDetailRow(
                    icon: Icons.label_outline,
                    label: 'Kategori',
                    value: category?.label ?? expense.categoryId,
                    valueColor: categoryColor,
                  ),
                  const ExpenseDetailDivider(),
                  ExpenseDetailRow(
                    icon: card != null
                        ? Icons.credit_card
                        : Icons.account_balance_outlined,
                    label: card != null ? 'Kartu' : 'Sumber',
                    value: sourceLabel(expense, source, card),
                  ),
                  if (spender != null) ...[
                    const ExpenseDetailDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: FtColors.ink2),
                          const SizedBox(width: 12),
                          Text(
                            'Dicatat oleh',
                            style: TextStyle(
                              color: FtColors.ink3,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          MemberChip(member: spender),
                        ],
                      ),
                    ),
                  ],
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const ExpenseDetailDivider(),
                    ExpenseDetailRow(
                      icon: Icons.notes,
                      label: 'Catatan',
                      value: expense.note!,
                    ),
                  ],
                  if (expense.recurring) ...[
                    const ExpenseDetailDivider(),
                    ExpenseDetailRow(
                      icon: Icons.event_repeat,
                      label: 'Rutin',
                      value: 'Setiap bulan',
                      valueColor: FtColors.moss,
                    ),
                  ],
                  if (expense.installmentPlanId != null) ...[
                    const ExpenseDetailDivider(),
                    // The sheet only has the expense row, not the plan doc,
                    // so it can't tell active from settled — keep it neutral.
                    ExpenseDetailRow(
                      icon: Icons.timeline,
                      label: 'Cicilan',
                      value: 'Lewat tagihan kartu',
                      valueColor: FtColors.clay,
                    ),
                  ],
                ],
              ),
            ),
            ExpenseReviewSection(expense: expense, household: household),
            const SizedBox(height: 18),
            ExpenseSocialSection(expense: expense, household: household),
            const SizedBox(height: 18),
            if (canDelete) ...[
              ExpenseDetailEditButton(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/expenses/${expense.id}/edit');
                },
              ),
              const SizedBox(height: 10),
              ExpenseDetailDeleteButton(
                onTap: () => _confirmDelete(context, ref, household),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: Text(
          '${Money.format(expense.amount)} • ${Dates.short(expense.date)}\n'
          'Saldo rekening sumber akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(expenseRepositoryProvider)
          .delete(householdId: household.id, expenseId: expense.id);
      if (context.mounted) {
        FtHaptics.success();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus pengeluaran');
      }
    }
  }
}

