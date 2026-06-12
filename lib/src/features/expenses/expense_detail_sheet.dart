import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../accounts/account.dart';
import '../cards/cards_screen.dart' show cardsProvider;
import '../cards/credit_card.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../members/member_chip.dart';
import 'expense.dart';
import 'expense_repository.dart';
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
            const _Grabber(),
            const SizedBox(height: 14),
            _Hero(
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
                  _DetailRow(
                    icon: Icons.event,
                    label: 'Tanggal',
                    value: Dates.short(expense.date),
                  ),
                  const _Divider(),
                  _DetailRow(
                    icon: Icons.label_outline,
                    label: 'Kategori',
                    value: category?.label ?? expense.categoryId,
                    valueColor: categoryColor,
                  ),
                  const _Divider(),
                  _DetailRow(
                    icon: card != null
                        ? Icons.credit_card
                        : Icons.account_balance_outlined,
                    label: card != null ? 'Kartu' : 'Sumber',
                    value: _sourceLabel(expense, source, card),
                  ),
                  if (spender != null) ...[
                    const _Divider(),
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
                    const _Divider(),
                    _DetailRow(
                      icon: Icons.notes,
                      label: 'Catatan',
                      value: expense.note!,
                    ),
                  ],
                  if (expense.recurring) ...[
                    const _Divider(),
                    _DetailRow(
                      icon: Icons.event_repeat,
                      label: 'Rutin',
                      value: 'Setiap bulan',
                      valueColor: FtColors.moss,
                    ),
                  ],
                  if (expense.installmentPlanId != null) ...[
                    const _Divider(),
                    _DetailRow(
                      icon: Icons.timeline,
                      label: 'Cicilan',
                      value: 'Aktif',
                      valueColor: FtColors.plum,
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
              _EditButton(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/expenses/${expense.id}/edit');
                },
              ),
              const SizedBox(height: 10),
              _DeleteButton(
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

String _sourceLabel(Expense e, Account? source, CreditCard? card) {
  if (source != null) return source.label;
  if (card != null) return card.label;
  if (e.sourceAccountId != null) return e.sourceAccountId!;
  if (e.cardId != null) return e.cardId!;
  return '—';
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.expense,
    required this.category,
    required this.categoryColor,
  });
  final Expense expense;
  final Category? category;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.24),
              width: 0.5,
            ),
          ),
          child: Icon(
            iconFor(category?.icon ?? 'category'),
            size: 26,
            color: categoryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          Money.format(expense.amount),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 32,
                letterSpacing: -0.5,
              ),
        ),
        if (expense.note != null && expense.note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            expense.note!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FtColors.ink3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: FtColors.ink2),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: FtColors.ink3, fontSize: 12),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: FtColors.line);
}

class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: FtColors.lineStrong,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FtColors.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 18, color: FtColors.ink),
            const SizedBox(width: 8),
            Text(
              'Edit pengeluaran',
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FtColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FtColors.danger.withValues(alpha: 0.24),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                size: 18, color: FtColors.danger),
            const SizedBox(width: 8),
            Text(
              'Hapus pengeluaran',
              style: TextStyle(
                color: FtColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
